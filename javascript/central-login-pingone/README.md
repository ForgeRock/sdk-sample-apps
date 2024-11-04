# Central login

The SDK provides an option for using the Authorization Code Flow (with PKCE) with a centralized login application.

For a non-authenticated user, use the `login: redirect` parameter of the `TokenManager` class to request OAuth/OIDC tokens. 

This instructs the SDK to redirect the user to the login application that uses either the ForgeRock platform, or PingOne. 

After successful authentication, the SDK redirects the user back to this sample application to obtain OAuth/OIDC tokens and complete the centralized login flow.

To configure this sample, follow the steps in [Getting Started](#getting-started).

Then, run the sample app as follows:
```
npm run start:central-login
``` 

### Instructions

* [PingOne server](#pingone-server)

#### PingOne server

* For instructions on configuring this sample to work with a PingOne server, refer to the [PingOne JavaScript tutorial](https://docs.pingidentity.com/sdks/latest/sdks/tutorials/javascript/index.html#tutorial_steps).