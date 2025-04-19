/*
 * angular-todo-prototype
 *
 * protect.component.ts
 *
 * Copyright (c) 2021 ForgeRock. All rights reserved.
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import { Component, EventEmitter, Input, OnInit, Output } from '@angular/core';

@Component({
    selector: 'app-protect',
    templateUrl: './protect.component.html',
    standalone: true,
})
export class ProtectComponent implements OnInit {
  @Input() label = '';
  @Output() protectProfile = new EventEmitter<string>();

  ngOnInit() {
    this.protectProfile.emit('fakeprofile');
  }
}
