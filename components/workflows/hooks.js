const { readFileSync } = require("fs");
const { dirname, resolve } = require("path");

const relativeRequire = (pkg) => (path) => require(resolve(pkg, path));

const n8n = relativeRequire("N8N_LIB_PATH");
const { AuthService } = n8n("auth/auth.service");
const { OIDC_NONCE_COOKIE_NAME, OIDC_STATE_COOKIE_NAME } = n8n("constants");
const { OidcService } = n8n("sso.ee/oidc/oidc.service.ee");
const { UrlService } = n8n("services/url.service");

const { LicenseState } = require("@n8n/backend-common");
const { GlobalConfig } = require("@n8n/config");
const { Time } = require("@n8n/constants");
const { Container } = require("@n8n/di");

function nonWritableProperty(obj, key, value) {
  Object.defineProperty(obj, key, {
    get: () => value,
    set: () => {},
  });
}

function readEnv(name) {
  if (name in process.env) return process.env[name];

  const filePath = process.env[`${name}_FILE`];
  if (filePath) return readFileSync(filePath, "utf8");

  return undefined;
}

function readEnvBool(name) {
  const value = readEnv(name);
  if (value === undefined) return false;

  const normalized = value.toLowerCase();

  if (normalized === "1" || normalized === "true") return true;
  else if (normalized === "0" || normalized === "false") return false;
  else {
    console.warn(`Invalid boolean value for ${name}: ${value}`);
    return false;
  }
}

const badRequest = (res, message) => res.status(400).send(message).end();

const loginPath = "/rest/custom/oidc/login";
const callbackPath = "/rest/custom/oidc/callback";

const customEnabled = readEnvBool("SSO_OIDC_ENABLED");
const discoveryEndpoint = readEnv("SSO_OIDC_DISCOVERY_ENDPOINT");
const clientId = readEnv("SSO_OIDC_CLIENT_ID");
const clientSecret = readEnv("SSO_OIDC_CLIENT_SECRET");

if (customEnabled && !(discoveryEndpoint && clientId && clientSecret)) {
  console.warn(
    "must provide a discovery endpoint, client id, and client secret when OIDC is enabled",
  );
}

module.exports = {
  n8n: {
    ready: [
      async function ({ app }) {
        const enterprise = Container.get(LicenseState).isOidcLicensed();
        if (enterprise) {
          console.warn(
            "official OIDC implementation is available, disabling custom",
          );
          return;
        }

        if (!customEnabled) return;

        const auth = Container.get(AuthService);
        const config = Container.get(GlobalConfig);
        const oidc = Container.get(OidcService);
        const urls = Container.get(UrlService);

        await oidc.updateConfig({
          discoveryEndpoint,
          clientId,
          clientSecret,
          loginEnabled: true,
          prompt: "login",
          authenticationContextClassReference: [],
        });

        app.router.get(loginPath, async (_req, res) => {
          try {
            const { url, state, nonce } = await oidc.generateLoginUrl();
            const { samesite: sameSite, secure } = config.auth.cookie;

            const baseUrl = urls.getInstanceBaseUrl();
            url.searchParams.set("redirect_uri", `${baseUrl}${callbackPath}`);

            res.cookie(OIDC_STATE_COOKIE_NAME, state, {
              maxAge: 15 * Time.minutes.toMilliseconds,
              httpOnly: true,
              sameSite,
              secure,
            });
            res.cookie(OIDC_NONCE_COOKIE_NAME, nonce, {
              maxAge: 15 * Time.minutes.toMilliseconds,
              httpOnly: true,
              sameSite,
              secure,
            });

            res.redirect(url.toString());
          } catch (e) {
            console.error("OIDC login error:");
            console.error(e);
            return badRequest(res, "failed to initiate oidc login");
          }
        });
        app.router.get(callbackPath, async (req, res) => {
          try {
            const callbackUrl = new URL(
              `${urls.getInstanceBaseUrl()}${req.originalUrl}`,
            );

            const state = req.cookies[OIDC_STATE_COOKIE_NAME];
            if (typeof state !== "string")
              return badRequest(res, "Invalid state");

            const nonce = req.cookies[OIDC_NONCE_COOKIE_NAME];
            if (typeof nonce !== "string")
              return badRequest(res, "Invalid nonce");

            const user = await oidc.loginUser(callbackUrl, state, nonce);

            res.clearCookie(OIDC_STATE_COOKIE_NAME);
            res.clearCookie(OIDC_NONCE_COOKIE_NAME);

            auth.issueCookie(res, user, true, req.browserId);

            res.redirect("/");
          } catch (e) {
            console.error("OIDC callback error:");
            console.error(e);
            res.clearCookie(OIDC_STATE_COOKIE_NAME);
            res.clearCookie(OIDC_NONCE_COOKIE_NAME);
            return badRequest(res, "oidc authentication failure");
          }
        });
      },
    ],
  },
  frontend: {
    settings: [
      async function (settings) {
        const enterprise = Container.get(LicenseState).isOidcLicensed();
        if (enterprise) return;

        if (!customEnabled) return;

        const baseUrl = Container.get(UrlService).getInstanceBaseUrl();

        settings.sso.oidc = {
          loginEnabled: true,
          loginUrl: `${baseUrl}${loginPath}`,
          callbackUrl: `${baseUrl}${callbackPath}`,
        };

        nonWritableProperty(settings.enterprise, "oidc", true);
        nonWritableProperty(
          settings.userManagement,
          "authenticationMethod",
          "oidc",
        );
      },
    ],
  },
};
