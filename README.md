<p align="center">
  <a href="https://github.com/ForgeRock/sdk-sample-apps">
    <img src="https://cdn.forgerock.com/logo/interim/Logo-PingIdentity-ForgeRock-Hor-FullColor.svg" alt="Logo">
  </a>
  <hr/>
</p>

## Samples

ForgeRock provides these samples to help demonstrate SDK functionality/implementation. They are provided "as is" and are not official products of ForgeRock and are not officially supported.

To try out the ForgeRock JavaScript SDK please look at one of our samples:

- [**Embedded login - `embedded-login`**](./embedded-login/README.md)

  - A barebones example of how to use the `@forgerock/javascript-sdk` in a vanilla html & javascript app with embedded login.

- [**Central login - `central-login`**](./central-login/README.md)

  - A barebones example of how to use the `@forgerock/javascript-sdk` in a vanilla html & javascript app with central login.

- [**React Todo - `reactjs-todo`**](./reactjs-todo/README.md)

  - Todo application that involves authentication and authorization of a user to post Todos with the `@forgerock/javascript-sdk` in ReactJS.
    The main branch includes many flavors of callbacks, including WebAuthN, embedded login, and social login.

- [**Angular Todo - `angular-todo`**](./angular-todo/README.md)
  - Todo application that involves authentication and authorization of a user to post Todos with the `@forgerock/javascript-sdk` in Angular.
    The main branch includes many flavors of callbacks, including WebAuthN, embedded login, and social login.

To try out the ForgeRock iOS SDK please look at one of our samples:

- [**FRAuthenticator Example - `iOS/FRAuthenticatorExample`**](./iOS/FRAuthenticatorExample/FRAuthenticatorExample.xcodeproj/)
  - An example of how to use the Forgerock Authenticator Module of the SDK in a simple iOS Project. 
  (https://backstage.forgerock.com/docs/sdks/latest/authenticator/index.html)

- [**FRExample - `iOS/FRExample`**](./iOS/FRExample.xcworkspace/)
  - An example iOS project making full use of the Forgerock SDK with a prototyping UI. Allows to explore the SDK uses in detail. Running the workspace makes use of the `FRExample`, `FRExampleObjC` and `FRAuthenticatorExample` projects.
  (https://backstage.forgerock.com/docs/sdks/latest/sdks/tutorials/ios/index.html)

- [**PasskeysSample - `iOS/PasskeysSample`**](./iOS/PasskeysSample/UnsummitAuthentication/UnsummitAuthentication.xcodeproj/)
  - An example iOS project making using Passkeys and WebAuthn with the Forgerock SDK. Based on the "Set up passwordless authentication with Passkeys" blog.
  (https://backstage.forgerock.com/docs/sdks/latest/sdks/use-cases/how-to-go-passwordless-with-passkeys.html)

<!------------------------------------------------------------------------------------------------------------------------------------>
<!-- DOCS - Link off to the AM-centric documentation at sdks.forgerock.com. -->

## Documentation

Documentation for the SDKs is provided on [ForgeRock Backstage](https://backstage.forgerock.com/docs/sdks/latest/index.html), and includes topics such as:

- Introducing the SDK Features
- Preparing your server for use with the SDKS
- API Reference documentation

## Requirements

Javascript
- Please use a modern web browser like Chrome, Safari, or Firefox
- Node >= 18

iOS
- Latest Xcode
