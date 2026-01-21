/*
 * ping-sample-web-react-journey
 *
 * create.js
 *
 * Copyright (c) 2026 Ping Identity Ping Identity Corporation. All rights reserved.
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import React, { useContext, useRef, useState } from 'react';

import apiRequest from '../../utilities/request';
import { ThemeContext } from '../../context/theme.context';

/**
 * @function CreateTodo - React component for displaying the input and button pair for todo creation
 * @param {Object} props - React props object
 * @param {Function} props.addTodo - The function that adds the todo to the local collection
 * @returns {Object} - React component object
 */
export default function CreateTodo({ addTodo }) {
  const theme = useContext(ThemeContext);

  const [creatingTodo, setCreatingTodo] = useState(false);
  const textInput = useRef(null);

  async function createTodo(e) {
    e.preventDefault();

    setCreatingTodo(true);

    const title = e.target.elements[0].value;
    const newTodo = await apiRequest('todos', 'POST', { title });

    addTodo(newTodo);
    setCreatingTodo(false);
    textInput.current.value = '';
  }

  return (
    <form
      className={`p-3 d-flex ${theme.textClass}`}
      action="http://localhost:9443/todos"
      method="POST"
      onSubmit={createTodo}
    >
      <div className="cstm_todos-input cstm_form-floating form-floating flex-grow-1">
        <input
          id="newTodo"
          type="text"
          className={`cstm_form-control form-control bg-transparent ${theme.textClass} ${theme.borderClass}`}
          placeholder="What needs doing?"
          required="required"
          ref={textInput}
        />
        <label htmlFor="newTodo">What needs doing?</label>
      </div>
      <button className="btn btn-primary ms-2" type="submit">
        {creatingTodo ? (
          <span
            className="spinner-border spinner-border-sm"
            role="status"
            aria-hidden="true"
          ></span>
        ) : (
          'Create'
        )}
      </button>
    </form>
  );
}
