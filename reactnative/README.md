[![Ping Identity](https://www.pingidentity.com/content/dam/picr/nav/Ping-Logo-2.svg)](https://github.com/ForgeRock/sdk-sample-apps)

## React Native Samples

_Ping provides these React Native samples to help demonstrate SDK functionality/implementation. They are provided "as is" and are not official products of Ping and are not officially supported._

The Ping SDK for React Native enables you to integrate your React Native application with Ping services.

There are two UI deployment options:
- Embedded:
  - With this option, each app has to have its own login User Interface (UI).
  - Users authenticate natively to your application.
- OIDC (Redirect) Login:
  - Often referred to as centralized login, with this option you reuse a central UI (such as hosted pages for PingOne Advanced Identity Cloud or the Login Widget for PingOne/PingOne DaVinci) your own web application for login requests in multiple apps and sites.
  - User's are redirected via a browser to a central place for authentication.

We provide samples that demonstrate both methods.

### Integrate with Auth Journeys - PingOne Advanced Identity Cloud / PingAM:

- [**React Native Journey - `/reactnative-journey`**](./reactnative-journey/)

  - An example React Native project making full use of the Ping Orchestration SDK for React Native. The sample supports the OOTB Login Journey with Username and Password, along with device binding, FIDO/WebAuthn, external IdP, device profile, push, and OATH callback integrations.
  (https://developer.pingidentity.com/orchsdks/journey/index.html)

### OIDC Login:

- [**React Native OIDC - `/reactnative-oidc`**](./reactnative-oidc/)

  - A sample app that demonstrates the functionality of using the Ping SDK for React Native for OIDC (redirect) authentication. Can be used with PingOne Advanced Identity Cloud, PingOne and PingAM.
  (https://developer.pingidentity.com/orchsdks/oidc/index.html)

## License

This software may be modified and distributed under the terms of the MIT license. See the LICENSE file for details.

© Copyright 2024-2026 Ping Identity Corporation. All rights reserved.
