/*
 * ping-sample-web-angular-davinci
 *
 * davinci.service.ts
 *
 * Copyright (c) 2025 Ping Identity Corporation. All rights reserved.
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import { computed, Injectable, Signal, signal, WritableSignal } from '@angular/core';
import createClient from './davinci.utils';
import { DaVinciClient, DaVinciNode } from './davinci.types';
import {
  Collectors,
  FlowCollector,
  PasswordCollector,
  TextCollector,
  Updater,
  ValidatedTextCollector,
} from '@forgerock/davinci-client/types';

@Injectable()
export class DavinciService {
  private client: WritableSignal<DaVinciClient | null> = signal(null);
  readonly node: WritableSignal<DaVinciNode | null> = signal(null);
  collectors: Signal<Collectors[]> = computed(() => {
    const currentNode = this.node();
    if (currentNode?.status === 'continue') {
      return this.client().getCollectors() ?? [];
    } else return [];
  });
  formName: Signal<string> = computed(() => {
    const currentNode = this.node();
    if (currentNode?.status === 'continue') {
      return currentNode.client.name ?? '';
    } else {
      return '';
    }
  });
  formAction: Signal<string> = computed(() => {
    const currentNode = this.node();
    if (currentNode?.status === 'continue') {
      return currentNode.client.action ?? '';
    } else {
      return '';
    }
  });
  errorMessage: Signal<string> = computed(() => {
    const currentNode = this.node();
    if (currentNode?.status === 'error') {
      return currentNode.error.message ?? '';
    } else {
      return '';
    }
  });
  updater: Signal<
    ((collector: TextCollector | ValidatedTextCollector | PasswordCollector) => Updater) | null
  > = computed(() => {
    const currentNode = this.node();
    if (this.client() && currentNode?.status === 'continue') {
      return (collector) => this.updaterFunction(this.client(), collector);
    } else {
      return null;
    }
  });

  /**
   * @function initDavinci - Initialize the DaVinci flow
   * @returns {Promise<void>}
   */
  async initDavinci(): Promise<void> {
    /** *********************************************************************
     * SDK INTEGRATION POINT
     * Summary: Initialize the Davinci client and flow
     * ----------------------------------------------------------------------
     * Details: Start the DaVinci flow to get the first node for rendering the form.
     ********************************************************************* */
    try {
      if (!this.client() || !this.node()) {
        const davinciClient = await createClient();
        const initialNode = (await davinciClient?.start()) ?? null;

        this.client.set(davinciClient);
        this.node.set(initialNode);
      }
    } catch (error) {
      console.error('Error initializing DaVinci: ', error);
    }
  }

  /**
   * @function updater - Gets the DaVinci client updater function for a collector
   * @returns {function} - A function to call with the updated value for the collector's input
   */
  updaterFunction(
    client: DaVinciClient,
    collector: TextCollector | ValidatedTextCollector | PasswordCollector,
  ): Updater {
    return client.update(collector);
  }

  /**
   * @function setNext - Get the next node in the DaVinci flow
   * @returns {Promise<void>}
   */
  async setNext() {
    /** *********************************************************************
     * SDK INTEGRATION POINT
     * Summary: Get the next node in the DaVinci flow
     * ----------------------------------------------------------------------
     * Details: Get the next node in the flow from DaVinci. No need to pass
     * the node with set values on collectors since the DaVinci client will
     * manage the state of the current node. Updates local node state with the
     * next node.
     ********************************************************************* */
    try {
      const nextNode = await this.client()?.next();
      this.node.set(nextNode);
    } catch (error) {
      console.error('Error getting next node', error);
    }
  }

  /**
   * @function startNewFlow - Starts a new DaVinci flow from a flow collector
   * @returns {Promise<void>}
   */
  startNewFlowCallback = async (collector: FlowCollector) => {
    /** *********************************************************************
     * SDK INTEGRATION POINT
     * Summary: Start a new DaVinci flow from a flow collector
     * ----------------------------------------------------------------------
     * Details: The DaVinci client provides a flow method for retrieving
     * the first node from a new flow. We set the local node state to this
     * flow node to start a new flow.
     ********************************************************************* */
    if (this.client()) {
      try {
        const getFlowNode = this.client()?.flow({ action: collector.name });
        const flowNode = await getFlowNode();
        if (flowNode.error) {
          console.error('Error starting new flow: ', flowNode.error);
          this.node.set(null);
        } else {
          this.node.set(flowNode as DaVinciNode);
        }
      } catch (error) {
        console.error('Error getting flow node: ', error);
      }
    } else {
      console.error('Missing client to start new flow');
    }
  };
}
