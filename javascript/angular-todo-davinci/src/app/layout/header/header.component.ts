/*
 * angular-todo-prototype
 *
 * header.component.ts
 *
 * Copyright (c) 2021 ForgeRock. All rights reserved.
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import { Component, inject } from '@angular/core';
import { Router, RouterLink } from '@angular/router';
import { UserService } from '../../services/user.service';
import { NgClass, NgTemplateOutlet } from '@angular/common';
import { ForgerockIconComponent } from '../../icons/forgerock-icon/forgerock-icon.component';
import { AngularIconComponent } from '../../icons/angular-icon/angular-icon.component';
import { HomeIconComponent } from '../../icons/home-icon/home-icon.component';
import { TodosIconComponent } from '../../icons/todos-icon/todos-icon.component';
import { AccountIconComponent } from '../../icons/account-icon/account-icon.component';

/**
 * Used to show a navigation bar with router links and user info
 */
@Component({
  selector: 'app-header',
  templateUrl: './header.component.html',
  standalone: true,
  imports: [
    RouterLink,
    NgClass,
    ForgerockIconComponent,
    AngularIconComponent,
    NgTemplateOutlet,
    HomeIconComponent,
    TodosIconComponent,
    AccountIconComponent,
  ],
})
export class HeaderComponent {
  userService = inject(UserService);
  router = inject(Router);
}
