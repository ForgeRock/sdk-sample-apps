/*
 * angular-todo-prototype
 *
 * login.component.ts
 *
 * Copyright (c) 2021 ForgeRock. All rights reserved.
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import { Component, OnInit } from '@angular/core';
import { environment } from '../../../environments/environment';
import { TokenManager, UserManager } from '@forgerock/javascript-sdk';
import { ActivatedRoute, Router } from '@angular/router';
import { UserService } from '../../services/user.service';

/**
 * Used to show a login page
 */
@Component({
  selector: 'app-login',
  templateUrl: './login.component.html',
})
export class LoginComponent implements OnInit {
  isWebAuthn = false;
  code: string;
  error: string;
  state: string;
  centralLogin: string;
  loadingMessage: string;
  journey: string;

  get isCentralizedLogin(): boolean {
    return this.centralLogin === 'true' || environment.CENTRALIZED_LOGIN === 'true' ? true : false;
  }

  constructor(
    private route: ActivatedRoute,
    public userService: UserService,
    private router: Router,
  ) {}

  async ngOnInit(): Promise<void> {
    this.code = this.route.snapshot.queryParamMap.get('code');
    this.error = this.route.snapshot.queryParamMap.get('error');
    this.state = this.route.snapshot.queryParamMap.get('state');
    this.centralLogin = this.route.snapshot.queryParamMap.get('centralLogin');
    this.journey = this.route.snapshot.queryParamMap.get('journey');

    if (this.isCentralizedLogin) {
      if (this.code && this.state) {
        /** *****************************************************************
         * SDK INTEGRATION POINT
         * Summary: Get OAuth/OIDC tokens with Authorization Code Flow w/PKCE.
         * ------------------------------------------------------------------
         * Details:When the user return to this app after successfully logging in,
         * the URL will include code and state query parameters that need to
         * be passed in to complete the OAuth flow giving the user access
         ***************************************************************** */
        this.loadingMessage = 'Success! Redirecting ...';
        await this.authorize(this.code, this.state);
      } else if (this.error) {
        // Do nothing as this will result in a redirect
      } else {
        /** *****************************************************************
         * SDK INTEGRATION POINT
         * Summary: Get OAuth/OIDC tokens with Authorization Code Flow w/PKCE.
         * ------------------------------------------------------------------
         * The key-value of `login: redirect` is what allows central-login.
         * Passing no arguments or a key-value of `login: 'embedded'` means
         * the app handles authentication locally
         ***************************************************************** */
        this.loadingMessage = 'Redirecting ...';
        await TokenManager.getTokens({ login: 'redirect', query: { acr_values: 'simpleLogin' } });
      }
    }
  }

  onSetIsWebAuthn(isWebAuthn: boolean): void {
    this.isWebAuthn = isWebAuthn;
  }

  async authorize(code: string, state: string): Promise<void> {
    await TokenManager.getTokens({ query: { code, state } });
    const user = (await UserManager.getCurrentUser()) as Record<string, unknown>;
    this.userService.info = user;
    this.userService.isAuthenticated = true;
    this.router.navigateByUrl('/');
  }
}
