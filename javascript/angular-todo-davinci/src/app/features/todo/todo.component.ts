/*
 * ping-sample-web-angular-davinci
 *
 * todo.component.ts
 *
 * Copyright (c) 2025 Ping Identity Corporation. All rights reserved.
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import { Component, EventEmitter, Input, Output } from '@angular/core';
import { Todo } from './todo';
import { NgClass } from '@angular/common';
import { TodoIconComponent } from '../../icons/todo-icon/todo-icon.component';
import { ActionIconComponent } from '../../icons/action-icon/action-icon.component';

/**
 * Used to display a Todo retrieved from the backend, handles user interaction with an existing Todo
 */
@Component({
  selector: 'app-todo',
  templateUrl: './todo.component.html',
  standalone: true,
  imports: [NgClass, TodoIconComponent, ActionIconComponent],
})
export class TodoComponent {
  /**
   * The Todo being displayed
   */
  @Input() todo?: Todo;

  /**
   * Emits a completed Todo to be updated
   */
  @Output() completed = new EventEmitter<Todo>();

  /**
   * Emits an edited Todo to be updated
   */
  @Output() edit = new EventEmitter<Todo>();

  /**
   * Emits a Todo marked for deletion
   */
  @Output() delete = new EventEmitter<Todo>();

  /**
   * Emit an event to the parent component, passing the value of the Todo to be completed
   * @param todo - the Todo to be completed
   */
  setComplete(todo: Todo): void {
    this.completed.emit(todo);
  }

  /**
   * Emit an event to the parent component, passing the value of the Todo to be opened for editing
   * @param todo - the Todo to be opened for editing
   */
  setEdit(todo: Todo): void {
    this.edit.emit(todo);
  }

  /**
   * Emit an event to the parent component, passing the value of the Todo to be deleted
   * @param todo - the Todo to be deleted
   */
  setDelete(todo: Todo): void {
    this.delete.emit(todo);
  }
}
