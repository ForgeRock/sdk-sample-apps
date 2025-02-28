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
  }

  onSetIsWebAuthn(isWebAuthn: boolean): void {
    this.isWebAuthn = isWebAuthn;
  }

  onCompleteFlow(): void {
    this.router.navigateByUrl('/');
  }

  async authorize(code: string, state: string): Promise<void> {
    await TokenManager.getTokens({ query: { code, state } });
    const user = (await UserManager.getCurrentUser()) as Record<string, unknown>;
    this.userService.info = user;
    this.userService.isAuthenticated = true;
    this.router.navigateByUrl('/');
  }
}
