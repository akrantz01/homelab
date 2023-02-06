from flask import Flask, request, jsonify
from werkzeug.middleware.proxy_fix import ProxyFix

from .security import webhook

app = Flask(__name__)
app.wsgi_app = ProxyFix(app.wsgi_app)


@app.post("/webhook/apply")
@webhook
def apply():
    if request.json.get("ref") != "refs/heads/main":
        return jsonify(message="not main branch, skipping")

    return jsonify(message="ok")
