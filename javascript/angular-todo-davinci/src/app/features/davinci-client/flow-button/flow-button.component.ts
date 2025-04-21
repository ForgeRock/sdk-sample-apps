/*
 * angular-todo-prototype
 *
 * flow-button.component.ts
 *
 * Copyright (c) 2021 ForgeRock. All rights reserved.
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import { Component, EventEmitter, Input, Output } from '@angular/core';

@Component({
  selector: 'app-flow-button',
  templateUrl: './flow-button.component.html',
  standalone: true,
})
export class FlowButtonComponent {
  @Input() label = '';
  @Output() clicked = new EventEmitter<void>();
}
