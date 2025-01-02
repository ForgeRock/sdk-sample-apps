<p align="center">
  <a href="https://github.com/ForgeRock/sdk-sample-apps">
    <img src="https://www.pingidentity.com/content/dam/picr/nav/Ping-Logo-2.svg" alt="Ping Identity Logo">
  </a>
  <hr/>
</p>

## Samples

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


### Integrate with flows - PingOne DaVinci:

- [**Kotlin DaVinci - `/kotlin-davinci`**](./kotlin-davinci/)
  - An example Android project making use of the OOTB PingOne Sign on With Sessions flow in DaVinci environments and found in the marketplace.       Demonstrates use cases such as user authentication, registration, and account recovery.

    (https://docs.pingidentity.com/sdks/latest/davinci/tutorials/android/index.html)

### OIDC Login:

- [**Kotlin Central Login OIDC - `/kotlin-central-login-oidc`**](./kotlin-central-login-oidc/)
  - A sample app
    that demonstrates the functionality
    of using the Ping SDK for Android for OIDC (redirect) authentication.
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

- Latest Android Studio
- Java 17+
- Gradle 8.6+
- Ping Advanced Identity Cloud or Ping AM 7.1 and above
- Android API level 23+
