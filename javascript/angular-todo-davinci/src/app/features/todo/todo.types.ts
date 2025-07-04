/*
 * ping-sample-web-angular-davinci
 *
 * todo.types.ts
 *
 * Copyright (c) 2025 Ping Identity Corporation. All rights reserved.
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

/**
 * Defines the expected structure of a single Todo item
 */
export interface Todo {
  _rev?: string;
  _id?: string;
  title?: string;
  completed?: boolean;
}
