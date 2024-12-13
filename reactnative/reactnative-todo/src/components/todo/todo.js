/*
 * forgerock-react-native-sample
 *
 * todo.js
 *
 * Copyright (c) 2021 ForgeRock. All rights reserved.
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import { HStack, Menu, Text, Checkbox, Divider } from 'native-base';
import React, { useState } from 'react';
import { Pressable } from 'react-native';
import Icon from 'react-native-vector-icons/MaterialCommunityIcons';

import EditTodo from './edit-todo';

/**
 * @function Todo - Component for rendering todo item
 * @param {Object} props - React props object
 * @param {Function} props.editTodo - Function for handling label change
 * @param {Function} props.handleStatusChange - Function for handling label change
 * @param {Function} props.handleDelete - Function for handling deletion of todo
 * @param {Object} props.todo - Todo object
 * @returns {Object} - React object
 */
export default function Todo({
  editTodo,
  handleStatusChange,
  handleDelete,
  todo,
}) {
  const [showModal, setShowModal] = useState(false);
  let customCheckboxChecked = { position: 'absolute', color: '#166534' };
  let customCheckboxUnchecked = { position: 'absolute', color: '#737373' };
  let nativeBaseCheckbox = { opacity: 0 };

  return (
    <React.Fragment>
      <Divider my={4} />
      <HStack justifyContent="space-between">
        <Checkbox
          accessibilityLabel="todos checkbox"
          isChecked={todo.completed}
          onChange={() => handleStatusChange(todo)}
          value={todo.title}
          size="lg"
          style={nativeBaseCheckbox}
        >
          {
            /**
             * Since we are hiding the NativeBase icon from above, we are going to
             * conditionally render a custom icon from Material Icons.
             */
            todo.completed ? (
              <Icon
                size={32}
                name="checkbox-marked-circle-outline"
                style={customCheckboxChecked}
              />
            ) : (
              <Icon
                size={32}
                name="checkbox-blank-circle-outline"
                style={customCheckboxUnchecked}
              />
            )
          }
          <Text
            color={todo.completed ? 'muted.500' : 'darkText'}
            fontSize="lg"
            fontWeight="medium"
            maxWidth="85%"
            ml={3}
            mt={0.5}
            strikeThrough={todo.completed}
          >
            {todo.title}
          </Text>
        </Checkbox>
        <Menu
          p={2}
          placement="left"
          trigger={(triggerProps) => (
            <Pressable accessibilityLabel="More options menu" {...triggerProps}>
              <Icon size={25} name="dots-horizontal" />
            </Pressable>
          )}
        >
          <Menu.Item onPress={() => setShowModal(true)}>
            <Text fontSize="md">Edit</Text>
          </Menu.Item>
          <Menu.Item onPress={() => handleDelete(todo)}>
            <Text fontSize="md">Delete</Text>
          </Menu.Item>
        </Menu>
      </HStack>
      <EditTodo
        editTodo={editTodo}
        setShowModal={setShowModal}
        showModal={showModal}
        todo={todo}
      />
    </React.Fragment>
  );
}
