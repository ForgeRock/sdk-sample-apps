/*
 * angular-todo-prototype
 *
 * text-input.component.ts
 *
 * Copyright (c) 2021 ForgeRock. All rights reserved.
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import { Component, EventEmitter, Input, Output } from '@angular/core';

@Component({
  selector: 'app-text-input',
  templateUrl: './text-input.component.html',
})
export class TextInputComponent {
  @Input() key: string;
  @Input() label: string;
  @Output() valueUpdated = new EventEmitter<string>();

  onChange(event: Event): void {
    this.valueUpdated.emit((event.target as HTMLInputElement).value);
  }
}
