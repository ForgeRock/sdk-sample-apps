# React JS Todo Sample App with DaVinci

## Disclaimers

This sample code is provided "as is" and is not a supported product of Ping Identity. It's purpose is solely to demonstrate how the Ping OIDC client and DaVinci client can be implemented within a React application. Also, this is not a demonstration of React itself or instructional for _how_ to build a React app. There are many aspects to routing, state management, tooling and other aspects to building a React app that are outside of the scope of this project. For information about creating a React app, [visit React's official documentation](https://reactjs.org/docs/create-a-new-react-app.html).

## Supported DaVinci Collectors

- TextCollector
- PasswordCollector
- SingleSelectCollector
- ReadOnlyCollector
- PhoneNumberCollector
- DeviceRegistrationCollector
- DeviceAuthenticationCollector
- IdpCollector
- SubmitCollector
- FlowCollector
- ProtectCollector

## Requirements

1. A PingOne tenant with SSO and DaVinci services enabled
2. Node >= 14.2.0 (recommended: install via [official package installer](https://nodejs.org/en/))
3. Knowledge of using the Terminal/Command Line
4. This project "cloned" to your computer

## Setup

Once you have the requirements above met, we can build the project.

### Setup Your PingOne application

1. Create a new OIDC Web App

#### Configuration

1. CORS Allowed origins: `https://localhost:8443`
2. Token Auth Method: None
3. Signoff URLs: https://localhost:8443
4. Redirect URIs: https://localhost:8443/callback.html
5. Response Type: Code
6. Grant Type: Authorization Code

#### Resources (scopes)

1. openid profile email phone name revoke

#### Policies

1. DaVinci Policies: Select your DaVinci application

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
```

### Installing Dependencies

**Run from root of `/javascript`**: since this sample app uses npm's workspaces, we recommend running the npm commands from the root of the `/javascript` folder.

```sh
# Install all dependencies
npm install
```

### Run the Servers

Now, run the below commands to start the processes needed for building the application and running the servers for both client and API server:

```sh
# In a terminal window, run the following command from the /javascript folder
npm run start:reactjs-todo-dv
```

Now, you should be able to visit `http://localhost:8443`, which is your web app or client (the Relying Party in OAuth terms). This client will make requests to your PingOne instance, (the Authorization Server in OAuth terms), which will be running on whatever domain you set, and `http://localhost:9443` as the REST API for your todos (the Resource Server).

## Learn About Integration Touchpoints

This project has a debugging statements that can be activated which causes the app to pause execution at each SDK integration point. It will have a comment above the `debugger` statement explaining the purpose of the integration.

If you'd like to use this feature as a learning tool, open the live app and then open the developer tools of your browser. Rerun the app with the developer tools open, and it will automatically pause at these points of integration.

For local development, if you want to turn these debuggers off, you can set the environment variable of `DEBUGGER_OFF` to true.

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

The ForgeRock Javascript SDK is developed with TypeScript, so type definitions are available. This sample application does not utilize TypeScript, but if you'd like to see a version of this written in TypeScript, let us know.
