/*
 * Copyright (c) 2024 Ping Identity. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import { Alert as AlertEl, Box, HStack, Text, VStack } from 'native-base';
import React from 'react';
import Icon from 'react-native-vector-icons/MaterialCommunityIcons';

/**
 * @function Alert - React component used for displaying generic alerts
 * @param {Object} props - React props object
 * @param {string} props.type - Type of alert: success, error ...
 * @param {string} props.message - The message to display
 * @param {string} props.information - Additional information to display
 * @returns {Object} - React component object
 */
export default function Alert({ type, message, information }) {
  let icon;
  let color;
  switch (type) {
    case 'success':
    case 'LoginSuccess':
      icon = <Icon name="check-decagram" size={24} />;
      color = 'success';
      break;
    case 'error':
    case 'LoginFailure':
      icon = <Icon name="alert" size={24} />;
      color = 'error';
      break;
    default:
    // do nothing
  }

  return (
    <AlertEl w="100%" mb={4} status="info" colorScheme={color}>
      <VStack space={2} flexShrink={1} w="100%">
        <HStack
          flexShrink={1}
          space={2}
          alignItems="center"
          justifyContent="space-between"
        >
          <HStack flexShrink={1} space={2} alignItems="center">
            {icon}
            <Text fontSize="md" fontWeight="medium" color="coolGray.800">
              {message}
            </Text>
          </HStack>
        </HStack>
        {information ? (
          <Box
            pl="8"
            _text={{
              color: 'coolGray.600',
            }}
          >
            {information}
          </Box>
        ) : null}
      </VStack>
    </AlertEl>
  );
}
