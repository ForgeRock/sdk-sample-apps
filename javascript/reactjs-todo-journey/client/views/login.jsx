/*
 * ping-sample-web-react-journey
 *
 * login.js
 *
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */
import { useContext } from 'react';
import { Link, useSearchParams } from 'react-router-dom';
import BackHome from '../components/utilities/back-home';
import Card from '../components/layout/card';
import Form from '../components/journey/form';
import { ThemeContext } from '../context/theme.context';

/**
 * @function Login - React view for Login
 * @returns {Object} - React component object
 */
export default function Login() {
  const theme = useContext(ThemeContext);
  const [params] = useSearchParams();
  const journey = params.get('journey');

  return (
    <div className="cstm_container_v-centered container-fluid d-flex align-items-center">
      <div className="w-100">
        <BackHome />
        <Card>
          <Form
            action={{ type: 'login' }}
            bottomMessage={
              <p className={`text-center text-secondary p-3 ${theme.textClass}`}>
                Don&apos;t have an account? <Link to="/register">Sign up here!</Link>
              </p>
            }
            journey={journey}
          />
        </Card>
      </div>
    </div>
  );
}
