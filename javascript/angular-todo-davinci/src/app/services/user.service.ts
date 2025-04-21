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
   * State representing previously retrieved user information
   */
  username: string = '';
  email: string = '';
}
