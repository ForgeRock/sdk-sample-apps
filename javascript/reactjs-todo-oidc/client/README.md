# React JS Todo OIDC Client

This folder contains the React client for `reactjs-todo-oidc`, which demonstrates centralized OIDC login with `@forgerock/oidc-client`. Unlike journey-based samples, this client does not render embedded login callbacks and does not expose a `/register` route.

## Authentication flow

1. User clicks **Sign In** on `/`.
2. `client/views/login.js` redirects to the configured authorization endpoint.
3. OIDC callback returns to `/callback.html`, which forwards query params to `/login`.
4. `/login` exchanges the authorization code for tokens and loads user profile info.
5. Authenticated users can access `/todos`; unauthenticated users are redirected to `/login`.

## Runtime configuration

### SDK credentials

Copy `config.example.json` to `config.json` at `javascript/reactjs-todo-oidc/config.json` and fill in your values:

```sh
cp config.example.json config.json
```

```json
{
  "oidc": {
    "clientId": "<your-oauth-client-id>",
    "discoveryEndpoint": "https://<your-domain>/.well-known/openid-configuration",
    "scopes": ["openid", "profile", "email"],
    "redirectUri": "https://localhost:8443/callback.html"
  }
}
```

`config.json` is gitignored.

### Runtime env vars

Copy `.env.example` to `.env` at `javascript/reactjs-todo-oidc/.env`:

```text
API_URL=http://localhost:9443
DEBUGGER_OFF=true
DEVELOPMENT=true
PORT=8443
#SERVER - 'PINGAM' or 'PINGONE'
SERVER=PINGAM
```

Notes:

- `SERVER` is used to derive the display name from either PingAM or PingOne token claims.

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
