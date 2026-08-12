# React JS Todo OIDC Sample App

## Disclaimers

This sample code is provided "as is" and is not a supported product of Ping. Its purpose is solely to demonstrate how the Ping JavaScript SDK can be implemented within a React application using centralized OIDC login. This is not a demonstration of React itself or instructional for _how_ to build a React app. There are many aspects to routing, state management, tooling, and other areas of building a React app that are outside the scope of this project. For information about creating a React app, [visit React's official documentation](https://reactjs.org/docs/create-a-new-react-app.html).

## Requirements

1. A PingOne tenant or instance of Ping's Access Manager (PingAM), either within Ping Advanced Identity Cloud, your own private installation, or locally installed on your computer
2. Node >= 18 (recommended: install via the [official package installer](https://nodejs.org/en/))
3. Knowledge of using the Terminal/Command Line
4. This project cloned to your computer

## Setup

Once you have the requirements above met, we can build the project.

### Set Up A Public Client
Choose to set up either a PingOne or PingAM/PingAIC instance

#### Set Up Your AM Instance

##### Configure CORS

1. Allowed origins: `https://localhost:8443`
2. Allowed methods: `GET` `POST`
3. Allowed headers: `Content-Type` `X-Requested-With` `X-Requested-Platform` `Accept-API-Version` `Authorization`
4. Allow credentials: enable

##### Create Your OAuth Clients

1. Create a public (SPA) OAuth client for the web app: no secret, scopes including `openid profile email`, implicit consent enabled, and no "token authentication endpoint method".
   - Redirect URI: `https://localhost:8443/callback.html`
   - Post logout redirect URI: `https://localhost:8443/`
2. Create a confidential (Node.js) OAuth client for the API server: with a secret, default scope of `am-introspect-all-tokens`, and `client_secret_basic` as the "token authentication endpoint method".

#### Setup Your PingOne application

1. Create a new OIDC Web App

##### Configuration

1. CORS Allowed origins: `https://localhost:8443`
2. Token Auth Method: None
3. Signoff URLs: https://localhost:8443/logout
4. Redirect URIs: https://localhost:8443/callback.html
5. Response Type: Code
6. Grant Type: Authorization Code

##### Resources (scopes)

1. openid profile email phone name revoke

### Configure SDK Credentials

> **Note:** Using `config.json` is optional and backward-compatible. If you prefer, you can continue supplying SDK credentials via the `SDK_CONFIG` environment variable (a JSON string). The app falls back to `config.json` only when `SDK_CONFIG` is not set.

Copy `config.example.json` to `config.json` at the app root and fill in your values:

```sh
cp config.example.json config.json
```

`config.json` (gitignored):

```json
{
  "oidc": {
    "clientId": "<your-oauth-client-id>",
    "discoveryEndpoint": "https://<your-domain>/.well-known/openid-configuration",
    "scopes": ["openid", "profile", "email"],
    "redirectUri": "https://localhost:8443/callback.html"
  }
}
```

### Configure Your `.env` File

Change the name of `.env.example` to `.env` and set the remaining runtime values:

```text
API_URL=http://localhost:9443
DEBUGGER_OFF=true
DEVELOPMENT=true
PORT=8443
#SERVER - 'PINGAM' or 'PINGONE'
SERVER=PINGAM
```

### Installing Dependencies and Run Build

**Run from repo root**: since this sample app uses npm's workspaces, we recommend running the npm commands from the root of the `sdk-sample-apps` folder.

```sh
# Install all dependencies
npm install
```

### Run the Servers

Run the command below to start both the client app and `todo-api`:

```sh
# In a terminal window, run the following command from the root of the sdk-sample-apps folder
npm run start:reactjs-todo-oidc
```

Now, you should be able to visit `https://localhost:8443`, which is your web app or client (the Relying Party in OAuth terms). This client will make requests to PingAM or PingOne (the Authorization Server in OAuth terms), and `http://localhost:9443` as the REST API for your todos (the Resource Server).

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
