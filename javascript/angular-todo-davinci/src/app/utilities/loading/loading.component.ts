/*
 * ping-sample-web-angular-davinci
 *
 * loading.component.ts
 *
 * Copyright (c) 2025 Ping Identity Corporation. All rights reserved.
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import { Component, Input } from '@angular/core';

/**
 * Used to show a spinner and message during loading / processing steps
 */
@Component({
  selector: 'app-loading',
  templateUrl: './loading.component.html',
  standalone: true,
})
export class LoadingComponent {
  /**
   * The header to be displayed with the spinner
   */
  @Input() header?: string;
  /**
   * The message to be displayed with the spinner
   */
  @Input() message?: string;
}
