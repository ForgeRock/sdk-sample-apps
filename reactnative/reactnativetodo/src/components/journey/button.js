/*
 * forgerock-react-native-sample
 *
 * button.js
 *
 * Copyright (c) 2021 ForgeRock. All rights reserved.
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import { Button, Spinner, Text } from 'native-base';
import React from 'react';

/**
 * @function FormButton - Button for handling submit of journey form
 * @param {Object} props - React props object
 * @param {string} props.buttonText - Text to display in button
 * @param {boolean} props.isProcessingForm - state of form submission: processing or not
 * @param {Function} props.setProcessingForm - Function for setting the state of form submission
 * @param {Function} props.setSubmissionStep - Function for setting the state of the step
 * @param {Function} props.renderStep - The journey's "step" object with callbacks
 * @returns {Object} - React object
 */
export default function FormButton({
  buttonText,
  isProcessingForm,
  setProcessingForm,
  setSubmissionStep,
  renderStep,
}) {
  return (
    <Button
      onPress={() => {
        setProcessingForm(true);
        setSubmissionStep(renderStep);
      }}
    >
      {
        /**
         * Render a small spinner during submission calls
         */
        isProcessingForm ? (
          <Spinner color="white" />
        ) : (
          <Text color="white" fontSize="md" fontWeight="medium">
            {buttonText}
          </Text>
        )
      }
    </Button>
  );
}
