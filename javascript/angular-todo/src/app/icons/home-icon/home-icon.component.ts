/*
 * angular-todo-prototype
 *
 * home-icon.component.ts
 *
 * Copyright (c) 2021 - 2025 Ping Identity Corporation. All rights reserved.
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import { Component, Input } from '@angular/core';

@Component({
  selector: 'app-home-icon',
  templateUrl: './home-icon.component.html',
})
export class HomeIconComponent {
  @Input() size = '24px';
}
