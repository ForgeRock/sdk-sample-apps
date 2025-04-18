/*
 * ping-sample-web-angular-davinci
 *
 * login.component.ts
 *
 * Copyright (c) 2025 Ping Identity Corporation. All rights reserved.
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import { Component } from '@angular/core';
import { BackHomeComponent } from '../../utilities/back-home/back-home.component';

import { DavinciFormComponent } from '../../features/davinci-client/form/form.component';

/**
 * Used to show a login page
 */
@Component({
  selector: 'app-login',
  templateUrl: './login.component.html',
  standalone: true,
  imports: [BackHomeComponent, DavinciFormComponent],
})
export class LoginComponent {}
