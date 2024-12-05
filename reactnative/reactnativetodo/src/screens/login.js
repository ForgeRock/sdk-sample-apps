/*
 * forgerock-react-native-sample
 *
 * login.js
 *
 * Copyright (c) 2021 ForgeRock. All rights reserved.
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import { Link } from '@react-navigation/native';
import { Center, Heading, Text, useToken } from 'native-base';
import React from 'react';
import Icon from 'react-native-vector-icons/MaterialCommunityIcons';

import Form from '../components/journey/form';

export default function Login() {
  const [primary] = useToken('colors', ['primary.600']);
  const linkStyle = {
    color: primary,
    textDecorationLine: 'underline',
  };

  return (
    <Form
      action={{ type: 'login' }}
      bottomMessage={
        <Center>
          <Text mt={2}>
            {"Don't have an account?"}{' '}
            <Link to={{ screen: 'Sign Up' }} style={linkStyle}>
              Register
            </Link>
          </Text>
        </Center>
      }
      mb={4}
    >
      <Center>
        <Icon name="key" size={72} color="#c0c9d5" />
        <Heading size="lg" mb={4}>
          Sign In
        </Heading>
      </Center>
    </Form>
  );
}
