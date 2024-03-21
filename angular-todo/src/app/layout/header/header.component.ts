/*
 * angular-todo-prototype
 *
 * header.component.ts
 *
 * Copyright (c) 2021 ForgeRock. All rights reserved.
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import { Component, OnInit } from '@angular/core';
import { ActivatedRoute, Router } from '@angular/router';
import { UserService } from '../../services/user.service';

/**
 * Used to show a navigation bar with router links and user info
 */
@Component({
  selector: 'app-header',
  templateUrl: './header.component.html',
})
export class HeaderComponent implements OnInit {
  /**
   * Initialise with user service and router as we will be using user info and showing router links
   * @param userService - Determine whether user is authenticated and get user info retrieved by other parts of the app
   * @param router - Show router links
   */
  centralLogin: string;
  journey: string;

  constructor(
    public userService: UserService,
    public router: Router,
    private route: ActivatedRoute,
  ) {}

  ngOnInit(): void {
    this.centralLogin = this.route.snapshot.queryParamMap.get('centralLogin');
    this.journey = this.route.snapshot.queryParamMap.get('journey');
  }
}
