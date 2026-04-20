<p align="center">
  <a href="https://github.com/ForgeRock/sdk-sample-apps">
    <img src="https://www.pingidentity.com/content/dam/picr/nav/Ping-Logo-2.svg" alt="Ping Identity Logo">
  </a>
  <hr/>
</p>

# OIDC Android App using Kotlin for PingAM, PingOne Advanced Identity Cloud, PingFederate, PingOne for Customers

This repository contains Android sample applications to demonstrate the functionality and implementation of Ping Identity SDKs for OpenID Connect (OIDC) authentication. These samples support integration with PingAM, PingOne Advanced Identity Cloud, PingFederate, and PingOne for Customers.
- Note: These samples are provided "as is" and are not official Ping Identity products. They are not covered by Ping support agreements.

## Features
- Authentication using OpenID Connect (OIDC)
- Centralized login implementation
- Easy integration with various Ping Identity services
- Modular configuration through Config.kt

## Requirements

- Android Studio: Latest version recommended
- Ping Identity Services:
    Ping AM 7.1 and above
    PingOne Advanced Identity Cloud
    PingFederate
    PingOne for Customers
- Android API Level: 23 (Android 6.0) or higher


## Getting Started

To try out the ForgeRock Android SDK sample, perform these steps:
1. Prepare your Access Management (AM) Instance **[Documentation](https://docs.pingidentity.com/sdks/latest/sdks/configure-your-server.html)**
    Follow the official Ping Identity Documentation to configure your AM instance.

2. Configure Ping Services
    Ensure that your chosen Ping service (AM, PingOne, or PingFederate) is set up to support OIDC workflows.

3. Clone this repo:

    ```
    git clone https://github.com/ForgeRock/sdk-sample-apps.git
    ```
4. Open the Android sample project(kotlin-central-login-oidc) in [Android Studio](https://developer.android.com/studio).
5. Open the `Config.kt` file within the project and modify the PingConfig class to include or remove the necessary fields based on your environment's requirements.
6. Validate the PingConfig.toFROptions() method to map values correctly.
7. Connect an Android device or emulator.
8. On the **Run** menu, click **Run 'app'**.

## Additional Resources
Ping SDK Documentation: https://docs.pingidentity.com/sdks/latest/sdks/index.html

