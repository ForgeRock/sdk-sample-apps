# NodeJS Todo-API

## Disclaimers

This sample code is provided "as is" and is not a supported product of Ping. It's purpose is solely to demonstrate how the Ping JavaScript SDK can be implemented within a React application. Also, this is not a demonstration of React itself or instructional for _how_ to build a React app. There are many aspects to routing, state management, tooling and other aspects to building a React app that are outside of the scope of this project. For information about creating a React app, [visit React's official documentation](https://reactjs.org/docs/create-a-new-react-app.html).

## Requirements

1. An instance of Ping's Access Manager (AM), either within a Ping's Advanced Identity Cloud tenant, your own private installation or locally installed on your computer
2. Node >= 14.2.0 (recommended: install via [official package installer](https://nodejs.org/en/))
3. Knowledge of using the Terminal/Command Line
4. Ability to generate security certs (recommended: mkcert ([installation instructions here](https://github.com/FiloSottile/mkcert#installation))
5. This project "cloned" to your computer

## Setup

Once you have the 5 requirements above met, we can build the project.

### Setup Your AM Instance

#### Configure CORS

1. Allowed origins: `https://localhost:8443`
2. Allowed methods: `GET` `POST`
3. Allowed headers: `Content-Type` `X-Requested-With` X-Requested-Platform` `Accept-API-Version` `Authorization`
4. Allow credentials: enable

#### Create Your OAuth Clients

1. Create a public (SPA) OAuth client for the web app: no secret, scopes of `openid profile email`, implicit consent enabled, and no "token authentication endpoint method".
2. Create a confidential (Node.js) OAuth client for the API server: with a secret, default scope of `am-introspect-all-tokens`, and `client_secret_basic` as the "token authentication endpoint method".

### Configure Your `.env` File

Change the name of `.env.example` to `.env` and replace the bracketed values (e.g. `<<<helper-text>>>`) with your values.

Example with annotations:

```text
AM_URL= "[Your PingAM or AIC tenant URL]"
DEVELOPMENT="true"
PORT="[The port you want the API to run (default 9443)]"
REALM_PATH="[Your realm path]"
REST_OAUTH_CLIENT="[Confidential Client ID]"
REST_OAUTH_SECRET="[Confidential Client Secret]"
```

### Installing Dependencies and Run Build

**Run from root of repo**: since this sample app uses npm's workspaces, we recommend running the npm commands from the root of the repo.

```sh
# Install all dependencies (no need to pass the -w option)
npm install
```

### Run the Servers

Now, run the below commands to start the processes needed for building the application and running the servers for both client and API server:

```sh
# In one terminal window, run the following watch command from the root of the repository
npm start -w todo-api
```

Now, calling `http://localhost:9443` as the REST API for your todos (the Resource Server), should running and can be used from the Sample Applications.

### Accept Cert Exceptions

You will likely have to accept the security certificate exceptions for both your React app and the Node.js server. To accept the cert form the Node.js server, you can visit `http://localhost:9443/healthcheck` in your browser. Once you receive "OK", your Node.js server is running on the correct domain and port, and the cert is accepted.

## Learn About Integration Touchpoints

This project has a debugging statements that can be activated which causes the app to pause execution at each SDK integration point. It will have a comment above the `debugger` statement explaining the purpose of the integration.

For local development, if you want to turn these debuggers off, you can set the environment variable of `DEBUGGER_OFF` to true.

### REST API Server

To modify the API server, you'll need a [basic understanding of Node](https://nodejs.org/en/about/) as well as the following things:

1. [Express](https://expressjs.com/)
2. [PouchDB](https://pouchdb.com/)
3. [Superagent](https://www.npmjs.com/package/superagent)

## TypeScript?

The Ping JavaScript SDK is developed with TypeScript, so type definitions are available. This sample application does not utilize TypeScript, but if you'd like to see a version of this written in TypeScript, let us know.