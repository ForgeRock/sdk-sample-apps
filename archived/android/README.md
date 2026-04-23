[![Ping Identity](https://www.pingidentity.com/content/dam/picr/nav/Ping-Logo-2.svg)](https://github.com/ForgeRock/sdk-sample-apps)

> [!IMPORTANT]
> **The applications contained in this folder are no longer supported and will not receive any further feature updates. These applications were built solely to demonstrate features of the legacy ForgeRock SDK 4.x.**
>
>**The ForgeRock SDK v4.x entered a maintenance-only phase on April 15, 2026, and its end-of-support is scheduled for April 15, 2028. During this period, the SDK will only receive critical bug fixes and security updates.**

## Recommended Action: Migrate to Ping Orchestration SDK v2.x

We strongly recommend migrating to the Ping Orchestration SDK v2.x. New sample applications and [migration guides](https://developer.pingidentity.com/orchsdks/journey/migration.html) are available to assist with this transition.

Adopting the latest Ping Orchestration SDK ensures the security, compatibility, and stability of your solutions, offering improved features, enhanced performance, and continued support from Ping.

## Android Samples

_Ping provides these Android samples to help demonstrate SDK functionality/implementation. They are provided "as is" and are not official products of Ping and are not officially supported._

The Ping SDK for Android enables you to integrate your Android application with Ping services.

There are two UI deployment options:
- Embedded:
  - With this option, each app has to have its own login User Interface (UI). 
  - Users  authenticate natively to your application.
- OIDC (Redirect) Login:
  - Often referred to as centralized login, with this option you reuse a central UI (such as hosted pages for PingOne Advanced Identity Cloud or the Login Widget for PingOne/PingOne DaVinci) your own web application for login requests in multiple apps and sites. 
  - User's are redirected via a browser to a central place for authentication.

We provide samples that demonstrate both methods.

### Integrate with Auth Journeys - PingOne Advanced Identity Cloud / PingAM:

To try out the Ping Android SDK please look at one of our samples:

- [**Java Authenticator - `/java-authenticator`**](./java-authenticator/)
  
  - This Authenticator sample app supports registration of multiple accounts and multiple different authentication methods in each account, such as push notifications and one-time passwords.

- [**Java UI prototype - `/java-ui-prototype`**](./java-ui-prototype/)
  
  - An example Android project making full use of the Android SDK with a prototyping UI. Allows to explore the SDK uses in detail with example calls for running Journeys, getting OAuth2.0 tokens, User Info and more. 
  (https://docs.pingidentity.com/sdks/latest/sdks/tutorials/android/index.html)

- [**Java Quickstart - `/java-quickstart`**](./java-quickstart/)
  
  - An example Android project written in Java making use of the SDK. The sample supports the OOTB Login Journey with Username and Password. (https://docs.pingidentity.com/sdks/latest/sdks/tutorials/android/index.html)

- [**Kotlin Quickstart - `/kotlin-quickstart`**](./kotlin-quickstart/)
  
  - An example Android project written in Java making use of the SDK. The sample supports the OOTB Login Journey with Username and Password. (https://docs.pingidentity.com/sdks/latest/sdks/tutorials/android/index.html)

- [**Kotlin UI prototype - `/kotlin-ui-prototype`**](./kotlin-ui-prototype/)
  
  - An example Android project making full use of the Android SDK with a prototyping UI, written in Kotlin. Allows to explore the SDK uses in detail with example calls for running Journeys, getting OAuth2.0 tokens, User Info and more. 
  (https://docs.pingidentity.com/sdks/latest/sdks/tutorials/android/index.html)

### OIDC Login:

- [**Kotlin Central Login OIDC - `/kotlin-central-login-oidc`**](./kotlin-central-login-oidc/)
  - A sample app
    that demonstrates the functionality
    of using the Ping SDK for Android for OIDC (redirect) authentication.
    Can be used with PingOne Advanced Identity Cloud,
    PingOne, PingOne DaVinci (via a PingOne application),
    PingAM, and PingFederate.
    (https://docs.pingidentity.com/sdks/latest/oidc/index.html)

## Requirements

- Latest Android Studio
- Java 17+
- Gradle 8.6+
- Ping Advanced Identity Cloud or Ping AM 7.1 and above
- Android API level 23+

## License

This software may be modified and distributed under the terms of the MIT license. See the LICENSE file for details.

© Copyright 2024-2026 Ping Identity Corporation. All rights reserved.