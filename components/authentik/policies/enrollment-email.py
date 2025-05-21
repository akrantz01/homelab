from authentik.brands.models import Brand
from authentik.events.models import EventAction
from authentik.stages.email.models import EmailStage
from authentik.stages.email.tasks import send_mails
from authentik.stages.email.utils import TemplateEmailMessage
from authentik.stages.invitation.models import Invitation
from django.template.exceptions import TemplateSyntaxError

event = request.context.get("event")
if event is None or event.action != EventAction.MODEL_CREATED:
    return False

model = event.context.get("model")
if (
    model is None
    or model["app"] != "authentik_stages_invitation"
    or model["model_name"] != "invitation"
):
    return False

try:
    invitation = Invitation.objects.get(pk=model["pk"])
except Invitation.DoesNotExist as exc:
    raise ValueError(f"invitation {model['pk']} does not exist") from exc

name = invitation.fixed_data.get("name")
if name is None:
    raise ValueError(f"invitation {model['pk']} is missing a name")

email = invitation.fixed_data.get("email")
if email is None:
    raise ValueError(f"invitation {model['pk']} is missing an email")

email_stage_name = f"{invitation.flow.slug}-email"
try:
    email_stage = EmailStage.objects.get(name=email_stage_name)
except EmailStage.DoesNotExist as exc:
    raise ValueError(f"email stage {email_stage_name} does not exist") from exc

brand = Brand.objects.filter(default=True).first()
assert brand is not None, "no default brand found"

message = TemplateEmailMessage(
    subject=email_stage.subject,
    to=[(name, email)],
    template_name=email_stage.template,
    template_context={
        "expires": invitation.expires,
        "name": name,
        "url": f"https://{brand.domain}/if/flow/default-invitation-enrollment/?itoken={invitation.invite_uuid}",
    },
)

send_mails(email_stage, message)

return True
