# Angular Todo Sample App

## Disclaimers

This sample code is provided "as is" and is not a supported product of ForgeRock. It's purpose is solely to demonstrate how the ForgeRock JavaScript SDK can be implemented within an Angular application. Also, this is not a demonstration of Angular itself or instructional for _how_ to build an Angular app. There are many aspects to routing, state management, tooling and other aspects to building an Angular app that are outside of the scope of this project. For information about creating an Angular app, [visit Angular's official documentation](https://angular.io/cli).

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
3. Signoff URLs: https://localhost:8443/login
4. Redirect URIs: https://localhost:8443/login
5. Response Type: Code
6. Grant Type: Authorization Code

#### Resources (scopes)

1. email phone profile

#### Policies

1. DaVinci Policies: Select your DaVinci application

### Configure Your `.env` File

Change the name of `.env.example` to `.env` and replace the bracketed values (e.g. `<<<helper-text>>>`) with your values.

Example with annotations:

### Configure Your `.env` Files

First, in the main directory of the SDK repo, create a file named `.env` by copying the file `.env.example` and adding your relevant values. This new file provides all the important configuration settings to your applications.

Here’s a hypothetical example; your values may vary:

```text
API_URL=http://localhost:9443
DEBUGGER_OFF=true
DEVELOPMENT=false
PORT=8443
CLIENT_ID=cfce748b-b7f4-4b60-972d-189d5ce9adaa
REDIRECT_URI=http://localhost:8443/login
SCOPE="openid profile email phone"
BASE_URL=https://auth.pingone.com/5057aeca-1869-4bf1-8cf4-99b7456086a5/
```

### Installing Dependencies

**Run from root of repo**: since this sample app uses npm's workspaces, we recommend running the npm commands from the root of the repo.

```sh
# Install all dependencies
npm install
```

### Run the App and API

Run the below commands to start the processes needed for building the application and running the servers for both client and API server:

```sh
# In one terminal window, run the following watch command
npm run start:angular-todo
```

Now, you should be able to visit `https://localhost:8443`, which is your web app or client (the Relying Party in OAuth terms). This client will make requests to your AM instance, (the Authorization Server in OAuth terms), which will be running on whatever domain you set, and `http://localhost:9443` as the REST API for your todos (the Resource Server).

### Accept Cert Exceptions

You will likely have to accept the security certificate exceptions for both your Angular app and the Node.js server. To accept the cert form the Node.js server, you can visit `http://localhost:9443/healthcheck` in your browser. Once you receive "OK", your Node.js server is running on the correct domain and port, and the cert is accepted.

## Learn About Integration Touchpoints

This project has a debugging statements that can be activated which causes the app to pause execution at each SDK integration point. It will have a comment above the `debugger` statement explaining the purpose of the integration.

For local development, if you want to turn these debuggers off, you can set the environment variable of `DEBUGGER_OFF` to true.

## Modifying This Project

### Angular Client

To modify the client portion of this project, you'll need to be familiar with the following Angular patterns:

1. [Components](https://angular.io/guide/architecture-components)
2. [Modules](https://angular.io/guide/architecture-modules)
3. [Services and Dependency Injection](https://angular.io/guide/architecture-services)
4. [Event Binding](https://angular.io/guide/event-binding-concepts)

You'll also want a [basic understanding of Webpack](https://webpack.js.org/concepts/) and the following:

1. [Plugins for Sass-to-CSS processing](https://webpack.js.org/loaders/sass-loader/#root)
2. [Angular CLI (used to create this app)](https://angular.io/cli)

#### Styling and CSS

We heavily leveraged [Twitter Bootstrap](https://getbootstrap.com/) and [it's utility classes](https://getbootstrap.com/docs/5.0/utilities/api/), but you will see classes with the prefix `cstm_`. These are custom classes, hence the `cstm` shorthand, and they are explicitly used to denote an additional style application on top of Bootstrap's styling.

### REST API Server

To modify the API server, you'll need a [basic understanding of Node](https://nodejs.org/en/about/) as well as the following things:

1. [Express](https://expressjs.com/)
2. [PouchDB](https://pouchdb.com/)
3. [Superagent](https://www.npmjs.com/package/superagent)
