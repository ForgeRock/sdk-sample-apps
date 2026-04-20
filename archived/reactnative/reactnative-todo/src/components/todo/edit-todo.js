/*
 * Copyright (c) 2024 - 2025 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import { Button, Input, Modal } from 'native-base';
import React, { useState } from 'react';

/**
 * @function EditTodo - Component for editing todo via modal
 * @param {Object} props - React props object
 * @param {Function} props.editTodo - Function for handling label change
 * @param {Function} props.setShowModal - Function for setting the modal state
 * @param {boolean} props.showModal - Modal state
 * @param {Object} props.todo - Todo object
 * @returns {Object} - React object
 */
export default function EditModal({ editTodo, setShowModal, showModal, todo }) {
  const [text, onChange] = useState(todo.title);

  return (
    <React.Fragment>
      <Modal
        animationPreset="slide"
        isOpen={showModal}
        onClose={() => setShowModal(false)}
      >
        <Modal.Content
          backgroundColor="white"
          height="30%"
          // eslint-disable-next-line react-native/no-inline-styles
          style={{ marginBottom: 0, marginTop: 'auto' }}
          width="100%"
        >
          <Modal.CloseButton />
          <Modal.Header p={6}>Edit Todo</Modal.Header>
          <Modal.Body backgroundColor="white" p={6}>
            <Input size="lg" onChangeText={onChange} defaultValue={text} />
          </Modal.Body>
          <Modal.Footer backgroundColor="white" p={6} mb={4}>
            <Button.Group space={2}>
              <Button
                colorScheme="blueGray"
                onPress={() => {
                  setShowModal(false);
                }}
                size="lg"
                variant="ghost"
              >
                Cancel
              </Button>
              <Button
                onPress={async () => {
                  setShowModal(false);
                  await editTodo({ ...todo, title: text });
                  onChange('');
                }}
                size="lg"
              >
                Save
              </Button>
            </Button.Group>
          </Modal.Footer>
        </Modal.Content>
      </Modal>
    </React.Fragment>
  );
}
