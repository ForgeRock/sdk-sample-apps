[![Ping Identity](https://www.pingidentity.com/content/dam/picr/nav/Ping-Logo-2.svg)](https://github.com/ForgeRock/sdk-sample-apps)

> [!IMPORTANT]
> **The applications contained in this folder are no longer supported and will not receive any further feature updates. These applications were built solely to demonstrate features of the legacy ForgeRock SDK 4.x.**
>
>**The ForgeRock SDK v4.x entered a maintenance-only phase on April 15, 2026, and its end-of-support is scheduled for April 15, 2028. During this period, the SDK will only receive critical bug fixes and security updates.**

## Recommended Action: Migrate to Ping Orchestration SDK v2.x

We strongly recommend migrating to the Ping Orchestration SDK v2.x. New sample applications and [migration guides](https://developer.pingidentity.com/orchsdks/journey/migration.html) are available to assist with this transition.

Adopting the latest Ping Orchestration SDK ensures the security, compatibility, and stability of your solutions, offering improved features, enhanced performance, and continued support from Ping.

# React Native Samples

_This repository contains React Native sample apps provided by **Ping Identity** to demonstrate SDK functionality and implementation. These samples are for demonstration purposes only, are provided **"as is"**, and are not official Ping products nor supported by Ping._

The sample app uses a **bridging architecture** to integrate **Ping SDKs** with React Native. You can modify the code to use  **bridgeless** architecture as well. The apps rely on the  [`../javascript/todo-api/`](../javascript/todo-api/) project for backend storage, specifically for a simple **To-Do** list example.

### Integrate with PingOne Advanced Identity Cloud / PingAM:

To try out the Ping iOS and Android SDKs in a Flutter application please look at the following sample:

- [**ToDo - `/reactnative-todo/`**](./reactnative-todo/)
  
  - An example React Native project making use of the iOS and Android SDKs to demonstrate the use of the Native SDKs on a Hybrid framework like React Native with a use of a bridging layer. The app makes use of the [`../javascript/todo-api/`](../javascript/todo-api/) project as a backend storage mechanism for the `To-Do` list.

## Requirements

- **Xcode**: Latest version recommended
- **Android Studio**: Latest version recommended with Java 17
- **Node.js**: >= 18
- **Visual Studio Code**: Latest version recommended
- **PingAM** or **AIC** for authentication

## License

This software may be modified and distributed under the terms of the MIT license. See the LICENSE file for details.

© Copyright 2024-2026 Ping Identity Corporation. All rights reserved.