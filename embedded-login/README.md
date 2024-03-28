# Embedded login

In most real-world scenarios, you will want to have full control over the UI. In these cases, you can use `FRAuth` to obtain typed callback instances from authentication trees and render the UI in whatever way makes sense for your application.

You can run this sample app with the `npm run start:embedded-login` command. Please [see the Getting Started instructions](#getting-started) for more details.

### Getting Started

1. Setup CORS support in an Access Management (AM) instance.

   See [Enabling CORS Support](https://sdks.forgerock.com/serverconfiguration/onpremise/configure-cors-configuration/) in the Documentation.

2. Create an authentication tree in AM.

   See [Creating a User Authentication Tree](https://sdks.forgerock.com/serverconfiguration/cloud/create-user-auth-workflow/) in the Documentation.

3. Clone this repo:

   ```
   git clone https://github.com/ForgeRock/sdk-sample-apps/
   ```

4. In the root folder of the repo, use NPM to install dependencies:

   ```
   npm install
   ```

5. Open `samples/embedded-login/.env.example`. Copy the file in the same directory and name it `.env`. Fill in the values in this file with your values.

6. Run the Embedded Login application

   ```
   npm run start:embedded-login
   ```

7. In a [supported web browser](../../README.md#requirements), navigate to [https://localhost:8443](https://localhost:8443)
