/*
 * angular-todo-prototype
 *
 * home.component.ts
 *
 * Copyright (c) 2021 ForgeRock. All rights reserved.
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import { Component, inject } from '@angular/core';
import { UserService } from '../../services/user.service';
import { HeaderComponent } from '../../layout/header/header.component';

import { VerifiedIconComponent } from '../../icons/verified-icon/verified-icon.component';
import { RouterLink } from '@angular/router';
import { FooterComponent } from '../../layout/footer/footer.component';

/**
 * Used to show a home page with information about the application, and links to sign in or register or a personalised welcome
 */
@Component({
  selector: 'app-home',
  templateUrl: './home.component.html',
  standalone: true,
  imports: [HeaderComponent, VerifiedIconComponent, RouterLink, FooterComponent],
})
export class HomeComponent {
  private readonly userService = inject(UserService);

  username = this.userService.username;
  isAuthenticated = this.userService.isAuthenticated;
}
