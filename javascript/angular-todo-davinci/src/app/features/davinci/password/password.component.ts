/*
 * ping-sample-web-angular-davinci
 *
 * password.component.ts
 *
 * Copyright (c) 2025 Ping Identity Corporation. All rights reserved.
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import { Component, Input } from '@angular/core';
import { EyeIconComponent } from '../../../icons/eye-icon/eye-icon.component';
import { Updater } from '@forgerock/davinci-client/types';

@Component({
  selector: 'app-password',
  templateUrl: './password.component.html',
  standalone: true,
  imports: [EyeIconComponent],
})
export class PasswordComponent {
  @Input() key: string = '';
  @Input() label: string = '';
  @Input() update: Updater | undefined = undefined;

  isVisible = false;

  toggleVisibility(): void {
    this.isVisible = !this.isVisible;
  }

  onBlur(event: Event): void {
    this.update && this.update((event.target as HTMLInputElement).value);
  }
}
