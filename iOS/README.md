[![Ping Identity](https://www.pingidentity.com/content/dam/picr/nav/Ping-Logo-2.svg)](https://github.com/ForgeRock/sdk-sample-apps)

## iOS Samples

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

- [**Journey using SwiftUI - `/ios/swiftui-journey-module`**](./swiftui-journey-module/)
  
  - An example iOS project in Swift/SwiftUI making use of the Journey module of the Ping Orchestration SDK. 
    The sample supports the OOTB Login Journey with Username and Password.
  (https://developer.pingidentity.com/orchsdks/journey/index.html)


### Integrate with flows - PingOne DaVinci:

- [**DaVinci using SwiftUI - `/ios/swiftui-davinci`**](./swiftui-davinci/)

    - An example iOS project written in Swift/SwiftUI making use of the DaVinci module of the Ping Orchestration SDK.
      The sample supports the OOTB PingOne Sign on With Sessions flow in DaVinci environments and found in the marketplace. Demonstrates use cases such as user authentication, registration, and account recovery.
    (https://developer.pingidentity.com/orchsdks/davinci/index.html)

   
### OIDC Login:

- [**OIDC (Redirect) Login using SwiftUI - `/ios/swiftui-oidc`**](./swiftui-oidc/)
  - A sample app
    that demonstrates the functionality
    of using the Ping SDK for iOS for OIDC (redirect) authentication.
    Can be used with PingOne Advanced Identity Cloud,
    PingOne, PingOne DaVinci (via a PingOne application),
    PingAM, and PingFederate.
    (https://developer.pingidentity.com/orchsdks/oidc/index.html)

## License

This software may be modified and distributed under the terms of the MIT license. See the LICENSE file for details.

© Copyright 2024-2026 Ping Identity Corporation. All rights reserved.