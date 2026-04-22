/*
 * ping-sample-web-angular-davinci
 *
 * unknown.component.ts
 *
 * Copyright (c) 2025 Ping Identity Corporation. All rights reserved.
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import { Component, Input } from '@angular/core';
import { Collectors } from '@forgerock/davinci-client/types';

/**
 * Used to display a message if there is an unknown callback
 */
@Component({
  selector: 'app-unknown',
  templateUrl: './unknown.component.html',
  standalone: true,
})
export class UnknownComponent {
  /**
   * The callback that is of an unknown type
   */
  @Input() collector?: Collectors;
}
