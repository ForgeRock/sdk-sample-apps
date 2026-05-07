/*
 * ping-sample-web-angular-davinci
 *
 * verified-icon.component.ts
 *
 * Copyright (c) 2025 Ping Identity Corporation. All rights reserved.
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import { Component, Input } from '@angular/core';

@Component({
  selector: 'app-verified-icon',
  templateUrl: './verified-icon.component.html',
  standalone: true,
})
export class VerifiedIconComponent {
  @Input() size = '24px';
}
