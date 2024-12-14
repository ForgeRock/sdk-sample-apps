<p align="center">
  <a href="https://github.com/ForgeRock/sdk-sample-apps">
    <img src="https://www.pingidentity.com/content/dam/picr/nav/Ping-Logo-2.svg" alt="Ping Identity Logo">
  </a>
  <hr/>
</p>

## Samples

Ping provides these Android samples to help demonstrate SDK functionality/implementation. They are provided "as is" and are not official products of Ping and are not officially supported.

The Ping SDK for Android enables you to integrate your SPA with our services.
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

- Coming soon

### OIDC Login:

- Coming soon

## Documentation

Detailed [documentation](https://docs.pingidentity.com/sdks/latest/sdks/index.html) is provided, and includes topics such as:

- Introducing the SDK features
- Preparing your server for use with the SDKs
- API Reference documentation

## Requirements

- Latest Android Studio
- Java 17+
- Gradle 8.6+
- Ping Advanced Identity Cloud or Ping AM 7.1 and above
- Android API level 23+
