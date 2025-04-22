/*
 * angular-todo-prototype
 *
 * app.component.ts
 *
 * Copyright (c) 2021 ForgeRock. All rights reserved.
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import { OnInit, inject } from '@angular/core';
import { Component } from '@angular/core';
import { Config, UserManager } from '@forgerock/javascript-sdk';
import { AsyncConfigOptions } from '@forgerock/javascript-sdk/src/config/interfaces';
import { UserService } from './services/user.service';
import { Router, RouterOutlet } from '@angular/router';
import { NavigationCancel, NavigationEnd, NavigationError, NavigationStart } from '@angular/router';
import { Observable } from 'rxjs';
import { filter } from 'rxjs/operators';
import createConfig from '../utilities/create-config';

import { LoadingComponent } from './utilities/loading/loading.component';

@Component({
  selector: 'app-root',
  templateUrl: './app.component.html',
  standalone: true,
  imports: [RouterOutlet, LoadingComponent],
})
export class AppComponent implements OnInit {
  private readonly userService = inject(UserService);
  private readonly router = inject(Router);

  loading = false;

  constructor() {
    const router = this.router;

    const navStart = router.events.pipe(
      filter((evt) => evt instanceof NavigationStart),
    ) as Observable<NavigationStart>;

    const navEnd = router.events.pipe(
      filter(
        (evt) =>
          evt instanceof NavigationEnd ||
          evt instanceof NavigationCancel ||
          evt instanceof NavigationError,
      ),
    );

    navStart.subscribe(() => (this.loading = true));
    navEnd.subscribe(() => (this.loading = false));
  }

  /**
   * Initialize the SDK and try to load the user when the app loads
   */
  async ngOnInit(): Promise<void> {
    /** ***************************************************************************
     * SDK INTEGRATION POINT
     * Summary: Configure the SDK
     * ----------------------------------------------------------------------------
    * Details: The config generator below will create the following settings which
    * can be passed to the SDK's Config.setAsync() method to initalize the SDK:
    * - clientId: (OAuth 2.0 only) this is the OAuth 2.0 client you created in PingOne
    * - redirectUri: (OAuth 2.0 only) this is the URI/URL of this app to which the
    *   OAuth 2.0 flow redirects
    * - scope: (OAuth 2.0 only) these are the OAuth scopes that you will request from
    *   PingOne
    * - serverConfig: this includes the wellknown URL of your PingOne environment
     *************************************************************************** */

    const config: AsyncConfigOptions = createConfig();
    await Config.setAsync(config);

    /** *****************************************************************
     * SDK INTEGRATION POINT
     * Summary: Optional client-side route access validation
     * ------------------------------------------------------------------
     * Details: Here, you could just make sure tokens exist –
     * TokenStorage.get() – or, validate tokens, renew expiry timers,
     * session checks ... Below, we are calling the userinfo endpoint to
     * ensure valid tokens before continuing, but it's optional.
     ***************************************************************** */
    try {
      // The user is authenticated if we can get the user info
      const user = (await UserManager.getCurrentUser()) as Record<string, unknown>;
      this.userService.isAuthenticated = true;
      this.userService.username = `${user.given_name ?? ''} ${user.family_name ?? ''}`;
      this.userService.email = `${user.email ?? ''}`;
    } catch (err) {
      // User likely not authenticated
      console.log(err);
    }
  }
}
