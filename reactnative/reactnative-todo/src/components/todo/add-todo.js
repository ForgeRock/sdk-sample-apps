/*
 * Copyright (c) 2024 Ping Identity. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import { Button, Input, HStack } from 'native-base';
import * as React from 'react';

import request from '../../utilities/request';

/**
 * @function AddTodo - Component for handling the add todo functionality
 * @param {Object} props - React props object
 * @param {Function} props.dispatch - Reducer function for managing todo state
 * @returns {Object}
 */
export default function AddTodo({ dispatch }) {
  const [text, onChangeText] = React.useState('');

  const addTodo = async (e) => {
    e.preventDefault();
    const todo = { title: text };
    try {
      const data = await request('POST', 'todos', todo);
      dispatch({
        type: 'add-todo',
        payload: data,
      });
    } catch (err) {
      console.error(err);
    }
    onChangeText('');
  };

  return (
    <HStack flexDirection="row" justifyContent="space-between">
      <Input
        flexGrow="1"
        onChangeText={onChangeText}
        maxWidth="70%"
        placeholder="What needs doing?"
        size="lg"
        value={text}
      />
      <Button ml={3} onPress={addTodo} size="lg">
        Create
      </Button>
    </HStack>
  );
}
