/*
 * angular-todo-prototype
 *
 * davinci.service.ts
 *
 * Copyright (c) 2021 ForgeRock. All rights reserved.
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import { Injectable } from '@angular/core';
import { davinci } from '@forgerock/davinci-client';
import { DaVinciConfig } from '@forgerock/davinci-client/types';

@Injectable({
  providedIn: 'root',
})

export class DavinciService {
  client = null;

  async initDavinciClient(config: DaVinciConfig): Promise<void> {
    this.client = await davinci({ config });
  }
}
