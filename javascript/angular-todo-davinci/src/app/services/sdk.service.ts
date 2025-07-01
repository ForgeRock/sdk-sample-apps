/*
 * ping-sample-web-angular-davinci
 *
 * sdk.service.ts
 *
 * Copyright (c) 2025 Ping Identity Corporation. All rights reserved.
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import { Injectable } from '@angular/core';
import { TokenManager, UserManager } from '@forgerock/javascript-sdk';

/**
 * Used to share user state between components
 */
@Injectable({
  providedIn: 'root',
})
export class SdkService {
  /**
   * State representing whether the user is authenticated or not
   */
  isAuthenticated = false;

  /**
   * State representing retrieved user information
   */
  username: string = '';
  email: string = '';

  /**
   * @function getUser - Gets user information from the authorization server
   * @returns {Promise<unknown>} - A promise that resolves to the user object if it exists
   */
  async getUser(): Promise<unknown> {
    /** *********************************************************************
     * SDK INTEGRATION POINT
     * Summary: Call the user info endpoint for some basic user data and set
     * the service state.
     * ----------------------------------------------------------------------
     * Details: This is an OAuth2 call that returns user information with a
     * valid access token. This is optional and only used for displaying
     * user info in the UI.
     ********************************************************************* */
    try {
      const user = await UserManager.getCurrentUser();
      if (user) {
        const userInfo = user as Record<string, string>;
        this.username = `${userInfo.given_name ?? ''} ${userInfo.family_name ?? ''}`;
        this.email = userInfo.email ?? '';
        this.isAuthenticated = true;
      } else {
        this.username = '';
        this.email = '';
        this.isAuthenticated = false;
      }
      return user;
    } catch (error) {
      console.error('Error getting user', error);
      return null;
    }
  }

  async startOidc(params: { code: string; state: string }): Promise<unknown> {
    /** *********************************************************************
     * SDK INTEGRATION POINT
     * Summary: Get OAuth/OIDC tokens with Authorization Code Flow w/PKCE.
     * ----------------------------------------------------------------------
     * Details: Since we have successfully authenticated the user, we can now
     * get the OAuth2/OIDC tokens. We are passing the `forceRenew` option to
     * ensure we get fresh tokens, regardless of existing tokens.
     ************************************************************************* */
    const { code, state } = params;

    try {
      await TokenManager.getTokens({
        query: { code, state },
        forceRenew: true,
      });
      const user = await this.getUser();
      return user;
    } catch (err) {
      console.error(`Error starting OIDC; ${err}`);
      return null;
    }
  }
}
