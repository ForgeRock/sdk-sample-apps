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
// import { UserService } from '../../../services/user.service';
import { DavinciService } from '../../../services/davinci/davinci.service';
import { ErrorMessageComponent } from '../error-message/error-message.component';
import { ProtectComponent } from '../protect/protect.component';
import { TextInputComponent } from '../text-input/text-input.component';
import { PasswordComponent } from '../password/password.component';
import { SubmitButtonComponent } from '../submit-button/submit-button.component';
import { FlowButtonComponent } from '../flow-button/flow-button.component';

@Component({
  selector: 'app-davinci-form',
  templateUrl: './form.component.html',
  standalone: true,
  imports: [
    FormsModule,
    ErrorMessageComponent,
    ProtectComponent,
    TextInputComponent,
    PasswordComponent,
    SubmitButtonComponent,
    FlowButtonComponent,
  ],
  providers: [DavinciService],
})
export class DavinciFormComponent implements OnInit {
  // private readonly userService = inject(UserService);
  private readonly davinciService = inject(DavinciService);

  @Output() flowComplete = new EventEmitter<void>();

  node = this.davinciService.node;
  collectors = this.davinciService.collectors;
  updater = this.davinciService.updater;
  formName = this.davinciService.formName;
  formAction = this.davinciService.formAction;
  errorMessage = this.davinciService.errorMessage;
  isSubmittingForm = false;

  async ngOnInit(): Promise<void> {
    await this.davinciService.initDavinci();
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

    console.log('submitForm');
    // const nextNode = await this.davinciClient.next();
    // this.mapRenderer(nextNode);

    try {
      await this.davinciService.setNext();
    } catch (error) {
      console.error(error);
    } finally {
      this.isSubmittingForm = false;
    }
  }

  async completeFlow(): Promise<void> {
    // const clientInfo = this.davinciService.client()?.getClient();
    // let code = '';
    // let state = '';
    // if (clientInfo?.status === 'success') {
    //   code = clientInfo.authorization?.code || '';
    //   state = clientInfo.authorization?.state || '';
    // }
    // await TokenManager.getTokens({ query: { code, state } });
    // await this.userService.populateUserInfo();
    // this.flowComplete.emit();
  }

  // async onFlowButtonClicked(collector: Collector) {
  //   console.log('onFlowButtonClicked', collector);
  //   const flow = this.davinciClient.flow({ action: collector.output.key });
  //   const node = await flow(collector.output.key);
  //   this.renderForm(node);
  // }
}
