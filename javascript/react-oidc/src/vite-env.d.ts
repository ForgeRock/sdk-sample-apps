/*
 * vite-env.d.ts
 *
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */
/// <reference types="vite/client" />

interface ImportMetaEnv {
  readonly VITE_SCOPE: string
  readonly VITE_WEB_OAUTH_CLIENT: string
  readonly VITE_WELLKNOWN_URL: string
}
