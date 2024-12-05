/*
 * forgerock-react-native-sample
 *
 * form.js
 *
 * Copyright (c) 2021 ForgeRock. All rights reserved.
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */
import {
  Box,
  Button,
  FormControl,
  ScrollView,
  Spinner,
  Text,
} from 'native-base';
import React, { useContext, useEffect } from 'react';
import Icon from 'react-native-vector-icons/MaterialCommunityIcons';

import Alert from '../utilities/alert';
// import FormButton from './button';
import { AppContext } from '../../global-state';
import useJourneyHandler from './journey-handler';
import Loading from '../utilities/loading';
import { mapCallbacksToComponents } from './utilities';

export default function Form({ action, bottomMessage, children }) {
  const [_, methods] = useContext(AppContext);

  /**
   * Call custom hook to handle the state and error management as well
   * as request orchestration for the iterative process between a client
   * and the ForgeRock server.
   */
  const {
    formFailureMessage,
    renderStep,
    isProcessingForm,
    setSubmissionStep,
    setProcessingForm,
    user,
  } = useJourneyHandler(action);

  useEffect(() => {
    /**
     * First, let's see if we get a user back from useJourneyHandler.
     * If we do, let's set the user data and redirect back to home.
     */
    if (user) {
      /**
       * Set user state/info on "global state"
       */
      methods.setName(user.name);
      methods.setEmail(user.email);

      /**
       * Setting authentication to true results in a re-rendering of
       * the navigation bar and of the correct screen.
       */
      methods.setAuthentication(true);
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [user]);

  /**
   * Render conditions for presenting appropriate views to user.
   * First, we need to handle no "step" to render, which means we are
   * waiting for the initial response from AM for authentication.
   *
   * Once we have a step, we then need to ensure we don't already have a
   * success or failure. If we have a step but don't have a success or
   * failure, we will likely have callbacks that we will need to present'
   * to the user in their render component form.
   */
  if (!renderStep) {
    /**
     * Since there is no step information we need to call AM to retrieve the
     * instructions for rendering the login form.
     */
    return <Loading message={'Checking your session'} />;
  } else if (renderStep.type === 'LoginSuccess') {
    /**
     * Since we have successfully authenticated, show a success message to
     * user while we complete the process and redirect to home page.
     */
    return <Loading message="Success! Redirecting ..." />;
  } else if (renderStep.type === 'Step') {
    /**
     * The step to render has callbacks, so we need to collect additional
     * data from user. Map callbacks to form inputs.
     */
    return (
      <ScrollView>
        <Box safeArea flex={1} p={2} w="90%" mx="auto">
          {children}
          <FormControl isInvalid={formFailureMessage}>
            <FormControl.ErrorMessage
              leftIcon={<Icon name="alert" size={18} />}
            >
              {formFailureMessage}
            </FormControl.ErrorMessage>
            {
              /**
               * Map over the callbacks in renderStep and render the appropriate
               * component for each one using the mapper.js utility.
               */
              renderStep.callbacks.map(mapCallbacksToComponents)
            }
            <Button
              onPress={() => {
                // Indicate form processing
                setProcessingForm(true);
                // set currently rendered step as step to be submitted
                setSubmissionStep(renderStep);
              }}
              size="lg"
            >
              {
                /**
                 * Render a small spinner during submission calls
                 */
                isProcessingForm ? (
                  <Spinner color="white" />
                ) : (
                  <Text color="white" fontWeight="medium">
                    {action.type === 'login' ? 'Login' : 'Register'}
                  </Text>
                )
              }
            </Button>
            {bottomMessage}
          </FormControl>
        </Box>
      </ScrollView>
    );
  } else {
    return <Alert message={renderStep.message} />;
  }
}
