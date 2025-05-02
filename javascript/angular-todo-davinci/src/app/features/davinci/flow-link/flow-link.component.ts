/*
 * ping-sample-web-angular-davinci
 *
 * flow-link.component.ts
 *
 * Copyright (c) 2025 Ping Identity Corporation. All rights reserved.
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import { Component, EventEmitter, Input, Output } from '@angular/core';
import { FlowCollector } from '@forgerock/davinci-client/types';

@Component({
  selector: 'app-flow-link',
  templateUrl: './flow-link.component.html',
  standalone: true,
})
export class FlowButtonComponent {
  @Input() collector: FlowCollector | null = null;
  @Input() flow: () => void;
  @Output() renderForm = new EventEmitter<void>();

  async onFlowClick() {
    await this.flow();
    this.renderForm.emit();
  }
}
