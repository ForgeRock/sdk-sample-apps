/*
 * ping-sample-web-angular-davinci
 *
 * google-icon.component.ts
 *
 * Copyright (c) 2025 Ping Identity Corporation. All rights reserved.
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import { Component, Input } from '@angular/core';

@Component({
  selector: 'app-google-icon',
  templateUrl: './google-icon.component.html',
  standalone: true,
})
export class GoogleIconComponent {
  @Input() size = '24px';
}
