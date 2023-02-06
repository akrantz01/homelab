import hmac
from functools import wraps
from hashlib import sha256

from flask import abort, request

# TODO: load secret from SaltStack
SECRET = ""


def webhook(f):
    """
    Decorator to validate webhook requests.
    """

    @wraps(f)
    def wrapper(*args, **kwargs):
        signature = request.headers.get("X-Hub-Signature-256", "").removeprefix("sha256=")
        if not _validate(request.data, signature):
            abort(401)
        
        return f(*args, **kwargs)

    return wrapper


def _validate(body, signature):
    computed = hmac.new(SECRET.encode(), body, sha256).hexdigest()
    return hmac.compare_digest(signature, computed)
