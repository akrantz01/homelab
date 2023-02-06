from os import environ

from flask import Flask, jsonify, request
from werkzeug.middleware.proxy_fix import ProxyFix

from .commands import apply, sync
from .config import DEFAULT_BRANCH
from .security import webhook

app = Flask(__name__)
app.wsgi_app = ProxyFix(app.wsgi_app)


@app.post("/webhook/apply")
@webhook
def apply():
    if request.json.get("ref") != "refs/heads/{DEFAULT_BRANCH}":
        return jsonify(message="not main branch, skipping")

    sync()
    apply()

    return jsonify(message="ok")
