# Central login OIDC

The SDK provides an option for using the Authorization Code Flow (with PKCE) with a centralized login application.

For a non-authenticated user, use the `login: redirect` parameter of the `TokenManager` class to request OAuth/OIDC tokens. 

This instructs the SDK to redirect the user to the login application that uses either the ForgeRock platform, or PingOne. 

After successful authentication, the SDK redirects the user back to this sample application to obtain OAuth/OIDC tokens and complete the centralized login flow.

### Instructions

To configure your server, following the steps in [Getting Started](https://docs.pingidentity.com/sdks/latest/sdks/getting-started.html).

Then, create your configuration `.env` file based on the included `.env.example`.

Set the `SERVER_TYPE` property to either `PINGONE` or `AIC`, based on the server used.

Then, run the sample app as follows:
```
npm run start:central-login-oidc
``` 
