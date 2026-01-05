/*
 * ping-sample-web-react-davinci
 *
 * fetch.js
 *
 * Copyright (c) 2025 Ping Identity Corporation. All rights reserved.
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import { useEffect } from 'react';

import apiRequest from '../../utilities/request';

/**
 * @function useTodoFetch - A custom React hook for fetching todos from API
 * @param {Function} dispatch - The function to pass in an action with data to result in new state
 * @param {Function} setFetched - A function for setting the state of hasFetched
 * @param {Function} setApiError - A function for setting API error messages
 * @returns {undefined} - this doesn't directly return anything, but calls dispatch to set data
 */
export default function useTodoFetch(dispatch, setFetched, setApiError) {
  /**
   * Since we are making an API call, which is a side-effect,
   * we will wrap this in a useEffect, which will re-render the
   * view once the API request returns.
   */
  useEffect(() => {
    async function getTodos() {
      // Request the todos from our resource API
      const fetchedTodos = await apiRequest('todos', 'GET');

      if (fetchedTodos.error) {
        setApiError(
          'The Todo API server is not running. Please start it with npm run start:todo-api from the javascript directory.',
        );
        setFetched(true);
        return;
      }
      setFetched(true);
      dispatch({ type: 'init-todos', payload: { todos: fetchedTodos } });
    }

    getTodos();

    // There are no dependencies needed as all methods/functions are "stable"
  }, []);
}
