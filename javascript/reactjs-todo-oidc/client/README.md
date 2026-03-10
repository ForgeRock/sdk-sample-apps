# React JS Todo OIDC Client

This folder contains the React client for `reactjs-todo-oidc`, which demonstrates centralized OIDC login with `@forgerock/oidc-client`.
Unlike journey-based samples, this client does not render embedded login callbacks and does not expose a `/register` route.

## Authentication flow

1. User clicks **Sign In** on `/`.
2. `client/views/login.js` redirects to the configured authorization endpoint.
3. OIDC callback returns to `/callback.html`, which forwards query params to `/login`.
4. `/login` exchanges the authorization code for tokens and loads user profile info.
5. Authenticated users can access `/todos`; unauthenticated users are redirected to `/login`.

## Runtime configuration

Copy `.env.example` to `.env` at `javascript/reactjs-todo-oidc/.env`, then set values for your environment:

```text
SERVER_URL=<<<URL to your AM instance, for example https://example.com/am>>>
WELLKNOWN_URL=<<<Realm well-known URL, for example https://example.com/am/oauth2/alpha/.well-known/openid-configuration>>>
REALM_PATH=<<<Realm path, for example alpha>>>
WEB_OAUTH_CLIENT=<<<Your Web OAuth client name/ID>>>
SCOPE="openid profile email"
API_URL=http://localhost:9443
REST_OAUTH_CLIENT=<<<Your API OAuth client name/ID>>>
REST_OAUTH_SECRET=<<<Your API OAuth client secret>>>
DEBUGGER_OFF=true
INIT_PROTECT=bootstrap
PINGONE_ENV_ID=<<<Optional: required only when using PingOne Protect callback collection>>>
```

Notes:

- `WELLKNOWN_URL` is the source of truth for OIDC discovery in this sample.
- `SCOPE` should include `openid` so logout and userinfo flows have the expected token set.
- `SERVER_URL` is kept in `.env` for parity with sample conventions, though OIDC discovery uses `WELLKNOWN_URL`.

## Running locally

Run from the JavaScript workspace root:

```sh
cd javascript
npm install
npm run start:reactjs-todo-oidc
```

Then visit:

- App: `https://localhost:8443`
- API healthcheck: `http://localhost:9443/healthcheck`

## Build, lint, and E2E

From `javascript/`:

```sh
npm run build --workspace reactjs-todo-oidc
npm run lint --workspace reactjs-todo-oidc
npm run e2e --workspace reactjs-todo-oidc -- e2e/oidc-login.spec.js --project=chromium
```

## Key client files

- `client/constants.js`: OIDC config construction (`CONFIG`) and env-backed constants
- `client/context/oidc.context.js`: OIDC client init, token-based auth state, logout handling
- `client/views/login.js`: centralized-login redirect, token exchange, and auth state hydration
- `client/utilities/route.js`: protected-route auth validation
- `public/callback.html`: callback forwarder to `/login`
