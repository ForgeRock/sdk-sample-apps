<p align="center">
  <a href="https://github.com/ForgeRock/sdk-sample-apps">
    <img src="https://cdn.forgerock.com/logo/interim/Logo-PingIdentity-ForgeRock-Hor-FullColor.svg" alt="Logo">
  </a>
  <hr/>
</p>

## Samples

Ping provides these samples to help demonstrate SDK functionality/implementation. They are provided "as is" and are not official products of Ping and are not officially supported.

### Integrate with PingOne Advanced Identity Cloud / PingAM:

To try out the Ping JavaScript SDK please look at one of our samples:

- [**Embedded login - `embedded-login`**](./embedded-login/README.md)

  - A barebones example of how to use the `@forgerock/javascript-sdk` in a vanilla html & javascript app with embedded login. The sample supports the OOTB Login Journey with Username and Password.

- [**Central login - `central-login`**](./central-login/README.md)

  - A barebones example of how to use the `@forgerock/javascript-sdk` in a vanilla html & javascript app with centralized login (OIDC Login). 

- [**React Todo - `reactjs-todo`**](./reactjs-todo/README.md)

  - Todo application that involves authentication and authorization of a user to post Todos with the `@forgerock/javascript-sdk` in ReactJS.
    The main branch includes many flavors of callbacks, including WebAuthN, embedded login, and social login.

- [**Angular Todo - `angular-todo`**](./angular-todo/README.md)
  
  - Todo application that involves authentication and authorization of a user to post Todos with the `@forgerock/javascript-sdk` in Angular.
    The main branch includes many flavors of callbacks, including WebAuthN, embedded login, and social login.

To try out the Ping iOS SDK please look at one of our samples:

- [**FRAuthenticator Example - `iOS/FRAuthenticatorExample`**](./iOS/AIC&PingAM/FRAuthenticatorExample/FRAuthenticatorExample.xcodeproj/)
  
  - The `FRAuthenticator Example` is a sample app that showcases how to integrate OATH OTPs or Push notifications in the iOS SDK, to have an embedded  MFA-experience directly within your app. This is for use with PingOne Advanced Identity Cloud and PingAM.
  (https://backstage.forgerock.com/docs/sdks/latest/authenticator/index.html)

- [**FRExample - `iOS/FRExample`**](./iOS/AIC&PingAM/FRExample.xcworkspace/)
  
  - An example iOS project making full use of the Ping SDK with a prototyping UI. Allows to explore the SDK uses in detail with example calls for running Journeys, getting OAuth2.0 tokens, User Info and more. Running the workspace makes use of the `FRExample`, `FRExampleObjC` and `FRAuthenticatorExample` projects.
  (https://backstage.forgerock.com/docs/sdks/latest/sdks/tutorials/ios/index.html)

- [**PasskeysSample - `iOS/PasskeysSample`**](./iOS/AIC&PingAM/PasskeysSample/UnsummitAuthentication/UnsummitAuthentication.xcodeproj/)
  
  - An example iOS project using the Ping iOS SDK, showcasing how to protect an application using Journeys and Passkeys. Based on the "Set up passwordless authentication with Passkeys" blog.
  (https://backstage.forgerock.com/docs/sdks/latest/sdks/use-cases/how-to-go-passwordless-with-passkeys.html)

- [**QuickStart SwiftUI - `iOS/QuickStart-SwiftUI`**](./iOS/AIC&PingAM/QuickStart-SwiftUI/QuickStart.xcodeproj/)
  
  - An example iOS project making use of the SDK and SwiftUI. The sample supports the OOTB Login Journey with Username and Password.
  (https://backstage.forgerock.com/docs/sdks/latest/sdks/tutorials/ios/index.html)

- [**QuickStart Example - `iOS/QuickStart-SwiftUI`**](./iOS/AIC&PingAM/QuickstartExample/Quickstart.xcodeproj/)
 
 - An example iOS project making use of the SDK and UIKit. The sample supports the OOTB Login Journey with Username and Password.
 (https://backstage.forgerock.com/docs/sdks/latest/sdks/tutorials/ios/index.html)


### Integrate with PingOne DaVinci:

- Samples coming soon

## Documentation

Documentation for the SDKs is provided on [ForgeRock Backstage](https://backstage.forgerock.com/docs/sdks/latest/index.html), and includes topics such as:

- Introducing the SDK Features
- Preparing your server for use with the SDKs
- API Reference documentation

## Requirements

Javascript
- Please use a modern web browser like Chrome, Safari, or Firefox
- Node >= 18

iOS
- Latest Xcode
