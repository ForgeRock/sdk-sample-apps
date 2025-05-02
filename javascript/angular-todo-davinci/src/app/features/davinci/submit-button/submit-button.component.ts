/*
 * ping-sample-web-angular-davinci
 *
 * submit-button.component.ts
 *
 * Copyright (c) 2025 Ping Identity Corporation. All rights reserved.
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import { Component, Input } from '@angular/core';

@Component({
  selector: 'app-submit-button',
  templateUrl: './submit-button.component.html',
  standalone: true,
  imports: [],
})
export class SubmitButtonComponent {
  @Input() key: string;
  @Input() label: string;
  @Input() submittingForm: boolean;
}
