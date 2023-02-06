import hmac
from functools import wraps
from hashlib import sha256

from flask import abort, request

from .commands import secret
from .config import WEBHOOK_SECRET_SDB_BACKEND, WEBHOOK_SECRET_SDB_KEY


def webhook(f):
    """
    Decorator to validate webhook requests.
    """

    @wraps(f)
    def wrapper(*args, **kwargs):
        signature = request.headers.get("X-Hub-Signature-256", "").removeprefix(
            "sha256="
        )
        if not _validate(request.data, signature):
            abort(401)

        return f(*args, **kwargs)

    return wrapper


def _validate(body, signature):
    key = secret(WEBHOOK_SECRET_SDB_KEY, WEBHOOK_SECRET_SDB_BACKEND).encode()
    computed = hmac.new(key, body, sha256).hexdigest()
    return hmac.compare_digest(signature, computed)
