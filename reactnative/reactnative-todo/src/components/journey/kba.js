/*
 * Copyright (c) 2024 - 2025 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */


import { FormControl, Input, Select } from 'native-base';
import React, { useState } from 'react';

/*
 * Please ensure you have created an .env.js from the
 * .env.example.js template!
 */
import { DEBUGGER_OFF } from '../../../.env';
import { TextInput } from 'react-native';

/**
 * @function KBA - React component used for handling "knowledge based answers"
 * @param {Object} props - React props object passed from parent
 * @param {Object} props.callback - The callback object from AM
 * @returns {Object} - React component object
 */
export default function KBA({ callback }) {
  const [selectedQuestion, setAns] = useState('');

  /********************************************************************
   * JAVASCRIPT SDK INTEGRATION POINT
   * Summary: Utilize Callback methods
   * ------------------------------------------------------------------
   *  Details: Because we wrap our responses in FRStep using the Javascript SDK
   *  we have access to helper methods to set, and retrieve information from our response.
   *  Referencing these helper methods allows us to avoid managing the state
   *  in our own application and leverage the SDK to do so
   *  *************************************************************** */
  if (!DEBUGGER_OFF) debugger;
  const updateQuestion = (question) => {
    setAns(question);
    callback.setQuestion(question);
  };
  const label = callback.getPrompt();
  const isRequired = callback.isRequired ? callback.isRequired() : false;

  return (
    <FormControl isRequired={isRequired}>
      <FormControl.Label mb={0}>{label}</FormControl.Label>
      <Select
        accessibilityLabel={label}
        onValueChange={updateQuestion}
        placeholder={label}
        selectedValue={selectedQuestion}
      >
        {callback.getPredefinedQuestions().map((question) => (
          <Select.Item label={question} key={question} value={question} />
        ))}
      </Select>
      <TextInput
        onChangeText={(itemValue) => callback.setAnswer(itemValue)}
        size="lg"
      />
    </FormControl>
  );
}
