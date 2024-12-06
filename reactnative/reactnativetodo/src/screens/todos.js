/*
 * Copyright (c) 2024 Ping Identity. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */



import React, { useContext, useEffect, useReducer } from 'react';
import { VStack, Box, Heading, ScrollView, Text } from 'native-base';

import AddTodo from '../components/todo/add-todo';
import { AppContext } from '../global-state';
import Loading from '../components/utilities/loading';
import reducer from '../components/todo/reducer';
import request from '../utilities/request';
import Todo from '../components/todo/todo';
import useToggle from '../components/todo/toggle';

export default function Todos() {
  const [_, { setAuthentication }] = useContext(AppContext);
  const [fetching, setFetch] = useToggle(false);
  const [todos = [], dispatch] = useReducer(reducer, []);

  /**
   * In order to call for all of the user's todos, we will
   * wrap it in a `useEffect` to handle it asynchronously.
   */
  useEffect(() => {
    async function getTodos() {
      setFetch(true);
      try {
        const response = await request('GET', 'todos');
        setFetch(false);
        dispatch({ type: 'init-todos', payload: response });
      } catch (err) {
        console.error('Fetch failure');
        setAuthentication(false);
      }
    }
    getTodos();
    // We explicitly want to call this only on initial mount
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  const editTodo = async ({ _id, title }) => {
    dispatch({ type: 'edit-todo', payload: { _id, title } });
    try {
      await request('POST', `todos/${_id}`, { title });
    } catch (err) {
      console.error('Fetch failure');
      setAuthentication(false);
    }
  };

  const handleDelete = async (todo) => {
    dispatch({
      type: 'delete-todo',
      payload: { completed: !todo.completed, _id: todo._id },
    });
    try {
      await request('DELETE', `todos/${todo._id}`, todo);
    } catch (err) {
      console.error('Fetch failure');
      setAuthentication(false);
    }
  };

  const handleStatusChange = async ({ _id, completed }) => {
    dispatch({
      type: 'complete-todo',
      payload: { _id, completed: !completed },
    });
    try {
      await request('POST', `todos/${_id}`, { completed: !completed });
    } catch (err) {
      console.error('Fetch failure');
      setAuthentication(false);
    }
  };

  return fetching ? (
    <Loading message={'Loading User Data'} />
  ) : (
    <ScrollView>
      <Box safeArea flex={1} p={2} w="90%" mx="auto">
        <Heading size="lg">Your Todos</Heading>
        <Text fontSize="md" mb={4} color="trueGray.600" fontWeight="medium">
          Create and manage your todos
        </Text>
        <AddTodo todos={todos} dispatch={dispatch} />
        <VStack>
          {todos.map((todo) => (
            <Todo
              todo={todo}
              key={todo?._id}
              editTodo={editTodo}
              handleDelete={handleDelete}
              handleStatusChange={handleStatusChange}
            />
          ))}
        </VStack>
      </Box>
    </ScrollView>
  );
}
