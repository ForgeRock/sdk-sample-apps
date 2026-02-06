/*
 * App.tsx
 *
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */
import reactLogo from './assets/react.svg';
import pingLogo from './assets/ping-logo-square-color.svg';
import './App.css';
import Form from './components/Form';

function App() {
  return (
    <>
      <div>
        <a href="https://vite.dev" target="_blank">
          <img src={pingLogo} className="logo" alt="Ping logo" />
        </a>
        <a href="https://react.dev" target="_blank">
          <img src={reactLogo} className="logo react" alt="React logo" />
        </a>
      </div>

      <h1>
        Protect with Ping
        <br />
        Develop with React.js
      </h1>

      <p>
        Learn how to develop a Ping-protected centralized login web app with the{' '}
        <a href="https://reactjs.org/">React.js</a> library and our{' '}
        <a href="https://github.com/ForgeRock/ping-javascript-sdk/">JavaScript SDK</a>.
      </p>

      <Form/>
      
      <div className="read-the-docs">
        <h2>About this project</h2>
        <p>
          The purpose of this sample web app is to demonstrate how the Ping JavaScript SDK is
          implemented within a fully-functional application using a popular framework. The source
          code for{' '}
          <a href="https://github.com/ForgeRock/sdk-sample-apps/tree/main/javascript/react-oidc">
            this project can be found on Github
          </a>{' '}
          and run locally for experimentation. For more on our SDKs,{' '}
          <a href="https://docs.pingidentity.com/sdks/latest/index.html">
            you can find our official SDK documentation here.
          </a>
        </p>
      </div>
    </>
  );
}

export default App;
