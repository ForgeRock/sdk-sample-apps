/*
 * angular-todo-prototype
 *
 * flow-link.component.ts
 *
 * Copyright (c) 2021 ForgeRock. All rights reserved.
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import { Component, Input } from '@angular/core';
import { FlowCollector } from '@forgerock/davinci-client/types';
// import { FlowCollector } from '@forgerock/davinci-client/types';

@Component({
  selector: 'app-flow-link',
  templateUrl: './flow-link.component.html',
  standalone: true,
})
export class FlowButtonComponent {
  @Input() collector: FlowCollector | null = null;
  @Input() startNewFlow: (collector: FlowCollector) => Promise<void> | null = null;

  async onFlowClick() {
    await this.startNewFlow(this.collector);
  }
}
