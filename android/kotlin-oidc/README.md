[![Ping Identity](https://www.pingidentity.com/content/dam/picr/nav/Ping-Logo-2.svg)](https://github.com/ForgeRock/ping-android-sdk)

# OIDC Browser Authentication app using Kotlin

Ping provides these Android samples to help demonstrate SDK functionality/implementation. They are provided "as is" and are not official products of Ping and are not officially supported.

This repository contains an example Android project written in Kotlin making use of the SDK. The sample demonstrates OIDC Centralized Login using browser-based authentication, and Rich Authorization Requests (RFC 9396) on PingAM or Advanced Identity Cloud.

# Introduction

This sample application demonstrates how to integrate the Android SDK into a basic application. The sample app includes examples of the following:


- Centralized Login: Implements a secure, browser-based authentication flow using OAuth 2.0 and PKCE

- Displaying authenticated user status.

- Displaying authenticated token.

- Rich Authorization Requests (RFC 9396): a dedicated login screen with editable `authorization_details` JSON and presets, a PAR toggle, and a "Granted Authorization Details" card on the RAR token screen (see [Rich Authorization Requests (RFC 9396)](#rich-authorization-requests-rfc-9396)).

- Ability to logout existing user and restart the login flow.

- Built with modern Android components (Jetpack Compose, Kotlin).

## Requirements

- Android Studio: Latest version recommended
- Ping One OR AIC
- Android API Level: 29 (Android 10.0) or higher

## Getting Started

To try out the OIDC Android SDK sample, perform these steps:
1. Configure Ping Services
   Ensure that you registered an OAuth 2.0 application for native mobile apps in PingOne. More details in this [documentation](https://backstage.forgerock.com/docs/sdks/latest/sdks/serverconfiguration/pingone/create-oauth2-client.html).

2. Clone this repo:

    ```
    git clone https://github.com/ForgeRock/sdk-sample-apps.git
    ```
3. Open the Android sample project (kotlin-oidc) in [Android Studio](https://developer.android.com/studio).
4. Open the `CentralizeLoginViewModel.kt` file within the project.
5. Locate the TODO and replace the placeholder strings in the Oidc module configuration with the values of your registered OAuth 2.0 application.
6. Go to `oidc\build.gradle.kts` and update the value of `appRedirectUriScheme` with the redirect URI schema from your OIDC configuration.
7. Connect an Android device or emulator.
8. On the **Run** menu, click **Run 'app'**.

## Additional Resources
Ping SDK Documentation: https://docs.pingidentity.com/sdks/latest/sdks/index.html
Ping SDKs for OIDC login: https://docs.pingidentity.com/sdks/latest/oidc/index.html

## Rich Authorization Requests (RFC 9396)

[Rich Authorization Requests (RFC 9396)](https://www.rfc-editor.org/rfc/rfc9396) let a client describe what it is asking the user to approve, instead of encoding the request in flat scopes. The client sends a JSON array of `authorization_details` objects with the authorization request, and the authorization server echoes the details it actually granted back on the token response. The sample demonstrates the full round trip on the **RAR Login** screen:

1. Pick a preset (`payment_initiation`, `account_information`, or a blank custom entry) or edit the `authorization_details` JSON directly. `RarJson.kt` validates the text and reports the first problem found in plain language.
2. Choose how the details are delivered and whether PAR is on.
3. Log in through the dedicated RAR client and inspect the granted details on the **RAR Access Token** screen.

> **Server support:** The RAR screens require PingAM or PingOne Advanced Identity Cloud. PingOne does not currently support the PAR-based RAR flow demonstrated here. On Advanced Identity Cloud, release 23604.0 or later is required.

### Delivery Paths

`authorization_details` can reach the authorization server two ways; both use the SDK's typed `authorizationDetails` API:

- **Per transaction** (`Parameters.authorizationDetails(...)`): the details travel with a single `authorize` call and are sent for that login only:

    ```kotlin
    val result = RarClientStore.client.authorize {
        authorizationDetails(details)
    }
    ```

- **Client config** (`OidcClientConfig.authorizationDetails`): the details are fixed on the client configuration and sent with every authorization made by that client.

A per-transaction value takes precedence over a config-level one. The **Delivery** picker on the RAR Login screen selects between the two.

### Pushed Authorization Requests (PAR) for RAR flows

With [Pushed Authorization Requests (RFC 9126)](https://www.rfc-editor.org/rfc/rfc9126), the authorization parameters are sent to the server in a POST to the discovery document's `pushed_authorization_request_endpoint` before the browser redirect, and the redirect carries only the resulting `request_uri`. The **PAR** toggle on the RAR Login screen sets `par` on the client configuration.

- Toggling PAR rebuilds the RAR client (`RarClientStore.apply(...)`), because `par` is fixed when a client is built.
- PAR requires the discovery document to advertise a `pushed_authorization_request_endpoint`. With PAR on and none advertised, the Android SDK fails the login (it does not fall back to the standard flow), unlike the iOS SDK which silently falls back.
- Prefer the typed `authorizationDetails` API over a raw `authorization_details` entry in `additionalParameters`: a per-transaction typed value suppresses both the config-level typed list and a hand-serialized parameter, so the request carries the parameter exactly once.

### Token Storage

The RAR login runs on its own client (`RarClientStore`) that keeps its token in its own storage file, `ACCESS_TOKEN_STORAGE_RAR`, separate from the standard client's: starting an authorization revokes and replaces the token held in the storage of the client that starts it. With separate storage:

- The RAR token and the token from the standard login coexist. Completing a RAR login revokes and replaces only the previous RAR token; the standard token stays valid, and vice versa.
- The two tokens are revoked independently: the **Access Token** screen shows the standard token, and the **RAR Access Token** screen has a **Revoke RAR Token** button that touches only the RAR slot. Logging out on the drawer's Logout item signs out the standard session only.

### Reading the RAR Access Token Screen

The **RAR Access Token** screen shows the token plus a "Granted Authorization Details" card listing each granted object (type, locations, actions, datatypes, privileges, and type-specific fields). The card distinguishes three outcomes:

- **Card populated**: the server processed the request as RAR and granted the listed details.
- **"The token response carried no authorization_details"**: the `authorization_details` member is absent, so the server did not process the request as a Rich Authorization Request (a server that does not support it, or one with RAR not enabled).
- **"The server returned an empty authorization_details array"**: RAR ran, but the consent flow granted nothing — typically the built-in example consent service, which does not echo details (see [server prerequisites](#server-prerequisites-for-rar)).

### The Deny Path

When the user declines the consent screen, the authorization redirect carries `error=access_denied`. The sample maps this to **"Consent was denied. The user declined the authorization request."** rather than a raw SDK error string, alongside readable messages for `invalid_authorization_details`, `invalid_request`, and a dismissed sign-in browser (see `OidcErrorDisplay.kt`).

### Server Prerequisites for RAR

The RAR login runs against PingAM/Advanced Identity Cloud with the following configuration:

1. **OAuth 2.0 provider**: Enable **Remote Consent** and **Enable Rich Authorization Requests with Remote Consent Service**. With either setting off, the provider silently ignores `authorization_details`.
2. **Two OAuth 2.0 clients** — the sample authenticates as two clients, because consent handling is a per-client setting:
    - **Standard client** (the `clientId` placeholder in `CentralizeLoginViewModel.kt`): grant type **Authorization Code** with PKCE, and **Implied Consent** on so the plain login does not stop at a consent prompt.
    - **RAR client** (the `RAR Client ID` placeholder in `RarClientStore.kt`): grant type **Authorization Code** with PKCE, **Implied Consent off** — implied consent with `authorization_details` is rejected with `invalid_request` — and every `type` you will request listed under **Authorization Detail Type(s)**, since a request for an unlisted type is rejected with `invalid_authorization_details`.
3. **Remote Consent Service**: Enable remote consent for the RAR client's flow and configure a Remote Consent Service that returns the granted `authorization_details`. The built-in example consent service does not return `authorization_details`, so a login against it completes with an empty array on the token — use a custom consent service to see populated cards on the RAR Access Token screen. The [RCS demo](../../rcs/rcs-demo/README.md) in this repository is a ready-made consent service for this purpose.