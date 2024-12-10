# React JS Todo Sample App

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

#### Create your Authentication Journeys/Trees

1. Login
2. Register

Note: The sample app currently supports the following callbacks only:

- NameCallback
- PasswordCallback

### Installing Dependencies

**Run from root of repo**: since this sample app uses npm's workspaces, we recommend running the npm commands from the root of the repo.

```sh
# Install all dependencies (no need to pass the -w option)
npm install
```

### Accept Cert Exceptions

You will likely have to accept the security certificate exceptions for both your React app and the Node.js server. To accept the cert form the Node.js server, you can visit `http://localhost:9443/healthcheck` in your browser. Once you receive "OK", your Node.js server is running on the correct domain and port, and the cert is accepted.

## Learn About Integration Touchpoints

This project has a debugging statements that can be activated which causes the app to pause execution at each SDK integration point. It will have a comment above the `debugger` statement explaining the purpose of the integration.

For local development, if you want to turn these debuggers off, you can set the environment variable of `DEBUGGER_OFF` to true.

## Build a protected React web app using this Project

### Configure the React client app

Copy the `.env.example` file in the `sdk-sample-apps/reactjs-todo` folder and save it with the name `.env` within this same directory.

Add your relevant values to this new file as it will provide all the important configuration settings to your applications.

Here’s an example; your values may vary:
```sh
AM_URL=https://openam-forgerock-sdks.forgeblocks.com/am
API_URL=http://localhost:9443
DEBUGGER_OFF=true
DEVELOPMENT=true
JOURNEY_LOGIN=sdkUsernamePasswordJourney
JOURNEY_REGISTER=Registration
REALM_PATH=alpha
WEB_OAUTH_CLIENT=sdkPublicClient
PORT=8443
REST_OAUTH_CLIENT=sdkConfidentialClient
REST_OAUTH_SECRET=ch4ng3it!
```

### Configure the API server app
Copy the `.env.example` file in the `sdk-sample-apps/todo-api` folder and save it with the name `.env` within this same directory.

Add your relevant values to this new file as it will provide all the important configuration settings to your applications.

Here’s an example; your values may vary:
```sh
AM_URL=https://openam-forgerock-sdks.forgeblocks.com/am
DEVELOPMENT=true
PORT=9443
REALM_PATH=alpha
REST_OAUTH_CLIENT=sdkConfidentialClient
REST_OAUTH_SECRET=ch4ng3it!
```

### Build and run the projects

```sh
npm-run-all --parallel todo-api reactjs-todo
```
or using npm Workspaces
```sh
npm run start:reactjs-todo
```

### Implementing the Ping SDK
#### Step 1. Configure the SDK to your server
Now that we have our environment and servers setup, let’s jump into the application! Within your IDE of choice, navigate to the reactjs-todo/client directory. This directory is where you will spend the rest of your time.

First, open up the index.js file, import the Config object from the Ping SDK for JavaScript and call the `Config.setAsync` method on this object:

```sh
+ import { Config } from '@forgerock/javascript-sdk';
  import React from 'react';
  import { createRoot } from 'react-dom/client';

@@ collapsed @@

+ Config.setAsync();

  /**
  * Initialize the React application
  * This is an IIFE (Immediately Invoked Function Expression),
  * so it calls itself.
  */
  (async function initAndHydrate() {

@@ collapsed @@
```
The configuration object you will use in this instance will pull most of its values out of the `.env` variables previously setup, which are mapped to constants within our `constants.js` file:
```sh
@@ collapsed @@

  Config.setAsync(
+   {
+     clientId: WEB_OAUTH_CLIENT,
+     redirectUri: `${window.location.origin}/callback`
+     scope: 'openid profile email address',
+     serverConfig: {
+       wellknown: WELLKNOWN_URL,
+       timeout: 3000, // Any value between 3000 to 5000 is good, this impacts the redirect time to login. Change that according to your needs.
+     },
+     tree: JOURNEY_LOGIN,
+   }
  );

@@ collapsed @@
```

#### Step 2. Building the login page
Since most of the action is taking place in `components/journey/form.js`, open it and add the Ping SDK for JavaScript import:
```sh
+ import { FRAuth } from '@forgerock/javascript-sdk';

@@ collapsed @@
```
FRAuth is the first object used as it provides the necessary methods for authenticating a user against the Login Journey/Tree. Use the `start()` method of FRAuth as it returns data we need for rendering the form.

You will need to add two new imports from the React package: useState and useEffect. You’ll use the `useState()` method for managing the data received from the server, and the useEffect is needed due to the `FRAuth.start()` method resulting in a network request.

```sh
import { FRAuth } from '@forgerock/javascript-sdk';
- import React from 'react';
+ import React, { useEffect, useState } from 'react';

  import Loading from '../utilities/loading';

  export default function Form() {
+   const [step, setStep] = useState(null);

+   useEffect(() => {
+     async function getStep() {
+       try {
+         const initialStep = await FRAuth.start();
+         console.log(initialStep);
+         setStep(initialStep);
+       } catch (err) {
+         console.error(`Error: request for initial step; ${err}`);
+       }
+     }
+     getStep();
+   }, []);

    return <Loading message="Checking your session ..." />;
  }
  ```

Below is a summary of what you’ll do to get the form to react to the new callback data:

Import the needed form-input components

Create a function to map over the callbacks and assign the appropriate component to render

Within the JSX, use a ternary to conditionally render the callbacks depending on their presence

If we do have callbacks, use our mapping function to render them

First, import the `Password`, `Text` and `Unknown` components.
```sh
import { FRAuth } from '@forgerock/javascript-sdk';
  import React, { useEffect, useState } from 'react';

  import Loading from '../utilities/loading';
+ import Alert from './alert';
+ import Password from './password';
+ import Text from './text';
+ import Unknown from './unknown';

@@ collapsed @@
```
Next, within the Form function body, create the function that maps these imported components to their appropriate callback.
```sh
@@ collapsed @@

  export default function Form() {
    const [step, setStep] = useState(null);

@@ collapsed @@

+   function mapCallbacksToComponents(cb, idx) {
+     const name = cb?.payload?.input?.[0].name;
+     switch (cb.getType()) {
+       case 'NameCallback':
+         return <Text callback={cb} inputName={name} key='username' />;
+       case 'PasswordCallback':
+         return <Password callback={cb} inputName={name} key='password' />;
+       default:
+         // If current callback is not supported, render a warning message
+         return <Unknown callback={cb} key={`unknown-${idx}`} />;
+     }
+   }
    return <Loading message="Checking your session ..." />;
  }
```
Finally, check for the presence of the step.callbacks, and if they exist, map over them with the function from above. Replace the single return of `<Loading message="Checking your session …​" />` with the following:
```sh
@@ collapsed @@

+   if (!step) {
+      return <Loading message='Checking your session ...' />;
+   } else if (step.type === 'Step') {
+     return (
+       <form className='cstm_form'>
+         {step.callbacks.map(mapCallbacksToComponents)}
+         <button className='btn btn-primary w-100' type='submit'>
+           Sign In
+         </button>
+       </form>
+     );
+   } else {
+     return <Alert message={step.payload.message} />;
+  }
```
Refresh the page, and you should now have a dynamic form that reacts to the callbacks returned from our initial call to ForgeRock.

#### Step 3. Handling the login form submission
Since a form that can’t submit anything isn’t very useful, we’ll now handle the submission of the user input values to ForgeRock. First, let’s edit the current form element, `<form className="cstm_form">`, and add an onSubmit handler with a simple, inline function.

```sh
@@ collapsed @@

- <form className='cstm_form'>
+ <form
+   className="cstm_form"
+   onSubmit={(event) => {
+     event.preventDefault();
+     async function getStep() {
+       try {
+         const nextStep = await FRAuth.next(step);
+         console.log(nextStep);
+         setStep(nextStep);
+       } catch (err) {
+         console.error(`Error: form submission; ${err}`);
+       }
+     }
+     getStep();
+   }}
+ >
```
Refresh the login page and use the test user to login. You will get a mostly blank login page if the user’s credentials are valid and the journey completes. You can verify this by going to the Network panel within the developer tools and inspect the last `/authenticate` request. It should have a `tokenId` and `successUrl` property.

Let’s take a look at the component for rendering the username input. Open up the Text component: `components/journey/text.js`. Notice how special methods are being used on the callback object. These are provided as convenience methods by the SDK for getting and setting data.

```sh
@@ collapsed @@

  export default function Text({ callback, inputName }) {
    const [state] = useContext(AppContext);
    const existingValue = callback.getInputValue();

    const textInputLabel = callback.getPrompt();
    function setValue(event) {
      callback.setInputValue(event.target.value);
    }

    return (
      <div className={`cstm_form-floating form-floating mb-3`}>
        <input
          className={`cstm_form-control form-control ${validationClass} bg-transparent ${state.theme.textClass} ${state.theme.borderClass}`}
          defaultValue={existingValue}
          id={inputName}
          name={inputName}
          onChange={setValue}
          placeholder={textInputLabel}
        />
        <label htmlFor={inputName}>{textInputLabel}</label>
      </div>
    );
  }
```
The two important items to focus on are the `callback.getInputValue()` and the `callback.setInputValue()`. The `getInputValue` retrieves any existing value that may be provided by ForgeRock, and the `setInputValue` sets the user’s input on the callback while they are typing (i.e. onChange). Since the callback is passed from the Form to the components by "reference" (not by "value"), any mutation of the callback object within the Text (or Password) component is also contained within the step object in Form.

Now that the form is rendering and submitting, add conditions to the Form component for handling the success and error response from ForgeRock. This condition handles the success result of the authentication journey. Back to the `form.js` file add the following:

```sh
@@ collapsed @@

  if (!step) {
    return <Loading message='Checking your session ...' />;
+ } else if (step.type === 'LoginSuccess') {
+   return <Alert message="Success! You're logged in." type='success' />;
  } else if (step.type === 'Step') {

@@ collapsed @@
```
Once you handle the success and error condition, return to the browser and remove all cookies created from any previous logins. Refresh the page and login with your test user created in the Setup section above. You should see a `"Success!"` alert message. 

#### Step 4. Continuing to the OAuth 2.0 flow
At this point, the user is authenticated. The session has been created and a session cookie has been written to the browser. This is "session-based authentication", and is viable when your system (apps and services) can rely on cookies as the access artifact. However, [there are increasing limitations with the use of cookies](https://webkit.org/blog/10218/full-third-party-cookie-blocking-and-more/). In response to this, and other reasons, it’s common to add a step to your authentication process: the "OAuth" or "OIDC flow".

The goal of this flow is to attain a separate set of tokens, replacing the need for cookies as the shared access artifact. The two common tokens are the Access Token and the ID Token. We will focus on the access token in this guide. The specific flow that the SDK uses to acquire these tokens is called the Authorization Code Flow with PKCE.

To start, import the TokenManager object from the Ping SDK into the same `form.js` file.

```sh
- import { FRAuth } from '@forgerock/javascript-sdk';
+ import { FRAuth, TokenManager } from '@forgerock/javascript-sdk';

@@ collapsed @@
```
Only an authenticated user that has a valid session can successfully request OAuth/OIDC tokens. Make sure we make this token request after we get a 'LoginSuccess' back from the authentication journey. This is an asynchronous call to the server. There are multiple ways to handle this, but we’ll use the useEffect and useState hooks.

Add a `useState` to the top of the function body to create a simple boolean flag of the user’s authentication state.
```sh
@@ collapsed @@

  export default function Form() {
    const [step, setStep] = useState(null);
+   const [isAuthenticated, setAuthentication] = useState(false);

@@ collapsed @@
```
Now, add a new `useEffect` hook to allow us to work with another asynchronous request. Unlike our first `useEffect`, this one will be dependent on the state of isAuthenticated. To do this, add `isAuthenticated` to the array passed in as the second argument. This instructs React to run the `useEffect` function when the value of `isAuthenticated` is changed.

```sh
@@ collapsed @@

+ useEffect(() => {
+   async function oauthFlow() {
+     try {
+       const tokens = await TokenManager.getTokens();
+       console.log(tokens);
+     } catch (err) {
+       console.error(`Error: token request; ${err}`);
+     }
+   }
+   if (isAuthenticated) {
+     oauthFlow();
+   }
+ }, [isAuthenticated]);

  @@ collapsed @@
```
Finally, we need to conditionally set this authentication flag when we have a success response from our authentication journey. In your form element’s `onSubmit` handler, add a simple conditional and set the flag to `true`.

```sh
@@ collapsed @@

  <form
    className="cstm_form"
    onSubmit={(event) => {
      event.preventDefault();
      async function getStep() {
        try {
          const nextStep = await FRAuth.next(step);
+         if (nextStep.type === 'LoginSuccess') {
+           setAuthentication(true);
+         }
          console.log(nextStep);
          setStep(nextStep);
        } catch (err) {
          console.error(`Error: form submission; ${err}`);
        }
      }
      getStep();
    }}
  >

@@ collapsed @@
```
Once the changes are made, return to your browser and remove all cookies created from any previous logins. Refresh the page and verify the login form is rendered. If the success message continues to display, make sure "third-party cookies" are also removed.

Login with your test user. You should get a success message like you did before, but now check your browser’s console log. You should see an additional entry of an object that contains your idToken and accessToken. Since the SDK handles storing these tokens for you, which are in localStorage, you have completed a full login and OAuth/OIDC flow.

#### Step 5. Request user information
Now that the user is authenticated and an access token is attained, you can now make your first authenticated request! The SDK provides a convenience method for calling the `/userinfo` endpoint, a standard OAuth endpoint for requesting details about the current user. The data returned from this endpoint correlates with the "scopes" set within the SDK configuration. The scopes profile and email will allow the inclusion of user’s first and last name as well as their email address.

Within the `form.js` file, add the UserManager object to our Ping SDK import statement.

```sh
- import { FRAuth, TokenManager } from '@forgerock/javascript-sdk';
+ import { FRAuth, TokenManager, UserManager } from '@forgerock/javascript-sdk';

@@ collapsed @@
```
The `getCurrentUser()` method on this new object will request the user’s data and validate the existing access token. After the `TokenManager.getTokens()` method call, within the `oauthFlow()` function from above, add this new method.
```sh
@@ collapsed @@

  try {
    const tokens = await TokenManager.getTokens();
    console.log(tokens);
+   const user = await UserManager.getCurrentUser();
+   console.log(user);

@@ collapsed @@
```

If the access token is valid, the user information will be logged to the console, just after the tokens. Before we move on from the `form.js` file, set a small portion of this state to the global context for application-wide state access. Add the remaining imports for setting the state and redirecting back to the home page: `useContext`, `AppContext `and `useNavigate`.

```sh
- import React, { useEffect, useState } from 'react';
+ import React, { useContext, useEffect, useState } from 'react';
+ import { useNavigate } from 'react-router-dom';

+ import { AppContext } from '../../global-state';

@@ collapsed @@

```
At the top of the Form function body, use the `useContext()` method to get the app’s global state and methods. Call the `useNavigate()` method to get the navigation object.
```sh
export default function Form() {
    const [step, setStep] = useState(null);
    const [isAuthenticated, setAuthentication] = useState(false);
+   const [_, methods] = useContext(AppContext);
+   const navigate = useNavigate();

@@ collapsed @@
```

After the `UserManager.getCurrentUser()` call, set the new user information to the global state and redirect to the home page.
```sh
@@ collapsed @@

  const user = await UserManager.getCurrentUser();
  console.log(user);

+ methods.setUser(user.name);
+ methods.setEmail(user.email);
+ methods.setAuthentication(true);

+ navigate('/');

@@ collapsed @@
```
Revisit the browser, clear out all cookies, storage and cache, and log in with you test user. If you landed on the home page and the logs in the console show tokens and user data, you have successfully used the access token for retrieving use data. Notice that the home page looks a bit different with an added success alert and message with the user’s full name. This is due to the app "reacting" to the global state that we set just before the redirection.

#### Step 6. Reacting to the presence of the access token
To ensure your app provides a good user experience, it’s important to have a recognizable, authenticated experience, even if the user refreshes the page or closes and reopens the browser tab. This makes it clear to the user that they are logged in.

Currently, if you refresh the page, the authenticated experience is lost. Let’s fix that!

Because the SDK stores the tokens in localStorage, you can use their presence as a hint for their authentication status without requiring a network request. This allows for quickly rendering the appropriate navigational elements and content to the screen.

To do this, add the `TokenStorage.get` method to the `index.js` file as it will provide what we need to rehydrate the user’s authentication status. First, import `TokenStorage` into the file. Use the `TokenStorage.get()` method within the initAndHydrate function. Second, add these values to the `useGlobalStateMgmt` function call.

```sh
- import { Config } from '@forgerock/javascript-sdk';
+ import { Config, TokenStorage } from '@forgerock/javascript-sdk';

  (async function initAndHydrate() {
   let isAuthenticated;
+   try {
+     isAuthenticated = !!(await TokenStorage.get());
+   } catch (err) {
+     console.error(`Error: token retrieval for hydration; ${err}`);
+   }

@@ collapsed @@

  function Init() {
    const stateMgmt = useGlobalStateMgmt({
      email,
+     isAuthenticated,
      prefersDarkTheme,
      username,
    });

@@ collapsed @@
```
With a global state API available throughout the app, different components can pull this state in and use it to conditionally render one set of UI elements versus another. Navigation elements and the displaying of profile data are good examples of such conditional rendering. Examples of this can be found by reviewing `components/layout/header.js` and `views/home.js`.

#### Step 7. Validating the access token
You can ensure the token is still valid with the use of `getCurrentUser()` method from earlier. This is optional, depending on your product requirements. If needed, you can protect routes with a token validation check before rendering portions of your application. This can prevent a potentially jarring experience of partial rendering UI that may be ejected due to an invalid token.

To validate a token for protecting a route, open the `router.js` file, import the `ProtectedRoute` module and replace the regular `<Route path="todos">` with the new ProtectedRoute wrapper.
```sh
@@ collapsed @@

  import Register from './views/register';
+ import { ProtectedRoute } from './utilities/route';
  import Todos from './views/todos';

@@ collapsed @@

  <Route
  path="todos"
  element={
  + <ProtectedRoute>
      <Header />
      <Todos />
      <Footer />
  + </ProtectedRoute>
    }
  />

@@ collapsed @@
```
Let’s take a look at what this wrapper does. Open `utilities/route.js` file and focus just on the validateAccessToken function within the useEffect function. Currently, it’s just checking for the existence of the tokens with `TokenStorage.get`, which may be fine for some situations. We can optionally call the `UserManager.getCurrentUser()` method to ensure the stored tokens are still valid.

To do this, import UserManager into the file, and then replace `TokenStorage.get` with `UserManager.getCurrentUser`.
```sh
import React, { useContext, useEffect, useState } from 'react';
  import { Route, Redirect } from 'react-router-dom';
- import { TokenStorage } from '@forgerock/javascript-sdk';
+ import { UserManager } from '@forgerock/javascript-sdk';

@@ collapsed @@

  useEffect(() => {
    async function validateAccessToken() {
     if (auth) {
        try {
-         await TokenStorage.get();
+         await UserManager.getCurrentUser();
          setValid('valid');
        } catch (err) {

@@ collapsed @@
```
In the code above, we are reusing the `getCurrentUser()` method to validate the token. If it succeeds, we can be sure our token is valid and call setValid to 'valid' . If it fails, we know it is not valid and call setValid to 'invalid'. We set that outcome with our `setValid()` state method and the routing will know exactly where to redirect the user.

Revisit the browser and refresh the page. Navigate to the todos page. You will notice a quick spinner and text communicating that the app is "verifying access". Once the server responds, the Todos page renders. As you can see, the consequence of this is the protected route now has to wait for the server to respond, but the user’s access has been verified by the server.

#### Step 8. Request protected resources with an access token
Once the Todos page renders, notice how the todo collection has a persistent spinner to indicate the process of requesting todos. This is due to the `fetch` request not having the proper headers for making an authorized request, so the request does not succeed.

Open `utilities/request.js` and import the `HttpClient` from the Ping SDK. Then, replace the native `fetch` method with the `HttpClient.request()` method.
```sh
+ import { HttpClient } from '@forgerock/javascript-sdk';
  import { API_URL, DEBUGGER } from '../constants';

  export default async function apiRequest(resource, method, data) {
    let json;
    try {
-     const response = await fetch(`${API_URL}/${resource}`, {
+     const response = await HttpClient.request({
+       url: `${API_URL}/${resource}`,
+       init: {
          body: data && JSON.stringify(data),
          headers: {
            'Content-Type': 'application/json',
          },
          method: method,
+       },
      });

@@ collapsed @@
```
At this point, the user can log in, request access tokens, and access the page of the protected resources (todos).

#### Step 9. Handle logout request
Open up the `views/logout.js` file and import the following:

- `FRUser` from the Ping SDK

- `useEffect` and `useContext` from React

- `useNavigate` from React Router

- `AppContext` from the global state module.

```sh
+ import { FRUser } from '@forgerock/javascript-sdk';
- import React from 'react';
+ import React, { useContext, useEffect } from 'react';
+ import { useNavigate } from 'react-router-dom';

+ import { AppContext } from '../global-state';

@@ collapsed @@
```
Since logging out requires a network request, we need to wrap it in a useEffect and pass in a callback function with the following functionality:
```sh
@@ collapsed @@

  export default function Logout() {
+   const [_, { setAuthentication, setEmail, setUser }] = useContext(AppContext);
+   const navigate = useNavigate();

+   useEffect(() => {
+     async function logout() {
+       try {
+         await FRUser.logout();

+         setAuthentication(false);
+         setEmail('');
+         setUser('');

+         navigate('/');
+       } catch (err) {
+         console.error(`Error: logout; ${err}`);
+       }
+     }
+     logout();
+   }, []);

    return <Loading classes="pt-5" message="You're being logged out ..." />;
  }
```
Since we only want to call this method once, after the component mounts, we will pass in an empty array as a second argument for useEffect(). After FRUser.logout() completes, we just empty or falsify the global state to clean up and redirect back to the home page.

Once all the above is complete, return to your browser, empty the cache, storage and cache, and reload the page. You should now be able to log in with the test user, navigate to the todos page, add and edit some todos, and logout by clicking the profile icon in the top-right and clicking "Sign Out".