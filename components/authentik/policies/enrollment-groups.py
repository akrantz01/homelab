from authentik.core.models import Group, User
from authentik.stages.invitation.models import Invitation

# TODO: get user from request context
user = context.get("pending_user")
assert user is not None, "no user found in context"

try:
    invitation = Invitation.objects.get(pk=...)
except Invitation.DoesNotExist as exc:
    raise ValueError(f"invitation {...} does not exist") from exc

groups = invitation.fixed_data.get("groups")
if groups is None:
    raise ValueError(f"invitation {...} is missing groups")
elif not isinstance(groups, list):
    raise ValueError(f"invitation {...} groups is not a list")

for group_name in groups:
    try:
        group = Group.objects.get(name=group_name)
    except Group.DoesNotExist as exc:
        raise ValueError(f"group {group_name} does not exist") from exc

    user.ak_groups.add(group)

return True
