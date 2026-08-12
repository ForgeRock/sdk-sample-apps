/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */
import { PingError } from '@ping-identity/rn-types';

export function formatError(error: unknown): string {
  if (error instanceof PingError) {
    return error.message === error.code
      ? `[${error.code}]`
      : `[${error.code}] ${error.message}`;
  }
  if (error instanceof Error) {
    return error.message;
  }
  return String(error);
}
