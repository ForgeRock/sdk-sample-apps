/*
 * ping-sample-web-angular-davinci
 *
 * logout.component.ts
 *
 * Copyright (c) 2025 Ping Identity Corporation. All rights reserved.
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import { OnInit, inject } from '@angular/core';
import { Component } from '@angular/core';
import { FRUser } from '@forgerock/javascript-sdk';
import { SdkService } from '../../services/sdk.service';
import { LoadingComponent } from '../../utilities/loading/loading.component';

/**
 * Used to log the user out whilst a spinner and message are displayed
 */
@Component({
  selector: 'app-logout',
  templateUrl: './logout.component.html',
  standalone: true,
  imports: [LoadingComponent],
})
export class LogoutComponent implements OnInit {
  private readonly sdkService = inject(SdkService);

  /**
   * As soon as this component loads we want to log the user out
   */
  ngOnInit(): void {
    this.logout();
  }

  /**
   * Log the user out and redirect to the home page
   */
  async logout() {
    try {
      /** *********************************************************************
       * SDK INTEGRATION POINT
       * Summary: Logout, end session and revoke tokens
       * ----------------------------------------------------------------------
       * Details: Logout and clear existing, stored data
       ********************************************************************* */
      await FRUser.logout({ logoutRedirectUri: window.location.origin });
      this.sdkService.username = '';
      this.sdkService.email = '';
      this.sdkService.isAuthenticated = false;
    } catch (err) {
      console.error(`Error: logout did not successfully complete; ${err}`);
    }
  }
}
