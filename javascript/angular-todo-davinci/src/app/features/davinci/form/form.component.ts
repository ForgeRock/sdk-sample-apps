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

import { Collectors, DavinciClient, NodeStates } from '@forgerock/davinci-client/types';
import createClient from '../davinci.utils';
import { SdkService } from '../../../services/sdk.service';

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
})

/**
 * A form for managing the user authentication and authorization flow
 */
export class DavinciFormComponent implements OnInit {
  private readonly sdkService = inject(SdkService);
  private readonly router = inject(Router);

  /**
   * Create local state to manage the DaVinci flow
   */
  client: DavinciClient | null = null;
  node: NodeStates | null = null;
  collectors: Collectors[] = [];
  formName = '';
  formAction = '';
  errorMessage = '';
  isSubmittingForm = false;

  /**
   * @function renderForm - Set the form data for the DaVinci flow based on node status
   * @returns {void}
   */
  renderForm(): void {
    /**
     * Set the form collectors needed to compose the form
     */
    this.collectors = this.client?.getCollectors() ?? [];

    /**
     * Set any form details that should be displayed. Use the getClient() method to
     * conveniently get the client information from the node.
     */
    const clientInfo = this.client?.getClient(); // We don't have a type for ClientInfo yet
    switch (clientInfo?.status) {
      case 'continue':
        this.formName = clientInfo.name ?? '';
        this.formAction = clientInfo.action ?? '';
        break;
      case 'error':
        this.errorMessage = this.node?.error?.message ?? 'An unknown error occurred';
        break;
      case 'failure':
        this.errorMessage = 'An unknown failure occurred';
        break;
      default:
        return;
    }
  }

  /**
   * @function handleSuccess - Continue with authorization after successful login
   * @param {string} code - The authorization code from a successfully completed DaVinci flow
   * @param {string} state - The authorization state from a successfully completed DaVinci flow
   * @returns {Promise<void>}
   */
  private async successHandler(code: string, state: string): Promise<void> {
    /**
     * Upon successful login, pass the authorization code and state to the SDK
     * service to start the OIDC flow. Upon successfully retrieving a user profile,
     * redirect the user to the home page.
     */
    try {
      const user = await this.sdkService.startOidc({ code, state });
      user && this.router.navigateByUrl('/home');
    } catch (error) {
      console.error('Error handling success:', error);
      this.sdkService.isAuthenticated = false;
    }
  }

  /** *********************************************************************
   * SDK INTEGRATION POINT
   * Summary: Initialize the Davinci client and flow
   * ----------------------------------------------------------------------
   * Details: Start the DaVinci flow to get the first node for rendering
   * the form. If the user is already authenticated then skip to the OIDC
   * step otherwise render a form
   ********************************************************************* */
  async ngOnInit(): Promise<void> {
    try {
      if (!this.client || !this.node) {
        this.client = await createClient();
        this.node = (await this.client?.start()) ?? null;

        if (this.node?.status === 'success') {
          const code = this.node.client?.authorization?.code ?? '';
          const state = this.node.client?.authorization?.state ?? '';
          await this.successHandler(code, state);
        } else {
          this.renderForm();
        }
      }
    } catch (error) {
      console.error('Error initializing DaVinci: ', error);
    }
  }

  /**
   * @function shouldRenderTitle - Determines if the form title should be displayed
   * @returns {boolean} - True if there is a Protect SDK collector otherwise false
   */
  shouldRenderTitle(): boolean {
    return !this.collectors?.some((collector) => collector.name === 'protectsdk');
  }

  /**
   * @function submitHandler - The function to call when the form is submitted
   * @param {Object} event - The event object from the form submission
   * @returns {Promise<void>}
   */
  async submitHandler(event?: Event): Promise<void> {
    event?.preventDefault();
    this.isSubmittingForm = true;

    try {
      /** *********************************************************************
       * SDK INTEGRATION POINT
       * Summary: Submit the form and check the next node for next steps
       * ----------------------------------------------------------------------
       * Details: Get the next node in the flow from DaVinci. Notice there is
       * no need to pass the node with set values on collectors since the DaVinci
       * client will manage the state of the current node. Continue with the
       * authorization flow if it is a success node otherwise render another form.
       ********************************************************************* */
      this.node = (await this.client?.next()) ?? null;
      if (this.node?.status === 'success') {
        const code = this.node.client?.authorization?.code ?? '';
        const state = this.node.client?.authorization?.state ?? '';
        await this.successHandler(code, state);
      } else {
        this.renderForm();
      }
    } catch (error) {
      console.error('Error submitting form;', error);
    } finally {
      this.isSubmittingForm = false;
    }
  }
}
