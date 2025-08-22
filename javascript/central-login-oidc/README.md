# OIDC Login

\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\
**IMPORTANT NOTE**: This sample app is deprecated. Please refer to the central-login-oidc-client sample app [here](https://github.com/ForgeRock/sdk-sample-apps/tree/main/javascript/central-login-oidc-client) for the latest information.\
\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*

The SDK provides an option for using the Authorization Code Flow
(with PKCE) with a centralized application using OIDC Login. 

For a non-authenticated user, use the `login: redirect` parameter of the `TokenManager` class to request OAuth/OIDC tokens. 

This instructs the SDK to redirect the user to the login application that uses either the ForgeRock platform, or PingOne. 

After successful authentication, the SDK redirects the user back to this sample application to obtain OAuth/OIDC tokens and complete the centralized login flow.

### Instructions

To configure your server, following the steps in [Getting Started](https://docs.pingidentity.com/sdks/latest/sdks/getting-started.html).

Then, create your configuration `.env` file based on the included `.env.example`.

- Set the `SCOPE` property to a "space separated" string, containing the scopes your app is requesting. For `PINGONE` servers the `revoke` scope is required. eg: `openid address revoke`
- Set the `TIMEOUT` property to the amount of miliseconds. Any value between 3000 to 5000 is good, this impacts the redirect time to login. Change that according to your needs.
- Set the `WEB_OAUTH_CLIENT` to the OAuth2.0 client ID that has been set up on your server.

- Set the `SERVER_TYPE` property to either `PINGONE` or `AIC`, based on the server used. If your server is PingOne Services, DaVinci or PingFed set this to `PINGONE`. If your server is Ping Advanced Identity Cloud or PingAM, please use `AIC`.


Then, move on the `/javascript` folder and run the sample app as follows:
```
npm install 

npm run start:central-login-oidc

``` 
