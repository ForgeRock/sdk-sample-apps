/*
 * forgerock-sample-web-react
 *
 * home.js
 *
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import React, { useContext } from 'react';
import { Link } from 'react-router-dom';

import { AuthContext } from '../context/auth.context';
import { ThemeContext } from '../context/theme.context';
import Alert from '../components/utilities/alert';

/**
 * @function Home - React view for Home
 * @returns {Object} - React component object
 */
export default function Home() {
  /**
   * Collects the global state for detecting user auth for rendering
   * appropriate navigational items.
   * The destructing of the hook's array results in index 0 having the state value,
   * and index 1 having the "setter" method to set new state values.
   */
  const [auth] = useContext(AuthContext);
  const theme = useContext(ThemeContext);

  const ErrorAlert = auth.error ? <Alert message={auth.error} type="error" /> : null;

  const LoginAlert = auth.isAuthenticated ? (
    <Alert
      message={
        <>
          Welcome back, {auth.username}!{' '}
          <Link className="cstm_verified-alert-link" to="/todos">
            Manage your todos here
          </Link>
          .
        </>
      }
      type="success"
    />
  ) : null;

  return (
    <div className={`cstm_container container-fluid ${theme.textClass}`}>
      {ErrorAlert}
      {LoginAlert}
      <h1 className={`cstm_head-text text-center ${theme.textClass}`}>
        Protect with Ping; Develop with React.js
      </h1>

      <p className={`cstm_subhead-text fs-3 mb-4 fw-bold ${theme.textMutedClass}`}>
        Learn how to develop Ping protected, web apps with the{' '}
        <a className={`${theme.textMutedClass}`} href="https://react.dev/">
          React.js
        </a>{' '}
        library and our{' '}
        <a
          className={`${theme.textMutedClass}`}
          href="https://github.com/ForgeRock/forgerock-web-login-framework"
        >
          Login Widget
        </a>
        .
      </p>
      <h2 className={`fs-4 fw-normal pt-3 pb-1 ${theme.textClass}`}>About this project</h2>
      <p>
        The purpose of this sample web app is to demonstrate how the Login Widget is implemented
        within a fully-functional application using a popular framework. The source code for{' '}
        <a href="https://github.com/ForgeRock/sdk-sample-apps/tree/main/javascript/reactjs-todo-login-widget">
          this project can be found on Github
        </a>{' '}
        and run locally for experimentation. For more on our SDKs,{' '}
        <a href="https://docs.pingidentity.com/sdks/latest/index.html">
          you can find our official SDK documentation here.
        </a>
      </p>
    </div>
  );
}
