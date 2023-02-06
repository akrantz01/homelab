from os import environ

DEFAULT_BRANCH = environ.get("DEFAULT_BRANCH", "main")

SECRET_TTL = int(environ.get("SECRET_TTL", 900))

WEBHOOK_SECRET_SDB_KEY = environ.get("WEBHOOK_SECRET_SDB_KEY", "github-webhook")
WEBHOOK_SECRET_SDB_BACKEND = environ.get("WEBHOOK_SECRET_SDB_BACKEND", "secrets")
