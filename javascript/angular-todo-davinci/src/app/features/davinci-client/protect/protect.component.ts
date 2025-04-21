/*
 * angular-todo-prototype
 *
 * protect.component.ts
 *
 * Copyright (c) 2021 ForgeRock. All rights reserved.
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import { Component, Input, OnInit } from '@angular/core';
import { Updater } from '@forgerock/davinci-client/types';

@Component({
    selector: 'app-protect',
    templateUrl: './protect.component.html',
    standalone: true,
})
export class ProtectComponent implements OnInit {
  @Input() label: string = '';
  @Input() update: Updater | null = null;
  @Input() submitProtect: (() => Promise<void>) | null = null;

  async ngOnInit() {
    this.update('fakeprofile');
    await this.submitProtect.bind(this)();
  }
}
