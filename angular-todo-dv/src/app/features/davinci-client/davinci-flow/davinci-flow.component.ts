/*
 * angular-todo-prototype
 *
 * davinci-flow.component.ts
 *
 * Copyright (c) 2021 ForgeRock. All rights reserved.
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */
import { Component, EventEmitter, OnInit, Output } from '@angular/core';
import { TokenManager } from '@forgerock/javascript-sdk';
import { UserService } from '../../../services/user.service';

interface Collector {
  category: string;
  id: string;
  name: string;
  type: string;
  input?: {
    key: string;
    value: string;
    type: string;
  };
  output: {
    key: string;
    label: string;
    type: string;
    url?: string;
  };
}

@Component({
  selector: 'app-davinci-flow',
  templateUrl: './davinci-flow.component.html',
})
export class DaVinciFlowComponent implements OnInit {
  @Output() flowComplete = new EventEmitter<void>();

  // TODO: Get proper typings and delete this and the next line
  /* eslint-disable @typescript-eslint/no-explicit-any */

  davinciClient: any;
  isSubmittingForm = false;
  collectors: Collector[] = [];
  pageHeader = '';
  errorMessage = '';

  constructor(private readonly userService: UserService) {}

  async ngOnInit(): Promise<void> {
    this.davinciClient = this.userService.loginClient;
    const node = await this.davinciClient.start();

    if (node.status !== 'success') {
      this.renderForm(node);
    } else {
      this.completeFlow();
    }
  }

  updateCollector(updateFn: (value: string) => void, value: string): void {
    updateFn(value);
  }

  async submitHandler(event: Event): Promise<void> {
    event.preventDefault();
    this.isSubmittingForm = true;

    const nextNode = await this.davinciClient.next();
    this.mapRenderer(nextNode);
  }

  async completeFlow(): Promise<void> {
    const clientInfo = this.davinciClient.getClient();

    let code = '';
    let state = '';

    if (clientInfo?.status === 'success') {
      code = clientInfo.authorization?.code || '';
      state = clientInfo.authorization?.state || '';
    }

    await TokenManager.getTokens({ query: { code, state } });

    await this.userService.populateUserInfo();
    this.flowComplete.emit();
  }

  async renderForm(nextNode: any): Promise<void> {
    // Set h1 header
    this.pageHeader = nextNode.client?.name || '';
    const collectors = this.davinciClient.getCollectors();
    // Save collectors to state
    this.collectors = collectors;

    // If node is a protect node, move to next node without user interaction
    if (collectors.find((collector) => collector.name === 'protectsdk')) {
      const nextNode = await this.davinciClient.next();
      this.mapRenderer(nextNode);
    }
  }

  async onFlowButtonClicked(collector: Collector) {
    const flow = this.davinciClient.flow({ action: collector.output.key });
    const node = await flow(collector.output.key);
    this.renderForm(node);
  }

  mapRenderer(nextNode: any): void {
    this.isSubmittingForm = false;
    if (nextNode.status === 'next') {
      this.renderForm(nextNode);
    } else if (nextNode.status === 'success') {
      this.completeFlow();
    } else if (nextNode.status === 'error') {
      this.errorMessage = nextNode.error.message;
    } else {
      console.error('Unknown node status', nextNode);
    }
  }
}
