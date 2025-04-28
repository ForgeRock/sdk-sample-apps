/*
 * ping-sample-web-angular-davinci
 *
 * form.component.ts
 *
 * Copyright (c) 2025 Ping Identity Corporation. All rights reserved.
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */
import { Component, OnInit, inject } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { Router } from '@angular/router';
import { UserService } from '../../../services/user.service';
import { DavinciService } from '../../../services/davinci/davinci.service';
import { OAuthService } from '../../../services/oauth.service';

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

import { SuccessNode } from '@forgerock/davinci-client/types';

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
  providers: [DavinciService, OAuthService],
})

/**
 * A form for managing the user authentication and authorization flow
 */
export class DavinciFormComponent implements OnInit {
  private readonly davinciService = inject(DavinciService);
  private readonly oauthService = inject(OAuthService);
  private readonly userService = inject(UserService);
  private readonly router = inject(Router);

  // Create local state using the DavinciService to manage the DaVinci flow
  node = this.davinciService.node;
  collectors = this.davinciService.collectors;
  updater = this.davinciService.updater;
  startNewFlow = this.davinciService.startNewFlowCallback;
  formName = this.davinciService.formName;
  formAction = this.davinciService.formAction;
  errorMessage = this.davinciService.errorMessage;
  isSubmittingForm = false;

  /** *********************************************************************
   * SDK INTEGRATION POINT
   * Summary: Initialize the Davinci client and flow
   * ----------------------------------------------------------------------
   * Details: Start the DaVinci flow to get the first node for rendering the form.
   ********************************************************************* */
  async ngOnInit(): Promise<void> {
    await this.davinciService.initDavinci();

    // If the initial node is a success node, then skip to handling OAuth
    const initialNode = this.node();
    console.log('intial node', initialNode);
    if (initialNode?.status === 'success') {
      this.handleSuccess(initialNode);
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
    await this.davinciService.setNext();
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
      await this.davinciService.setNext();
      const currentNode = this.node();
      if (currentNode?.status === 'success') {
        this.handleSuccess(currentNode);
      }
    } catch (error) {
      console.error(error);
    } finally {
      this.isSubmittingForm = false;
    }
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
      const user = await this.oauthService.handleOAuth({ code, state });
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
}
