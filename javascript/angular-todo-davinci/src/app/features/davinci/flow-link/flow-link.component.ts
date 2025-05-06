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
import { FlowCollector, InitFlow } from '@forgerock/davinci-client/types';

@Component({
  selector: 'app-flow-link',
  templateUrl: './flow-link.component.html',
  standalone: true,
})
export class FlowButtonComponent {
  @Input() collector: FlowCollector | null = null;
  @Input() flow: InitFlow | undefined = undefined;
  @Output() renderForm = new EventEmitter<void>();

  /** *********************************************************************
   * SDK INTEGRATION POINT
   * Summary: Start a new DaVinci flow from a flow collector
   * ----------------------------------------------------------------------
   * Details: The DaVinci client provides a flow method for retrieving
   * the first node from a new flow. This component accepts this "flow" input
   * and triggers a form re-render with this new flow when the flow link is clicked.
   ********************************************************************* */
  async onFlowClick() {
    if (this.flow) {
      await this.flow();
      this.renderForm.emit();
    }
  }
}
