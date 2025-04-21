/*
 * angular-todo-prototype
 *
 * error-message.component.ts
 *
 * Copyright (c) 2021 ForgeRock. All rights reserved.
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import { Component, Input } from '@angular/core';
import { AlertIconComponent } from '../../../icons/alert-icon/alert-icon.component';

@Component({
  selector: 'app-error-message',
  templateUrl: './error-message.component.html',
  standalone: true,
  imports: [AlertIconComponent],
})
export class ErrorMessageComponent {
  @Input() message: string;
}
