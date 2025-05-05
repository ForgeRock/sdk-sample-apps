/*
 * ping-sample-web-angular-davinci
 *
 * protect.component.ts
 *
 * Copyright (c) 2025 Ping Identity Corporation. All rights reserved.
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import { Component, EventEmitter, Input, OnInit, Output } from '@angular/core';
import { LoadingComponent } from '../../../utilities/loading/loading.component';
import { Updater } from '@forgerock/davinci-client/types';

/**
 * The protect collector is sent with the first node of the flow, but
 * it is not needed. It is a self-submitting node which requires no
 * user interaction. While you would normally load the Protect module
 * here and wait for a response, we instead mock the response with a
 * dummy value and update the collector. Then call the
 * submit function to proceed with the flow.
 */
@Component({
  selector: 'app-protect',
  templateUrl: './protect.component.html',
  standalone: true,
  imports: [LoadingComponent],
})
export class ProtectComponent implements OnInit {
  /**
   * The protect collector is sent with the first node of the flow, but
   * it is not needed. It is a self-submitting node which requires no
   * user interaction. While you would normally load the Protect module
   * here and wait for a response, we instead mock the response with a
   * dummy value and update the collector. Then call the
   * submit function to proceed with the flow.
   */

  @Input() label: string = '';
  @Input() update: Updater | undefined = undefined;
  @Output() submitHandler = new EventEmitter<void>();

  async ngOnInit() {
    if (this.update) {
      this.update('fakeprofile');
      await this.submitHandler.emit();
    }
  }
}
