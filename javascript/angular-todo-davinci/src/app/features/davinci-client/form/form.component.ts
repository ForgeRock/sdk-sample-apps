/*
 * ping-sample-web-angular-davinci
 *
 * form.component.ts
 *
 * Copyright (c) 2025 Ping Identity Corporation. All rights reserved.
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */
import { Component, OnInit, Signal, WritableSignal, computed, inject, signal } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { Router } from '@angular/router';
import { UserService } from '../../../services/user.service';

import { ProtectComponent } from '../protect/protect.component';
import { TextInputComponent } from '../text-input/text-input.component';
import { PasswordComponent } from '../password/password.component';
import { SubmitButtonComponent } from '../submit-button/submit-button.component';
import { FlowButtonComponent } from '../flow-link/flow-link.component';
import { LoadingComponent } from '../../../utilities/loading/loading.component';
import { AlertComponent } from '../alert/alert.component';
import { UnknownComponent } from '../unknown/unknown.component';
import { KeyIconComponent } from '../../../icons/key-icon/key-icon.component';
import { NewUserIconComponent } from '../../../icons/new-user-icon/new-user-icon.component';

import { Collectors, FlowCollector, NodeStates, PasswordCollector, SuccessNode, TextCollector, Updater, ValidatedTextCollector } from '@forgerock/davinci-client/types';
import { DaVinciClient } from '../davinci.types';
import createClient from '../davinci.utils';
import { TokenManager, UserManager } from '@forgerock/javascript-sdk';

@Component({
  selector: 'app-davinci-form',
  templateUrl: './form.component.html',
  standalone: true,
  imports: [
    FormsModule,
    ProtectComponent,
    TextInputComponent,
    PasswordComponent,
    SubmitButtonComponent,
    FlowButtonComponent,
    LoadingComponent,
    AlertComponent,
    UnknownComponent,
    KeyIconComponent,
    NewUserIconComponent,
  ],
  // providers: [DavinciService, OAuthService],
})

/**
 * A form for managing the user authentication and authorization flow
 */
export class DavinciFormComponent implements OnInit {
  // private readonly davinciService = inject(DavinciService);
  // private readonly oauthService = inject(OAuthService);
  private readonly userService = inject(UserService);
  private readonly router = inject(Router);

  // Create local state using the DavinciService to manage the DaVinci flow
  client: DaVinciClient | null = null;
  node: WritableSignal<NodeStates | null> = signal(null);
  // updater = this.davinciService.updater;
  // startNewFlow = this.davinciService.startNewFlowCallback;
  isSubmittingForm = false;

  collectors: Signal<Collectors[]> = computed(() => {
    const currentNode = this.node();
    const status = currentNode.status;
    if (status === 'continue' || status === 'error') {
      return currentNode.client.collectors ?? [];
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
      const status = this.node().status;
      if (this.client && (status === 'continue' || status === 'error')) {
        return (collector) => this.client.update(collector);
      } else {
        return null;
      }
    });

  /** *********************************************************************
   * SDK INTEGRATION POINT
   * Summary: Initialize the Davinci client and flow
   * ----------------------------------------------------------------------
   * Details: Start the DaVinci flow to get the first node for rendering the form.
   ********************************************************************* */
  async ngOnInit(): Promise<void> {
    try {
          if (!this.client || !this.node()) {
            const davinciClient = await createClient();
            const initialNode = (await davinciClient?.start()) ?? null;
    
            this.client = davinciClient;
            this.node.set(initialNode);

            // If the initial node is a success node, then skip to handling OAuth
            console.log('intial node', initialNode);
            if (initialNode?.status === 'success') {
              await this.handleSuccess(initialNode);
            }
          }
  } catch (error) {
    console.error('Error initializing DaVinci: ', error);
  }
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
      const nextNode = await this.client?.next();
      this.node.set(nextNode);
    } catch (error) {
      console.error('Error getting next node', error);
    }
  }

  /**
   * @function hasProtectCollector - Determines if there is a Protect SDK collector
   * @param {Object} collectors - An array of collectors from DaVinci
   * @returns {boolean} - True if there is a Protect SDK collector otherwise false
   */
  hasProtectCollector(collectors) {
    return collectors?.some(
      (collector) => collector.type === 'TextCollector' && collector.name === 'protectsdk',
    );
  }

  /**
   * @function submitProtect - Handles Protect collector submission
   * @returns {Promise<void>}
   */
  submitProtectCallback = async (): Promise<void> => {
    await this.setNext();
  };

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
    if (this.client) {
      try {
        const getFlowNode = this.client.flow({ action: collector.name });
        const flowNode = await getFlowNode();
        if (flowNode.error) {
          console.error('Error starting new flow: ', flowNode.error);
          this.node.set(null);
        } else {
          this.node.set(flowNode as NodeStates);
        }
      } catch (error) {
        console.error('Error getting flow node: ', error);
      }
    } else {
      console.error('Missing client to start new flow');
    }
  };

  /**
   * @function submitHandler - The function to call when the form is submitted
   * @param {Object} event - The event object from the form submission
   * @returns {Promise<void>}
   */
  async submitHandler(event: Event): Promise<void> {
    event.preventDefault();
    this.isSubmittingForm = true;

    try {
      /**
       * Get the next node in the flow and continue with authorization if
       * it is a success node
       */
      await this.setNext();
      const currentNode = this.node();
      if (currentNode?.status === 'success') {
        await this.handleSuccess(currentNode);
      }
    } catch (error) {
      console.error(error);
    } finally {
      this.isSubmittingForm = false;
    }
  }

  /**
   * @function handleOAuth - The function to call when we get a successful login
   * @returns {Promise<unknown>} - The user if authorization was successful
   */
  async handleOAuth(params: { code: string; state: string }): Promise<unknown> {
    /** *********************************************************************
     * SDK INTEGRATION POINT
     * Summary: Get OAuth/OIDC tokens with Authorization Code Flow w/PKCE.
     * ----------------------------------------------------------------------
     * Details: Since we have successfully authenticated the user, we can now
     * get the OAuth2/OIDC tokens. We are passing the `forceRenew` option to
     * ensure we get fresh tokens, regardless of existing tokens.
     ************************************************************************* */
    const { code, state } = params;
    try {
      await TokenManager.getTokens({
        query: { code, state },
        forceRenew: true,
      });
    } catch (err) {
      console.error(`Error: get tokens; ${err}`);
    }

    /** *********************************************************************
     * SDK INTEGRATION POINT
     * Summary: Call the user info endpoint for some basic user data.
     * ----------------------------------------------------------------------
     * Details: This is an OAuth2 call that returns user information with a
     * valid access token. This is optional and only used for displaying
     * user info in the UI.
     ********************************************************************* */
    try {
      const user = await UserManager.getCurrentUser();
      return user;
    } catch (err) {
      console.error(`Error: get current user; ${err}`);
      return null;
    }
  }

  /**
   * @function finalizeAuthState - Update global state in the UserService
   * @param {Record<string, string>} user - A user from the JS SDK
   * @returns {void}
   */
    private finalizeAuthState(user: Record<string, string>): void {
      this.userService.username = `${user.given_name ?? ''} ${user.family_name ?? ''}`;
      this.userService.email = user.email ?? '';
      this.userService.isAuthenticated = true;
    }

  /**
   * @function handleSuccess - Continue with authorization after successful login
   * @param {SuccessNode} node - A success node from the DaVinci flow
   * @returns {Promise<void>}
   */
  private async handleSuccess(node: SuccessNode): Promise<void> {
    /**
     * Upon successful login, pass the authorization code and state to the OAuth
     * service to get an authenticated user. Then, set the global user state in
     * the UserService and finish by redirecting to the home page.
     */
    try {
      const code = node.client?.authorization?.code ?? '';
      const state = node.client?.authorization?.state ?? '';
      const user = await this.handleOAuth({ code, state });
      if (user) {
        this.finalizeAuthState(user as Record<string, string>);

        // Redirect back to the home page
        this.router.navigateByUrl('/home');
      } else {
        this.userService.isAuthenticated = false;
      }
    } catch (error) {
      console.error('Error handling success:', error);
      this.userService.isAuthenticated = false;
    }
  }
}
