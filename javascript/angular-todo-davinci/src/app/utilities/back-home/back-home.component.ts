/*
 * ping-sample-web-angular-davinci
 *
 * back-home.component.ts
 *
 * Copyright (c) 2025 Ping Identity Corporation. All rights reserved.
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import { Component } from '@angular/core';
import { RouterLink } from '@angular/router';
import { LeftArrowIconComponent } from '../../icons/left-arrow-icon/left-arrow-icon.component';

/**
 * Used to provide a link to take the user to the root of the application
 */
@Component({
  selector: 'app-back-home',
  templateUrl: './back-home.component.html',
  standalone: true,
  imports: [RouterLink, LeftArrowIconComponent],
})
export class BackHomeComponent {}
