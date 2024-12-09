<p align="center">
  <a href="https://github.com/ForgeRock/sdk-sample-apps">
    <img src="https://www.pingidentity.com/content/dam/picr/nav/Ping-Logo-2.svg" alt="Ping Identity Logo">
  </a>
  <hr/>
</p>

## Samples

Ping provides these iOS samples to help demonstrate SDK functionality/implementation. They are provided "as is" and are not official products of Ping and are not officially supported.

The Ping SDK for iOS enables you to integrate your SPA with our services.
There are two methods of UI integration:
- Embedded - With this option, each app has to have its own login User Interface (UI).
  When a user attempts to log in to your application or site, they authenticate directly within the currently used application instead of being directed to a centralized web application to authenticate the user.
- OIDC Login - Often referred to as centralized login,
  with this option you reuse a central UI
  (such as hosted pages for PingOne Advanced Identity Cloud or the Login Widget for PingOne/PingOne DaVinci)
  or your own web application for login requests in multiple apps and sites.
  When a user attempts to log in to your application or site, they are redirected to a central login UI. After the user authenticates, they are redirected back to your application or site.

The sample apps focus on embedded login,
except where noted in the _OIDC Login_ section.

### Integrate with Auth Journeys - PingOne Advanced Identity Cloud / PingAM:

To try out the Ping iOS SDK please look at one of our samples:

- [**FR Example - `/uikit-frexamples/FRExample`**](./uikit-frexamples/)
  
  - An example iOS project making full use of the iOS SDK with a prototyping UI. Allows to explore the SDK uses in detail with example calls for running Journeys, getting OAuth2.0 tokens, User Info and more. Running the workspace makes use of the `FRExample`, `FRExampleObjC` and `FRAuthenticatorExample` projects.
  (https://docs.pingidentity.com/sdks/latest/sdks/tutorials/ios/index.html)

- [**Passkeys Sample - `/uikit-passkeys-sample`**](./uikit-passkeys/UnsummitAuthentication/)
  
  - An example iOS project using the Ping iOS SDK, showcasing how to protect an application using Journeys and Passkeys. Based on the "Set up passwordless authentication with Passkeys" blog.
  (https://docs.pingidentity.com/sdks/latest/sdks/use-cases/how-to-go-passwordless-with-passkeys.html)

- [**QuickStart using SwiftUI - `/ios/swiftui-quickstart/QuickStart-SwiftUI`**](./swiftui-quickstart/)
  
  - An example iOS project making use of the SDK and SwiftUI. The sample supports the OOTB Login Journey with Username and Password.
  (https://docs.pingidentity.com/sdks/latest/sdks/tutorials/ios/index.html)

- [**QuickStart using UIKit - `/ios/uikit-quickstart/QuickStart`**](./uikit-quickstart/)
 
  - An example iOS project making use of the SDK and UIKit. The sample supports the OOTB Login Journey with Username and Password.
  (https://docs.pingidentity.com/sdks/latest/sdks/tutorials/ios/index.html)


### Integrate with flows - PingOne DaVinci:

-  [**Davinci using SwiftUI - `/ios/swiftui-davinci`**](./swiftui-davinci/)

    - An example iOS project written in Swift/SwiftUI making use of the SDK. The sample supports the OOTB PingOne Sign on with Sessions DaVinci flow.
   
### OIDC Login:

- Coming soon

## Documentation

Detailed [documentation](https://docs.pingidentity.com/sdks/latest/sdks/index.html) is provided, and includes topics such as:

- Introducing the SDK features
- Preparing your server for use with the SDKs
- API Reference documentation

## Requirements

- Latest Xcode
