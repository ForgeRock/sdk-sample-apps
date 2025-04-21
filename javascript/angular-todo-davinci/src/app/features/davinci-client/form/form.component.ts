/*
 * angular-todo-prototype
 *
 * form.component.ts
 *
 * Copyright (c) 2021 ForgeRock. All rights reserved.
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */
import { Component, EventEmitter, OnInit, Output, inject } from '@angular/core';
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
export class DavinciFormComponent implements OnInit {
  private readonly davinciService = inject(DavinciService);
  private readonly oauthService = inject(OAuthService);
  private readonly userService = inject(UserService);
  private readonly router = inject(Router);

  @Output() flowComplete = new EventEmitter<void>();

  node = this.davinciService.node;
  collectors = this.davinciService.collectors;
  updater = this.davinciService.updater;
  startNewFlow = this.davinciService.startNewFlowCallback;
  formName = this.davinciService.formName;
  formAction = this.davinciService.formAction;
  errorMessage = this.davinciService.errorMessage;
  isSubmittingForm = false;

  private finalizeAuthState(user: Record<string, string>): void {
    /**
     * Set user state/info in UserService
     */
    this.userService.username = `${user.given_name ?? ''} ${user.family_name ?? ''}`;
    this.userService.email = user.email ?? '';
    this.userService.isAuthenticated = true;
  }

  private async handleSuccess(node: SuccessNode): Promise<void> {
    try {
      const code = node.client?.authorization?.code ?? '';
      const state = node.client?.authorization?.state ?? '';
      const user = await this.oauthService.handleOAuth({ code, state });
      console.log('user', user);
      user && this.finalizeAuthState(user as Record<string, string>);

      // Redirect back to the home page
      this.router.navigateByUrl('/home');
    } catch (error) {
      console.error('Error handling success:', error);
      this.userService.isAuthenticated = false;
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

  async submitHandler(event: Event): Promise<void> {
    event.preventDefault();
    this.isSubmittingForm = true;

    try {
      await this.davinciService.setNext();
      if (this.node().status === 'success') {
        this.handleSuccess(this.node() as SuccessNode);
      }
    } catch (error) {
      console.error(error);
    } finally {
      this.isSubmittingForm = false;
    }
  }

  async ngOnInit(): Promise<void> {
    await this.davinciService.initDavinci();
    console.log('intial node', this.node());

    if (this.node().status === 'success') {
      this.handleSuccess(this.node() as SuccessNode);
    }
  }
}
