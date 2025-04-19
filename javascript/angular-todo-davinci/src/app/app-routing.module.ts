/*
 * angular-todo-prototype
 *
 * app-routing.module.ts
 *
 * Copyright (c) 2021 ForgeRock. All rights reserved.
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import { NgModule } from '@angular/core';
import { Routes } from '@angular/router';
import { RouterModule } from '@angular/router';
import { AuthGuard } from './auth/auth.guard';

const routes: Routes = [
  { path: 'home', loadComponent: () => import('./views/home/home.component').then(m => m.HomeComponent) },
  { path: 'login', loadComponent: () => import('./views/login/login.component').then(m => m.LoginComponent) },
  { path: 'todos', canActivate: [AuthGuard], loadComponent: () => import('./views/todos/todos.component').then(m => m.TodosComponent) },
  { path: 'logout', loadComponent: () => import('./features/logout/logout.component').then(m => m.LogoutComponent) },
  { path: '', redirectTo: '/home', pathMatch: 'full' }, // redirect to `first-component`
];

/**
 * Defines the routes and auth guards for the application
 */
@NgModule({
  imports: [RouterModule.forRoot(routes)],
  exports: [RouterModule],
})
export class AppRoutingModule {}
