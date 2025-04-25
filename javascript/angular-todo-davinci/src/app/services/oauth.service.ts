/*
 * ping-sample-web-angular-davinci
 *
 * oauth.service.ts
 *
 * Copyright (c) 2025 Ping Identity Corporation. All rights reserved.
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import { Injectable } from '@angular/core';
import { TokenManager, UserManager } from '@forgerock/javascript-sdk';

/**
 * Used to handle the OAuth flow
 */
@Injectable()
export class OAuthService {
  /**
   * @function handleOAuth - The function to call when we get a successful login
   * @returns {Promise<unknown>} - The user if authorization was successful
   */
  async handleOAuth(params: { code: string; state: string }): Promise<unknown> {
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
    } catch (err) {
      console.error(`Error: get tokens; ${err}`);
    }

    /** *********************************************************************
     * SDK INTEGRATION POINT
     * Summary: Call the user info endpoint for some basic user data.
     * ----------------------------------------------------------------------
     * Details: This is an OAuth2 call that returns user information with a
     * valid access token. This is optional and only used for displaying
     * user info in the UI.
     ********************************************************************* */
    try {
      const user = await UserManager.getCurrentUser();
      return user;
    } catch (err) {
      console.error(`Error: get current user; ${err}`);
      return null;
    }
  }
}
