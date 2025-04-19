/*
 * angular-todo-prototype
 *
 * password.component.ts
 *
 * Copyright (c) 2021 ForgeRock. All rights reserved.
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import { Component, EventEmitter, Input, Output } from '@angular/core';
import { EyeIconComponent } from '../../../icons/eye-icon/eye-icon.component';

@Component({
    selector: 'app-password',
    templateUrl: './password.component.html',
    standalone: true,
    imports: [EyeIconComponent],
})
export class PasswordComponent {
  @Input() key: string;
  @Input() label: string;
  @Output() valueUpdated = new EventEmitter<string>();

  isVisible = false;

  toggleVisibility(): void {
    this.isVisible = !this.isVisible;
  }

  updateValue(event: Event): void {
    this.valueUpdated.emit((event.target as HTMLInputElement).value);
  }
}
