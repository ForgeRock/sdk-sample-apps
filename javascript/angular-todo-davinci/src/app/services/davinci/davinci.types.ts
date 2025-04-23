/*
 * ping-sample-web-angular-davinci
 *
 * davinci.types.ts
 *
 * Copyright (c) 2025 Ping Identity Corporation. All rights reserved.
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import { davinci } from '@forgerock/davinci-client';

type Awaited<T> = T extends Promise<infer U> ? U : T;
export type DaVinciClient = Awaited<ReturnType<typeof davinci>>;
export type DaVinciNode = Awaited<ReturnType<Awaited<ReturnType<typeof davinci>>['next']>>;
