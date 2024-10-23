# Central login

The ForgeRock SDK provides an option for using the Authorization Code Flow (with PKCE) with a centralized login application.

For a non-authenticated user, use the `login: redirect` parameter of the `TokenManager` class to request OAuth/OIDC tokens. 

This instructs the SDK to redirect the user to the login application that uses either the ForgeRock platform, or PingOne. 

After successful authentication, the SDK redirects the user back to this sample application to obtain OAuth/OIDC tokens and complete the centralized login flow.

To configure this sample, follow the steps in [Getting Started](#getting-started).

Then, run the sample app as follows:
```
npm run start:central-login
``` 

### Instructions

* [ForgeRock server](#forgerock-server)
* [PingOne server](#pingone-server)

#### ForgeRock server

1. Setup CORS support in an Access Management (AM) instance.

   See [Enabling CORS Support](https://sdks.forgerock.com/js/01_prepare-am/#enabling-cors-support) in the Documentation.

2. Create an authentication tree in AM.

   See [Creating a User Authentication Tree](https://sdks.forgerock.com/js/01_prepare-am/#creating-a-user-authentication-tree) in the Documentation.

3. Clone this repo:

   ```
   git clone https://github.com/ForgeRock/sdk-sample-apps/
   ```

4. In the root folder of the repo, use NPM to install dependencies:

   ```
   npm install
   ```

5. Open `central-login/.env.example`. Copy the file in the same directory and name it `.env`. Fill in the values in this file with your values.

6. Run the Central Login application

   ```
   npm run start:central-login
   ```

7. In a [supported web browser](../README.md#requirements), navigate to [https://localhost:8443](https://localhost:8443).


#### PingOne server

* For instructions on configuring this sample to work with a PingOne server, refer to the [PingOne JavaScript tutorial](https://backstage.forgerock.com/docs/sdks/latest/sdks/tutorials/javascript/index.html#tutorial_steps).