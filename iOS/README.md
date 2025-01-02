<p align="center">
  <a href="https://github.com/ForgeRock/sdk-sample-apps">
    <img src="https://www.pingidentity.com/content/dam/picr/nav/Ping-Logo-2.svg" alt="Ping Identity Logo">
  </a>
  <hr/>
</p>

## Samples

_Ping provides these iOS samples to help demonstrate SDK functionality/implementation. They are provided "as is" and are not official products of Ping and are not officially supported._

The Ping SDK for iOS enables you to integrate your iOS application with Ping services.

There are two UI deployment options:
- Embedded:
  - With this option, each app has to have its own login User Interface (UI).
  - Users  authenticate natively to your application.
- OIDC (Redirect) Login:
  - Often referred to as centralized login, with this option you reuse a central UI (such as hosted pages for PingOne Advanced Identity Cloud or the Login Widget for PingOne/PingOne DaVinci) your own web application for login requests in multiple apps and sites.
  - User's are redirected via a browser to a central place for authentication.

We provide samples that demonstrate both methods.

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

-  [**DaVinci using SwiftUI - `/ios/swiftui-davinci`**](./swiftui-davinci/)

    - An example iOS project written in Swift/SwiftUI making use of the SDK.
      The sample supports the OOTB PingOne Sign on With Sessions flow in DaVinci environments and found in the marketplace. Demonstrates use cases such as user authentication, registration, and account recovery.
    (https://docs.pingidentity.com/sdks/latest/davinci/tutorials/ios/index.html)

   
### OIDC Login:

- [**OIDC (Redirect) Login using SwiftUI - `/ios/swiftui-oidc`**](./swiftui-oidc/)
  - A sample app
    that demonstrates the functionality
    of using the Ping SDK for iOS for OIDC (redirect) authentication.
    Can be used with PingOne Advanced Identity Cloud,
    PingOne, PingOne DaVinci (via a PingOne application),
    PingAM, and PingFederate.
    (https://docs.pingidentity.com/sdks/latest/oidc/index.html)

## Documentation

Detailed [documentation](https://docs.pingidentity.com/sdks) is provided, and includes topics such as:

- Tutorial walkthroughs for each server
- Integrating functionality such as PingOne Protect, WebAuthn, and more
- Code snippets
- API Reference documentation

## Requirements

- Latest Xcode
