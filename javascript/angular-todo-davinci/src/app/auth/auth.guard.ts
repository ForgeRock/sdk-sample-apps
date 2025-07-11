/* eslint-disable @typescript-eslint/no-unused-vars */
/*
 * ping-sample-web-angular-davinci
 *
 * auth.guard.ts
 *
 * Copyright (c) 2025 Ping Identity Corporation. All rights reserved.
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import { Injectable, inject } from '@angular/core';
import { UrlTree, Router } from '@angular/router';
import { TokenStorage, UserManager } from '@forgerock/javascript-sdk';

@Injectable({
  providedIn: 'root',
})
export class AuthGuard {
  private readonly router = inject(Router);

  /**
   * Extends CanActivate to protect selected routes from unauthenticated access
   *
   * @returns Promise - Boolean or route to redirect the user to
   */
  async canActivate(): Promise<true | UrlTree> {
    const loginUrl = this.router.parseUrl('/login');
    try {
      /** *****************************************************************
       * SDK INTEGRATION POINT
       * Summary: Optional client-side route access validation
       * ------------------------------------------------------------------
       * Details: Here, we make sure tokens exist using TokenStorage.get()
       * however there are other checks – validate tokens, session checks..
       * In this case, we are calling the userinfo endpoint to
       * ensure valid tokens before continuing, but it's optional.
       ***************************************************************** */
      const tokens = await TokenStorage.get();
      const info = await UserManager.getCurrentUser();
      if (tokens === undefined || info === undefined) {
        return loginUrl;
      }

      // Assume user is likely authenticated if there are tokens
      return true;
    } catch (err) {
      // User likely not authenticated
      console.log(err);
      return loginUrl;
    }
  }
}
