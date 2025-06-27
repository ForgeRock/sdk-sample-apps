/*
 * angular-todo-prototype
 *
 * user.service.ts
 *
 * Copyright (c) 2021 ForgeRock. All rights reserved.
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import { Injectable } from '@angular/core';
import davinciClient from '@forgerock/davinci-client';
import { UserManager } from '@forgerock/javascript-sdk';

/**
 * Used to share user state between components
 */
@Injectable({
  providedIn: 'root',
})
export class UserService {
  /**
   * State representing whether the user is authenticated or not
   */
  isAuthenticated = false;

  /**
   * State repreesnting previously retrieved user information
   */
  info?: Record<string, unknown>;

  loginClient: unknown = null;

  async initLoginClient(config: unknown): Promise<void> {
    this.loginClient = await davinciClient({ config });
  }

  async populateUserInfo(): Promise<void> {
    const info = (await UserManager.getCurrentUser()) as Record<string, unknown>;
    this.isAuthenticated = true;
    this.info = info;
  }
}
