/*
 * ping-sample-web-angular-davinci
 *
 * header.component.ts
 *
 * Copyright (c) 2025 Ping Identity Corporation. All rights reserved.
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import { Component, inject } from '@angular/core';
import { Router, RouterLink } from '@angular/router';
import { SdkService } from '../../services/sdk.service';
import { NgClass } from '@angular/common';
import { PingIconComponent } from '../../icons/ping-icon/ping-icon.component';
import { AngularIconComponent } from '../../icons/angular-icon/angular-icon.component';
import { HomeIconComponent } from '../../icons/home-icon/home-icon.component';
import { TodosIconComponent } from '../../icons/todos-icon/todos-icon.component';
import { AccountIconComponent } from '../../icons/account-icon/account-icon.component';

/**
 * Used to show a navigation bar with router links and user info
 */
@Component({
  selector: 'app-header',
  templateUrl: './header.component.html',
  standalone: true,
  imports: [
    RouterLink,
    NgClass,
    PingIconComponent,
    AngularIconComponent,
    HomeIconComponent,
    TodosIconComponent,
    AccountIconComponent,
  ],
})
export class HeaderComponent {
  private readonly routerService = inject(Router);
  private readonly sdkService = inject(SdkService);

  router = this.routerService;
  isAuthenticated = this.sdkService.isAuthenticated;
  username = this.sdkService.username;
  email = this.sdkService.email;
}
