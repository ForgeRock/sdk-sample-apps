/*
 * forgerock-react-native-sample
 *
 * register.js
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

export default function Register() {
  const [primary] = useToken('colors', ['primary.600']);
  const linkStyle = {
    color: primary,
    textDecorationLine: 'underline',
  };

  return (
    <Form action={{ type: 'register' }} mb={4}>
      <Center>
        <Icon name="account-plus" size={72} color="#c0c9d5" />
        <Heading size="lg" mb={2}>
          Sign Up
        </Heading>
        <Text fontSize="sm" mb={4}>
          Already have an account?{' '}
          <Link to={{ screen: 'Sign In' }} style={linkStyle}>
            Sign in here!
          </Link>
        </Text>
      </Center>
    </Form>
  );
}
