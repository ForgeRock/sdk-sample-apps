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
import { LoadingComponent } from '../../../utilities/loading/loading.component';

@Component({
  selector: 'app-protect',
  templateUrl: './protect.component.html',
  standalone: true,
  imports: [LoadingComponent],
})
export class ProtectComponent implements OnInit {
  @Input() label: string = '';
  @Input() update: Updater | null = null;
  @Input() submitProtect: (() => Promise<void>) | null = null;

  async ngOnInit() {
    this.update('fakeprofile');
    await this.submitProtect();
  }
}
