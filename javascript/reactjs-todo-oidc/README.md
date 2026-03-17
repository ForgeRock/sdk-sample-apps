# React JS Todo OIDC Sample App

## Disclaimers

This sample code is provided "as is" and is not a supported product of Ping. Its purpose is solely to demonstrate how the Ping JavaScript SDK can be implemented within a React application using centralized OIDC login. This is not a demonstration of React itself or instructional for _how_ to build a React app. There are many aspects to routing, state management, tooling, and other areas of building a React app that are outside the scope of this project. For information about creating a React app, [visit React's official documentation](https://reactjs.org/docs/create-a-new-react-app.html).

## Requirements

1. An instance of Ping's Access Manager (AM), either within Ping Advanced Identity Cloud, your own private installation, or locally installed on your computer
2. Node >= 18 (recommended: install via the [official package installer](https://nodejs.org/en/))
3. Knowledge of using the Terminal/Command Line
4. Ability to generate security certs (recommended: mkcert; [installation instructions here](https://github.com/FiloSottile/mkcert#installation))
5. This project cloned to your computer

## Setup

Once you have the 5 requirements above met, we can build the project.

### Set Up Your AM Instance

#### Configure CORS

1. Allowed origins: `https://localhost:8443`
2. Allowed methods: `GET` `POST`
3. Allowed headers: `Content-Type` `X-Requested-With` `X-Requested-Platform` `Accept-API-Version` `Authorization`
4. Allow credentials: enable

#### Create Your OAuth Clients

1. Create a public (SPA) OAuth client for the web app: no secret, scopes including `openid profile email`, implicit consent enabled, and no "token authentication endpoint method".
   - Redirect URI: `https://localhost:8443/callback.html`
   - Post logout redirect URI: `https://localhost:8443/`
2. Create a confidential (Node.js) OAuth client for the API server: with a secret, default scope of `am-introspect-all-tokens`, and `client_secret_basic` as the "token authentication endpoint method".

#### Configure OIDC Discovery

Set your `.env` values to point to your realm-specific OpenID configuration endpoint (`WELLKNOWN_URL`) and keep `SCOPE` configured with at least `openid`.

### Configure Your `.env` File

Change the name of `.env.example` to `.env` and replace the bracketed values (e.g. `<<<helper-text>>>`) with your values.

Example with annotations:

```text
API_URL=http://localhost:9443
DEBUGGER_OFF=true
DEVELOPMENT=true
REALM_PATH=<<<Realm path, for example alpha>>>
WEB_OAUTH_CLIENT=<<<Your Web OAuth client name/ID>>>
SCOPE="openid profile email"
WELLKNOWN_URL=<<<Realm well-known URL, for example https://example.com/am/oauth2/alpha/.well-known/openid-configuration>>>
INIT_PROTECT=bootstrap
PINGONE_ENV_ID=<<<Optional: required only when using PingOne Protect callback collection>>>
```

### Installing Dependencies and Run Build

Run commands from the JavaScript workspace root:

```sh
cd javascript
npm install
```

### Run the Servers

Run the command below to start both the client app and `todo-api`:

```sh
cd javascript
npm run start:reactjs-todo-oidc
```

Now, you should be able to visit `https://localhost:8443`, which is your web app or client (the Relying Party in OAuth terms). This client will make requests to your AM instance (the Authorization Server in OAuth terms), and `http://localhost:9443` as the REST API for your todos (the Resource Server).

### Accept Cert Exceptions

You will likely have to accept security certificate exceptions for both your React app and the Node.js server. To accept the cert from the Node.js server, you can visit `http://localhost:9443/healthcheck` in your browser. Once you receive `OK`, your Node.js server is running on the correct domain and port, and the cert is accepted.

## Learn About Integration Touchpoints

This project has debugging statements that can be activated to pause execution at each SDK integration point. A comment above each `debugger` statement explains the purpose of the integration point.

If you'd like to use this feature as a learning tool, open the developer tools of your browser and rerun the app locally. It will automatically pause at these points of integration.

For local development, if you want to turn these debuggers off, set the environment variable `DEBUGGER_OFF=true`.

## Modifying This Project

### React Client

To modify the client portion of this project, you'll need to be familiar with the following React patterns:

1. [Functional components and composition](https://reactjs.org/docs/components-and-props.html)
2. [Hooks (including custom hooks)](https://reactjs.org/docs/hooks-intro.html)
3. [Context API](https://reactjs.org/docs/hooks-reference.html#usecontext)
4. [React Router](https://reactrouter.com/)

You'll also want a [basic understanding of Webpack](https://webpack.js.org/concepts/) and the following:

1. [Babel transformation for React](https://webpack.js.org/loaders/babel-loader/#root)
2. [Plugins for Sass-to-CSS processing](https://webpack.js.org/loaders/sass-loader/#root)

#### Styling and CSS

We heavily leveraged [Twitter Bootstrap](https://getbootstrap.com/) and [it's utility classes](https://getbootstrap.com/docs/5.0/utilities/api/), but you will see classes with the prefix `cstm_`. These are custom classes, hence the `cstm` shorthand, and they are explicitly used to denote an additional style application on top of Bootstrap's styling.

### REST API Server

To modify the API server, you'll need a [basic understanding of Node](https://nodejs.org/en/about/) as well as the following things:

1. [Express](https://expressjs.com/)
2. [PouchDB](https://pouchdb.com/)
3. [Superagent](https://www.npmjs.com/package/superagent)

## TypeScript?

The Ping JavaScript SDK is developed with TypeScript, so type definitions are available. This sample application does not utilize TypeScript, but if you'd like to see a version of this written in TypeScript, let us know.
