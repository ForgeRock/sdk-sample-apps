/*
 * ping-sample-web-angular-davinci
 *
 * text-input.component.ts
 *
 * Copyright (c) 2025 Ping Identity Corporation. All rights reserved.
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import { Component, Input } from '@angular/core';
import { Updater } from '@forgerock/davinci-client/types';

@Component({
  selector: 'app-text-input',
  templateUrl: './text-input.component.html',
  standalone: true,
})
export class TextInputComponent {
  @Input() key: string = '';
  @Input() label: string = '';
  @Input() update: Updater | undefined = undefined;

  onBlur(event: Event): void {
    this.update && this.update((event.target as HTMLInputElement).value);
  }
}
