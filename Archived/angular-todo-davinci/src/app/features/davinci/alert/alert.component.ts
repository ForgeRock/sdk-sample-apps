/*
 * ping-sample-web-angular-davinci
 *
 * alert.component.ts
 *
 * Copyright (c) 2025 Ping Identity Corporation. All rights reserved.
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import { Component, Input } from '@angular/core';
import { AlertIconComponent } from '../../../icons/alert-icon/alert-icon.component';
import { VerifiedIconComponent } from '../../../icons/verified-icon/verified-icon.component';

/**
 * Used for displaying for errors
 */
@Component({
  selector: 'app-alert',
  templateUrl: './alert.component.html',
  standalone: true,
  imports: [AlertIconComponent, VerifiedIconComponent],
})
export class AlertComponent {
  /**
   * Determines whether this is an error or success alert
   */
  @Input() type?: string;

  /**
   * The message to display
   */
  @Input() message?: string;
}
