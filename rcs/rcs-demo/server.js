/*
 *
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 *
 */

// Demonstration Remote Consent Service (RCS) for Rich Authorization Requests
// (RFC 9396) with PingAM and PingOne Advanced Identity Cloud.
//
// FOR TESTING AND DEMONSTRATION ONLY. Do not use in production: the app runs
// over plain HTTP, serves no CSRF protection, and accepts any consent request
// it is given without verifying its signature.
//
// Flow:
// 1. The authorization server redirects the user's browser to
//    GET /consent?consent_request=<signed JWT>.
// 2. The app decodes the JWT, renders the requested authorization_details,
//    and lets the user approve or deny.
// 3. On approval the app signs a consent_response JWT with RS256, echoing the
//    granted authorization_details, and returns a self-submitting form that
//    POSTs it back to the authorization server.

import express from "express";
import { SignJWT } from "jose";
import { loadSigningKeys, getJwkSet, toJoseKey } from "./keys.js";

// The port comes from --port (or -p) on the command line, then the PORT
// environment variable, then 8081. The flag form works in every shell:
// npm start -- --port 8082
function portFromArgs(args) {
  const index = args.indexOf("--port") >= 0 ? args.indexOf("--port") : args.indexOf("-p");
  if (index >= 0) {
    const value = Number.parseInt(args[index + 1], 10);
    if (Number.isInteger(value) && value > 0 && value < 65536) {
      return value;
    }
    console.error(`Invalid port "${args[index + 1]}". Using the default instead.`);
  }
  return undefined;
}

const PORT = portFromArgs(process.argv) ?? Number.parseInt(process.env.PORT, 10) ?? 8081;
const HOST = "0.0.0.0";

// The authorization detail types this RCS supports. Requests for other types
// are filtered out of the consent response, and the authorization server
// grants an empty authorization_details array for them.
const SUPPORTED_TYPES = ["account_information", "payment_initiation"];

const app = express();
app.use(express.urlencoded({ extended: false }));

// Verbose logging, enabled by `npm run debug`. Logs every request; AIC caches
// the agent's JWK set for about an hour, so knowing exactly when it fetched
// /keys helps correlate signature failures with key changes.
const DEBUG = process.env.RCS_DEBUG === "1" || process.argv.includes("--debug");
if (DEBUG) {
  app.use((req, _res, next) => {
    console.log(`${new Date().toISOString()} ${req.method} ${req.url} from ${req.ip}`);
    next();
  });
}

const { privateKey, publicKey } = loadSigningKeys();
const signingKey = await toJoseKey(privateKey);
const jwkSet = await getJwkSet(publicKey);

// Print the JWK set to paste into the RCS agent's "Json Web Key" field
// (Public key selector = JWKs). Regenerated from .keys/ on every start, so
// the console output is always current.
console.log("--- Paste into the RCS agent's Json Web Key field: ---");
console.log(JSON.stringify(jwkSet));
console.log("-----------------------------------------------------");

// --- Metadata and keys ------------------------------------------------------

app.get("/metadata", (_req, res) => {
  res.json({ authorization_details_types_supported: SUPPORTED_TYPES });
});

app.get("/keys", (_req, res) => {
  res.json(jwkSet);
});

// --- Consent page -----------------------------------------------------------

app.get("/consent", (req, res) => {
  const token = req.query.consent_request;
  if (!token || typeof token !== "string") {
    return res.status(400).send("Missing consent_request parameter.");
  }

  let claims;
  try {
    // The signature is not verified: this demonstration trusts whatever
    // consent request it is given. A production RCS must verify the
    // signature against the authorization server's keys and check the
    // issuer and audience.
    claims = decodeWithoutVerification(token);
  } catch (err) {
    return res.status(400).send(`Cannot read the consent request: ${escapeHtml(err.message)}`);
  }

  const requestedDetails = Array.isArray(claims.authorization_details) ? claims.authorization_details : [];
  const supportedDetails = requestedDetails.filter(isSupported);

  res.send(renderConsentPage(claims, requestedDetails, supportedDetails, token));
});

// --- Consent submission -----------------------------------------------------

app.post("/consent", async (req, res) => {
  const { consent_request: token, decision } = req.body;

  let claims;
  try {
    claims = decodeWithoutVerification(token);
  } catch (err) {
    return res.status(400).send(`Cannot read the consent request: ${escapeHtml(err.message)}`);
  }

  const redirectUri = claims.consentApprovalRedirectUri;
  if (!isHttpUrl(redirectUri)) {
    return res
      .status(400)
      .send("The consent request has no valid consentApprovalRedirectUri to post the response to.");
  }

  const requestedDetails = Array.isArray(claims.authorization_details) ? claims.authorization_details : [];
  const grantedDetails = decision === "grant" ? requestedDetails.filter(isSupported) : [];
  const clientId = clientIdOf(claims);

  let consentResponse;
  try {
    consentResponse = await new SignJWT({
      // AM expects a Boolean here ("decision": true in the docs example);
      // a string "allow" fails with "Expecting a java.lang.Boolean but got
      // java.lang.String".
      decision: decision === "grant",
      scopes: decision === "grant" ? Object.keys(claims.scopes ?? {}) : [],
      authorization_details: grantedDetails,
      // Echo the client identifier under both claim names. The consent
      // request carries it as clientId, while AM documentation and examples
      // use either name for the response, so send both.
      clientId,
      client_id: clientId,
      csrf: claims.csrf,
      save_consent: false,
    })
      .setProtectedHeader({ alg: "RS256", kid: "rcs-demo-signing-key" })
      // The response issuer must be the RCS agent ID the request was addressed
      // to (the request's aud claim); AM rejects any other value.
      .setIssuer(claims.aud)
      // The response audience must be the authorization server's issuer, the
      // full realm URL from the request's iss claim, unchanged.
      .setAudience(claims.iss)
      .setIssuedAt()
      .setExpirationTime("5m")
      .sign(signingKey);
  } catch (err) {
    return res.status(500).send(`Cannot sign the consent response: ${escapeHtml(err.message)}`);
  }

  if (DEBUG) {
    console.log(`Consent decision: ${decision === "grant" ? "allow" : "deny"}`);
    console.log(`Granted details:  ${JSON.stringify(grantedDetails)}`);
    console.log(`Posting response to: ${redirectUri}`);
    console.log(`Response JWT: ${consentResponse}`);
  }
  res.send(
    `<!DOCTYPE html><html>
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Consent recorded</title>
<style>
  body {
    font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
    font-size: 18px;
    line-height: 1.5;
    margin: 0;
    padding: 16px;
    max-width: 640px;
    margin-inline: auto;
  }
  h2 { font-size: 24px; }
  .detail {
    background: #f4f4f4;
    border-radius: 8px;
    padding: 12px;
    margin: 12px 0;
    word-break: break-all;
    font-size: 15px;
  }
  .detail div { margin-bottom: 6px; }
</style>
</head>
<body>` +
      `<h2>Consent recorded</h2>` +
      `<p>Decision: <strong>${decision === "grant" ? "Allow" : "Deny"}</strong></p>` +
      `<div class="detail">` +
        `${clientId ? `<div>Client: <code>${escapeHtml(clientId)}</code></div>` : ""}` +
        `<div>Posting consent response to:<br><code>${escapeHtml(redirectUri)}</code></div>` +
      `</div>` +
      `<p>Submitting the consent response to the authorization server. If this page stays open, the submission failed; try again, and check the RCS demo server console for details.</p>` +
      `<form id="return" method="post" action="${escapeHtml(redirectUri)}">` +
      `<input type="hidden" name="consent_response" value="${escapeHtml(consentResponse)}">` +
      `</form><script>document.getElementById("return").submit();</script>` +
      `</body></html>`,
  );
});

// --- Helpers ----------------------------------------------------------------

/** Decodes a JWT payload without verifying the signature. */
function decodeWithoutVerification(token) {
  const parts = token.split(".");
  if (parts.length !== 3) {
    throw new Error("Expected a signed three-part JWT.");
  }
  const payload = JSON.parse(Buffer.from(parts[1], "base64url").toString("utf8"));
  if (payload === null || typeof payload !== "object" || Array.isArray(payload)) {
    throw new Error("Expected the JWT payload to be a JSON object.");
  }
  return payload;
}

/** Whether a requested authorization detail is of a type this RCS supports. */
function isSupported(detail) {
  return SUPPORTED_TYPES.includes(detail?.type);
}

/** The client identifier, which the request carries as clientId or client_id. */
function clientIdOf(claims) {
  return claims.clientId ?? claims.client_id;
}

/** Whether the value is an absolute http(s) URL. */
function isHttpUrl(value) {
  try {
    return ["http:", "https:"].includes(new URL(value).protocol);
  } catch {
    return false;
  }
}

/** Escapes a value for use in HTML text and double-quoted attributes. */
function escapeHtml(value) {
  return String(value)
    .replaceAll("&", "&amp;")
    .replaceAll("<", "&lt;")
    .replaceAll(">", "&gt;")
    .replaceAll('"', "&quot;")
    .replaceAll("'", "&#39;");
}

function renderConsentPage(claims, requestedDetails, supportedDetails, token) {
  const clientId = clientIdOf(claims);
  const rows = supportedDetails
    .map((detail) => {
      const fields = Object.entries(detail)
        .filter(([key]) => key !== "type")
        .map(
          ([key, value]) =>
            `<li><code>${escapeHtml(key)}</code>: <code>${escapeHtml(JSON.stringify(value))}</code></li>`,
        )
        .join("");
      return `<h3>${escapeHtml(detail.type)}</h3><ul>${fields}</ul>`;
    })
    .join("");

  return `<!DOCTYPE html><html>
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Consent request</title>
<style>
  * { box-sizing: border-box; }
  body {
    font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
    font-size: 18px;
    line-height: 1.5;
    margin: 0;
    padding: 16px;
    max-width: 640px;
    margin-inline: auto;
  }
  code {
    font-size: 16px;
    word-break: break-all;
  }
  h1 { font-size: 26px; }
  h3 { font-size: 20px; margin-bottom: 4px; }
  ul { padding-left: 20px; margin-top: 4px; }
  li { margin-bottom: 8px; }
  button {
    font-size: 18px;
    padding: 12px 24px;
    margin-right: 12px;
    margin-top: 16px;
    border-radius: 8px;
    border: 1px solid #555;
    background: #f4f4f4;
  }
  button[name="grant"] {
    background: #1a73e8;
    color: #fff;
    border-color: #1a73e8;
  }
</style>
</head>
<body>
<h1>Consent request</h1>
${clientId ? `<p>Client: <code>${escapeHtml(clientId)}</code></p>` : ""}
${rows || "<p>No supported authorization details were requested.</p>"}
${requestedDetails.length !== supportedDetails.length ? "<p><em>Some requested detail types are not supported by this service and will not be granted.</em></p>" : ""}
<form method="post" action="/consent">
  <input type="hidden" name="consent_request" value="${escapeHtml(token)}">
  <button name="decision" value="grant">Approve</button>
  <button name="decision" value="deny">Deny</button>
</form>
</body></html>`;
}

app.listen(PORT, HOST, () => {
  console.log(`RCS demo listening on http://${HOST}:${PORT}`);
  console.log(`Metadata:  http://localhost:${PORT}/metadata`);
  console.log(`JWK set:   http://localhost:${PORT}/keys`);
  console.log(`Supported types: ${SUPPORTED_TYPES.join(", ")}`);
});
