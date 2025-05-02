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

import {
  Collectors,
  NodeStates,
} from '@forgerock/davinci-client/types';
import { DaVinciClient } from '../davinci.types';
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

  // Create local state using the DavinciService to manage the DaVinci flow
  client: DaVinciClient;
  node: NodeStates = null;
  collectors: Collectors[] = [];
  formName = '';
  formAction = '';
  errorMessage = '';
  isSubmittingForm = false;

  /**
   * @function setFormData - Set the form data for the DaVinci flow
   * @returns {void}
   */
  renderForm(): void {
    const clientInfo = this.client.getClient(); // We don't have a type for ClientInfo yet
    this.collectors = this.client.getCollectors();

    if (clientInfo.status === 'continue' || clientInfo.status === 'error') {
      this.formName = clientInfo.name ?? '';
      this.formAction = clientInfo.action ?? '';
    }

    // TODO: Handle error node and continuation
    // if (node.status === 'error') {
    //   this.errorMessage = node.error?.message ?? 'An unknown error occurred';
    // }
  }

  /** *********************************************************************
   * SDK INTEGRATION POINT
   * Summary: Initialize the Davinci client and flow
   * ----------------------------------------------------------------------
   * Details: Start the DaVinci flow to get the first node for rendering the form.
   ********************************************************************* */
  async ngOnInit(): Promise<void> {
    try {
      if (!this.client || !this.node) {
        this.client = await createClient();
        this.node = await this.client.start();

        if (this.node.status === 'success') {
          const code = this.node.client.authorization?.code ?? '';
          const state = this.node.client.authorization?.state ?? '';
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
   * @function shouldRenderTitle - Determines if there is a Protect SDK collector
   * @returns {boolean} - True if there is a Protect SDK collector otherwise false
   */
  shouldRenderTitle() {
    return !this.collectors?.find(
      (collector) => collector.name === 'protectsdk',
    );
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
      /**
       * Get the next node in the flow and continue with authorization if
       * it is a success node
       */
      this.node = await this.client.next();
      if (this.node.status === 'success') {
        const code = this.node.client.authorization?.code ?? '';
        const state = this.node.client.authorization?.state ?? '';
        await this.successHandler(code, state);
      } else if (this.node.status === 'continue') {
        this.renderForm();
      }
      // TODO: Handle failure node
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
  private async successHandler(code: string, state: string) {
    /**
     * Upon successful login, pass the authorization code and state to the OAuth
     * service to get an authenticated user. Then, set the global user state in
     * the UserService and finish by redirecting to the home page.
     */
    try {
      await this.sdkService.startOidc({ code, state });

      // Redirect back to the home page
      this.router.navigateByUrl('/home');
    } catch (error) {
      console.error('Error handling success:', error);
      this.sdkService.isAuthenticated = false;
    }
  }
}
