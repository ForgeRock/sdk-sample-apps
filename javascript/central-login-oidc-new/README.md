# OIDC Login

The SDK provides an OIDC client for using the Authorization Code Flow
(with PKCE) with a centralized application using OIDC Login. 

For a non-authenticated user, use the `authorize.url()` method to get an authorization URL. This can be used to redirect the user to the login application that uses either PingAM or PingOne.  After successful authentication, the user is redirected back to the sample application. Then use the `token.exchange()` method to request OAuth/OIDC tokens. 

### Instructions

To configure your server, following the steps in the [OIDC Login](https://docs.pingidentity.com/sdks/latest/oidc/configure-the-sdks.html) documentation.

Then, create your configuration `.env` file based on the included `.env.example`.

- Set the `VITE_SCOPE` property to a "space separated" string, containing the scopes your app is requesting. For PingOne servers the `revoke` scope is required. eg: `openid profile revoke`

- Set the `VITE_TIMEOUT` property to the amount of miliseconds. Any value between 3000 to 5000 is good, this impacts the redirect time to login. Change that according to your needs.

- Set the `VITE_WEB_OAUTH_CLIENT` to the OAuth2.0 client ID that has been set up on your server.

- Set the `VITE_WELLKNOWN_URL` to the wellknown URL for your OAuth client


Then, from the `/javascript` folder run the sample app as follows:
```
npm install 
npm run start:central-login-oidc
``` 
