/*
 * angular-todo-prototype
 *
 * app.module.ts
 *
 * Copyright (c) 2021 ForgeRock. All rights reserved.
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import { NgModule } from '@angular/core';
import { BrowserModule } from '@angular/platform-browser';

import { AppRoutingModule } from './app-routing.module';
import { FormsModule } from '@angular/forms';

import { AppComponent } from './app.component';
import { LoginComponent } from './views/login/login.component';
import { HomeComponent } from './views/home/home.component';
import { TodosComponent } from './views/todos/todos.component';
import { ErrorMessageComponent } from './features/davinci-client/error-message/error-message.component';
import { FlowButtonComponent } from './features/davinci-client/flow-button/flow-button.component';
import { PasswordComponent } from './features/davinci-client/password/password.component';
import { ProtectComponent } from './features/davinci-client/protect/protect.component';
import { SubmitButtonComponent } from './features/davinci-client/submit-button/submit-button.component';
import { TextInputComponent } from './features/davinci-client/text-input/text-input.component';
import { LogoutComponent } from './features/logout/logout.component';
import { TodoComponent } from './features/todo/todo.component';
import { BackHomeComponent } from './utilities/back-home/back-home.component';
import { LoadingComponent } from './utilities/loading/loading.component';
import { HomeIconComponent } from './icons/home-icon/home-icon.component';
import { LeftArrowIconComponent } from './icons/left-arrow-icon/left-arrow-icon.component';
import { KeyIconComponent } from './icons/key-icon/key-icon.component';
import { EyeIconComponent } from './icons/eye-icon/eye-icon.component';
import { AlertIconComponent } from './icons/alert-icon/alert-icon.component';
import { VerifiedIconComponent } from './icons/verified-icon/verified-icon.component';
import { LockIconComponent } from './icons/lock-icon/lock-icon.component';
import { NewUserIconComponent } from './icons/new-user-icon/new-user-icon.component';
import { HeaderComponent } from './layout/header/header.component';
import { FooterComponent } from './layout/footer/footer.component';
import { AngularIconComponent } from './icons/angular-icon/angular-icon.component';
import { ForgerockIconComponent } from './icons/forgerock-icon/forgerock-icon.component';
import { TodosIconComponent } from './icons/todos-icon/todos-icon.component';
import { AccountIconComponent } from './icons/account-icon/account-icon.component';
import { TodoIconComponent } from './icons/todo-icon/todo-icon.component';
import { ActionIconComponent } from './icons/action-icon/action-icon.component';
import { GoogleIconComponent } from './icons/google-icon/google-icon.component';
import { AppleIconComponent } from './icons/apple-icon/apple-icon.component';
import { FingerPrintIconComponent } from './icons/finger-print-icon/finger-print-icon.component';
import { DaVinciFlowComponent } from './features/davinci-client/davinci-flow/davinci-flow.component';

@NgModule({
  declarations: [
    AppComponent,
    LoginComponent,
    HomeComponent,
    TodosComponent,
    DaVinciFlowComponent,
    ErrorMessageComponent,
    FlowButtonComponent,
    PasswordComponent,
    ProtectComponent,
    SubmitButtonComponent,
    TextInputComponent,
    LogoutComponent,
    TodoComponent,
    BackHomeComponent,
    LoadingComponent,
    HomeIconComponent,
    LeftArrowIconComponent,
    KeyIconComponent,
    EyeIconComponent,
    AlertIconComponent,
    VerifiedIconComponent,
    LockIconComponent,
    NewUserIconComponent,
    HeaderComponent,
    FooterComponent,
    AngularIconComponent,
    ForgerockIconComponent,
    TodosIconComponent,
    AccountIconComponent,
    TodoIconComponent,
    ActionIconComponent,
    GoogleIconComponent,
    AppleIconComponent,
    FingerPrintIconComponent,
  ],
  imports: [BrowserModule, AppRoutingModule, FormsModule],
  providers: [],
  bootstrap: [AppComponent],
})
export class AppModule {}
