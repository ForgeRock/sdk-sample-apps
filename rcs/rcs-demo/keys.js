/*
 *
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 *
 */

// RSA signing keys for the demonstration RCS.
//
// On first start the app generates an RS256 keypair, writes it to .keys/ in
// this directory, and reuses it on subsequent runs. Persisting the keys keeps
// the JWK URI stable across restarts, so the authorization server's cached
// copy stays valid.

import { importPKCS8, exportJWK, generateKeyPair } from "jose";
import { createPrivateKey, createPublicKey, generateKeyPairSync } from "node:crypto";
import { existsSync, mkdirSync, readFileSync, writeFileSync } from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const KEY_DIR = path.join(path.dirname(fileURLToPath(import.meta.url)), ".keys");

const privateKeyPemPath = path.join(KEY_DIR, "signing-key.pem");
const publicKeyPemPath = path.join(KEY_DIR, "signing-key.pub.pem");

/**
 * Loads the persisted signing keys, generating and persisting a new pair on
 * first run.
 *
 * @returns {{ privateKey: import("node:crypto").PrivateKey, publicKey: import("node:crypto").PublicKey }}
 */
export function loadSigningKeys() {
  if (existsSync(privateKeyPemPath) && existsSync(publicKeyPemPath)) {
    const privateKey = createPrivateKey(readFileSync(privateKeyPemPath, "utf8"));
    const publicKey = createPublicKey(readFileSync(publicKeyPemPath, "utf8"));
    return { privateKey, publicKey };
  }

  const { publicKey, privateKey } = generateKeyPairSync("rsa", { modulusLength: 2048 });

  mkdirSync(KEY_DIR, { recursive: true });
  writeFileSync(privateKeyPemPath, privateKey.export({ type: "pkcs8", format: "pem" }));
  writeFileSync(publicKeyPemPath, publicKey.export({ type: "spki", format: "pem" }));

  return { privateKey, publicKey };
}

/**
 * Exports the signing public key as a JWK set, the format the authorization
 * server expects at the agent's Json Web Key URI.
 *
 * @param {import("node:crypto").PublicKey} publicKey
 * @returns {Promise<object>}
 */
export async function getJwkSet(publicKey) {
  const jwk = await exportJWK(publicKey);
  jwk.kid = "rcs-demo-signing-key";
  jwk.alg = "RS256";
  jwk.use = "sig";
  return { keys: [jwk] };
}

/**
 * Imports a PKCS#8 PEM private key into a WebCrypto key usable by `jose`.
 *
 * @param {import("node:crypto").PrivateKey} privateKey
 * @returns {Promise<CryptoKey>}
 */
export async function toJoseKey(privateKey) {
  const pkcs8 = privateKey.export({ type: "pkcs8", format: "pem" });
  return importPKCS8(pkcs8, "RS256");
}

export { generateKeyPair };
