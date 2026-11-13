/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

interface RequireContext {
  keys(): string[];
  (id: string): unknown;
}

interface NodeRequire {
  context(path: string, deep?: boolean, filter?: RegExp): RequireContext;
}
