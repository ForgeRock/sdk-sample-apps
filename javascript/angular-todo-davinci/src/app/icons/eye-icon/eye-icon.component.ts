/*
 * angular-todo-prototype
 *
 * eye-icon.component.ts
 *
 * Copyright (c) 2021 ForgeRock. All rights reserved.
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import { Component, Input } from '@angular/core';
import { NgTemplateOutlet } from '@angular/common';

@Component({
    selector: 'app-eye-icon',
    templateUrl: './eye-icon.component.html',
    standalone: true,
    imports: [NgTemplateOutlet],
})
export class EyeIconComponent {
  @Input() visible = true;
  @Input() size = '24px';
}
