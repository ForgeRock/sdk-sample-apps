![Ping Identity](https://www.pingidentity.com/content/dam/picr/nav/Ping-Logo-2.svg)

# Remote Consent Service (RCS) Demo

A small Node.js server that acts as a **Remote Consent Service** so you can test **Rich Authorization Requests** ([RFC 9396](https://www.rfc-editor.org/rfc/rfc9396)) end to end with PingAM and PingOne Advanced Identity Cloud (AIC). It is the companion server for the Rich Authorization Requests (RAR) screens in the [iOS OIDC module sample](../../iOS/swiftui-oidc-module/README.md#rich-authorization-requests-rfc-9396), and a reference for any other client that sends `authorization_details`.

## Disclaimers

This sample code is provided "as is" and is not a supported product of Ping. It is a **testing and demonstration tool only**:

- It listens on all network interfaces, and over plain HTTP until you configure HTTPS (see [HTTPS](#https)).
- It does **not** verify the signature, issuer or audience of the consent requests it receives, and it has no CSRF protection.
- It approves whatever authorization details of a supported type it is asked to approve, without any business rules.

Do not deploy it in production or expose it on an untrusted network. See [Security Considerations](#security-considerations).

## Overview

### What is a Remote Consent Service?

When a client asks for fine-grained permissions with `authorization_details` (for example, "initiate a payment of EUR 123.50 to this account"), the user has to approve those exact details. PingAM and AIC delegate that approval screen to a **Remote Consent Service**, a web application you host:

1. The authorization server redirects the user's browser to the service with the consent request, a signed JWT.
2. The service shows the user what is being requested and records Approve or Deny.
3. The service returns a signed JWT with the decision and the details it granted, and the authorization server issues tokens that carry those granted details.

### Why this demo exists

The example consent service built into AIC approves the request but never echoes `authorization_details` back. The token then carries an empty `authorization_details` array, so a client app has nothing to show. This demo is a working consent service that echoes the granted details, so you can:

- Run a complete RAR login from a sample app and see the **Granted Authorization Details** on the token screen.
- Exercise the **deny** path and the **unsupported type** path (granted as an empty array).
- Use it as a small reference for the signed-JWT contract between the authorization server and a consent service, if you are building your own.

Supported authorization detail types: `account_information` and `payment_initiation`, the same types as the presets in the iOS sample.

## How It Works

1. The sample app starts an authorization request that includes `authorization_details`.
2. The authorization server redirects the user's browser to `GET /consent?consent_request=<signed JWT>`.
3. The demo decodes the request and renders each requested detail of a supported type, with **Approve** and **Deny** buttons.
4. On submit, the demo signs a `consent_response` JWT (RS256) and returns a self-submitting form that POSTs it to the `consentApprovalRedirectUri` from the request.
5. The authorization server validates the response, continues the authorization code flow, and the token response carries the granted `authorization_details`.

### Endpoints

| Endpoint | Purpose |
|---|---|
| `GET /consent` | Consent page the authorization server redirects the browser to |
| `POST /consent` | Receives the Approve or Deny decision and posts the signed response to the authorization server |
| `GET /keys` | JWK set with the public signing key; the agent's Json Web Key URI |
| `GET /metadata` | Lists the supported authorization detail types |

### The consent response

The `consent_response` JWT is signed with `alg: RS256` and `kid: rcs-demo-signing-key`, and expires after 5 minutes. Its claims follow what PingAM expects:

| Claim | Value |
|---|---|
| `iss` | The RCS agent ID, which is the request's `aud` claim |
| `aud` | The authorization server issuer, which is the request's `iss` claim, unchanged |
| `decision` | A JSON boolean: `true` for Approve, `false` for Deny |
| `scopes` | The scope names from the request on Approve, empty on Deny |
| `authorization_details` | The requested details of a supported type on Approve, empty on Deny |
| `clientId`, `client_id` | The client identifier from the request, sent under both names |
| `csrf` | Echoed from the request |
| `save_consent` | `false` |

Requested details of a type that is not supported are left out of the response, so the authorization server grants an empty `authorization_details` array for them.

## Requirements

1. Node >= 18 (recommended: install via the [official package installer](https://nodejs.org/en/))
2. PingOne Advanced Identity Cloud release 23604.0 or later. For self-managed PingAM, use a release that supports Rich Authorization Requests with a Remote Consent Service
3. A client app that sends `authorization_details`, such as the [iOS OIDC module sample](../../iOS/swiftui-oidc-module/README.md)
4. A browser or device that can reach this app over the network (see [Configure the Authorization Server](#configure-the-authorization-server))

## Setup

### Run the demo

```sh
cd rcs/rcs-demo
npm install
npm start
```

The app listens on port `8081` on all interfaces unless you pass another port. On startup it prints the public JWK set, which you can paste into the agent configuration:

```text
--- Paste into the RCS agent's Json Web Key field: ---
{"keys":[{"kty":"RSA","n":"...","e":"AQAB","kid":"rcs-demo-signing-key","alg":"RS256","use":"sig"}]}
-----------------------------------------------------
RCS demo listening on http://0.0.0.0:8081
```

| Setting | Description |
|---|---|
| `--port <n>` (or `-p`) | Port to listen on: `npm start -- --port 8082`. A bare number is also accepted (`npm start -- 8082`), so the flag still works if npm drops it (see the note below). Without any, the `PORT` environment variable, then `8081` |
| `npm run debug` (or `RCS_DEBUG=1`) | Logs every request, the decision, the granted details, and the signed response JWT. Combine with a port: `npm run debug -- --port 8082` |
| `npm run ssl` (or `--ssl`) | Serve HTTPS instead of HTTP. See [HTTPS](#https) |
| `--cert <file> --key <file>` | Use these certificate files with `--ssl` (they also enable HTTPS on their own) |

> **The `--` separator matters**: `npm run debug --port 8082` (without `--`) makes npm try to parse `--port` itself. It warns, drops the flag, and passes only `8082` to the app — the app recognizes a bare port number, so the port still applies. Keep the `--` in scripts and docs to avoid the npm warnings.

### HTTPS

HTTPS matters here: ASWebAuthenticationSession, which the iOS sample uses for the login browser, and many browsers reject or warn on plain-HTTP pages embedded in an OAuth flow, and a hosted authorization server can only fetch JWK or metadata URLs it can reach over HTTPS.

The app serves HTTPS when either:

1. It is started with `npm run ssl` (or `--ssl`) and certificate files exist, or
2. `.certs/cert.pem` and `.certs/key.pem` exist next to `server.js` — HTTPS is then automatic, no flag needed.

For a **valid, trusted** certificate, create the `.certs/` files with [mkcert](https://github.com/FiloSottile/mkcert), which installs a local CA that your Mac and iOS Simulator already trust. Generate it for every name and address you will use in the agent configuration — typically your Mac's local IP, so the endpoints work from a physical device as well:

```sh
brew install mkcert
mkcert -install
mkcert -cert-file .certs/cert.pem -key-file .certs/key.pem localhost 127.0.0.1 <your-local-ip>
npm start
```

`<your-local-ip>` is the address other devices use to reach your Mac; find it with `ipconfig getifaddr en0` (or `en1`). **Every address or hostname in the agent URLs must be in this list** — a URL whose host is not covered by the certificate fails TLS validation in the browser and in the iOS sample, even though the server is up. `localhost` is already covered above.

With the certificate in place, the endpoints all use the same host. For example, with a Mac at `192.168.2.104`:

| Endpoint | URL |
|---|---|
| Consent page (Redirect URL) | `https://192.168.2.104:8081/consent` |
| JWK set (Json Web Key URI) | `https://192.168.2.104:8081/keys` |
| Metadata | `https://192.168.2.104:8081/metadata` |

Use the IP form everywhere — the agent's Redirect URL and, when your tenant can route to your network, the Json Web Key and Metadata URLs. The server already listens on all interfaces, so no host flag is needed; the URLs decide the reachability.

**Verify before configuring anything else**: open `https://<your-local-ip>:8081/metadata` in your Mac's browser. If it loads with no certificate warning, devices and the sample app will accept it too; a warning means the certificate does not cover that address — regenerate with it included.

Two caveats:

- **Changing addresses**: the certificate is bound to the names and addresses it was generated for. If your Mac's IP changes (DHCP), regenerate the certificate with the new address and update the agent URLs. A DHCP reservation for your Mac keeps the setup stable. The `.certs/` directory is git-ignored.
- **Hosted tenant**: a hosted AIC tenant cannot reach a private network address, so the Json Web Key and Metadata URLs need a tunnel (see the reachability note under [Configure the Authorization Server](#configure-the-authorization-server)) or a pasted JWK set, regardless of the certificate.

To use an existing certificate instead of mkcert, pass it explicitly: `npm run ssl -- --cert server.pem --key server.key`. With a self-signed certificate that the machine does not trust (for example a quick `openssl req` one), the server still runs, but browsers and the iOS sample show certificate warnings and may refuse the flow — the trusted-mkcert route above avoids that. `npm run ssl` without any certificate available prints an error and exits instead of silently serving HTTP.

> **Tunnels**: exposing the app through an HTTPS tunnel makes this unauthenticated app reachable from the internet — anyone who can reach it can request a signed consent response. Keep it up only for the length of your test session.

### Signing keys

The first run generates an RSA-2048 key pair and saves the private key to `.keys/signing-key.pem` in this directory (ignored by git, readable only by your user). Later runs reuse it and derive the public JWK from it, so the JWK URI stays stable across restarts. If you delete `.keys/`, a new key pair is generated and the agent configuration must be updated with the new JWK set.

### Configure the Authorization Server

Rich Authorization Requests with a Remote Consent Service need three pieces of configuration on PingAM or AIC. The iOS sample's [Rich Authorization Requests Prerequisites](../../iOS/swiftui-oidc-module/README.md#rich-authorization-requests-prerequisites) lists the provider and client settings in full. In summary:

1. **OAuth 2.0 provider**: enable **Remote Consent** and **Enable Rich Authorization Requests with Remote Consent Service**.
2. **OAuth 2.0 client**: list `payment_initiation` and `account_information` under **Authorization Detail Type(s)**, enable remote consent with the agent below, and turn **Implied Consent** off.
3. **Remote Consent Service agent**: point it at this app:

| Property | Value |
|---|---|
| Redirect URL | `https://<your-host>:8081/consent` (or `http://` when serving plain HTTP) |
| Json Web Key URI | `https://<your-host>:8081/keys` (or paste the JWK set printed at startup into **Json Web Key**, with the public key selector set to JWKs) |
| Metadata URL | `https://<your-host>:8081/metadata` |
| Enable Consent Request Encryption | Off |
| Consent Response Signing Algorithm | RS256 (the default) |

The agent ID you choose does not need to be configured here: the app reads it from the consent request and uses it as the issuer of the response.

> **Reachability and trust:** The **Redirect URL** is followed by the user's *browser*, so it only has to be reachable from the device running the sample app — use `https://localhost:8081/consent` for the iOS Simulator, which shares the Mac's network and its trust store, or `https://<your-local-ip>:8081/consent` for a physical device (generate the certificate for that address too). The **Json Web Key URI** and **Metadata URL** are fetched by the *authorization server*, and a hosted AIC tenant cannot reach a private network address. For a hosted tenant, publish this app through an HTTPS tunnel and use the tunnel's address for those URLs — a tunnel makes this unauthenticated app reachable from the internet, so keep it up only for the length of your test session. If your agent configuration allows it, you can instead paste the JWK set into the agent's **Json Web Key** field, so the tenant does not need to fetch `/keys`.

## Try It With the iOS Sample

1. Start the demo and complete the configuration above.
2. Configure and run the [iOS OIDC module sample](../../iOS/swiftui-oidc-module/README.md) against the same tenant.
3. Open **Launch RAR Login**, choose the `payment_initiation` preset, and tap **Login with authorization_details**.
4. The browser opens this app's **Consent request** page and lists the requested details. Tap **Approve**.
5. Back in the sample app, open **RAR Access Token**. The **Granted Authorization Details** card shows the details the demo echoed back.

To see the other outcomes:

| Action | Result in the sample app |
|---|---|
| Tap **Deny** | "Consent was denied. The user declined the authorization request." |
| Request a type this demo does not support | The consent page says the type will not be granted, and the token carries an empty `authorization_details` array |
| Request a type that is not listed on the OAuth client | The server rejects the request with `invalid_authorization_details` |

## Customizing

- **Supported types**: edit `SUPPORTED_TYPES` in `server.js`. `/metadata` and the consent filtering both follow it. Add the new types to the OAuth client's **Authorization Detail Type(s)** as well.
- **Grant rules**: the demo grants every requested detail of a supported type exactly as requested. A real consent service would apply its own rules here, for example capping an amount or removing a location, and return the reduced details in the response.

## Troubleshooting

**Issue**: The browser cannot open the consent page.  
**Solution**: The device must be able to reach the **Redirect URL**. Check that the app is running, that the device is on the same network as your machine, and that a firewall is not blocking the port. Use the machine's IP address, not `localhost`, for a physical device.

**Issue**: The "Consent recorded" page stays open and the login does not continue.  
**Solution**: The submission to the authorization server failed. Run `npm run debug` and check the console for the target URL and the signed response JWT.

**Issue**: The authorization server rejects the consent response signature.  
**Solution**: The agent's public key must match the key in `.keys/`. AIC caches an agent's JWK set for about an hour, so after the key changes (for example because `.keys/` was deleted) update the agent configuration and allow time for the cache to refresh. `npm run debug` logs when the server fetches `/keys`.

**Issue**: The token carries an empty `authorization_details` array.  
**Solution**: The user tapped **Deny**, or none of the requested types is supported by this demo. The consent page lists which requested details will be granted.

**Issue**: The token carries no `authorization_details` at all.  
**Solution**: The authorization server did not treat the request as a Rich Authorization Request. Check the OAuth 2.0 provider and client settings in [Configure the Authorization Server](#configure-the-authorization-server).

**Issue**: Port `8081` is already in use.  
**Solution**: Start the app on another port with `npm start -- --port 8082` and update the agent URLs to match.

## Project Structure

```text
rcs-demo/
├── server.js      # Express app: consent page, decision handling, JWKS and metadata
├── keys.js        # Generates and loads the RSA signing key pair
├── package.json   # Dependencies (express, jose) and npm scripts
└── .keys/         # Generated signing key (git-ignored)
```

## Security Considerations

This app trades safety for simplicity so that it is easy to read and run locally. A production Remote Consent Service must do the following, none of which this demo does:

- Verify the signature of the consent request against the authorization server's keys, and check its issuer and audience
- Serve over HTTPS with a certificate from a CA the client devices and the authorization server trust, and enable consent request encryption
- Protect the consent form against CSRF
- Authenticate the user and apply real grant rules to the requested details
- Bind to specific interfaces instead of all of them

Run the demo on a trusted network, stop it (and any tunnel) when you are finished, and never reuse its signing key elsewhere. Debug mode (`npm run debug`) prints signed response JWTs to the console.

## Additional Resources

- [Remote Consent Service](https://docs.pingidentity.com/pingoneaic/authorization/remote-consent-service.html) in the Ping Identity documentation
- [Ping Identity documentation](https://docs.pingidentity.com/)
- [RFC 9396: OAuth 2.0 Rich Authorization Requests](https://www.rfc-editor.org/rfc/rfc9396)

## License

This software may be modified and distributed under the terms of the MIT license. See the [LICENSE](../../LICENSE) file for details.

© Copyright 2026 Ping Identity Corporation. All rights reserved.
