<p align="center">
  <a href="https://github.com/ForgeRock/sdk-sample-apps">
    <img src="https://cdn.forgerock.com/logo/interim/Logo-PingIdentity-ForgeRock-Hor-FullColor.svg" alt="Ping Identity Logo">
  </a>
  <hr/>
</p>

# Ping SDKs Sample App Using React Native

This repository contains React Native sample apps provided by **Ping Identity** to demonstrate SDK functionality and implementation. These samples are for demonstration purposes only, are provided **"as is"**, and are not official Ping products nor supported by Ping.

The sample app uses a **bridging architecture** to integrate **Ping SDKs** with React Native. you can also modify the code to use  **bridgeless** architecture as well. The apps rely on the  [`../javascript/todo-api/`](../javascript/todo-api/) project for backend storage, specifically for a simple **To-Do** list example.

---

## Requirements

- **Xcode**: Latest version recommended
- **Android Studio**: Latest version recommended with Java 17
- **Node.js**: >= 18
- **Visual Studio Code**: Latest version recommended
- **PingAM** or **AIC** for authentication

---

## Getting Started

### Step 1: Configuration

> **Note**: Before starting, complete the [React Native Environment Setup](https://reactnative.dev/docs/environment-setup) through the **"Creating a new application"** step.

1. **Configure PingAM/AIC**:
    - Register an **OAuth 2.0 application** for native mobile apps in **PingAM/AIC**. Refer to the official [Server Configuration Guide](https://docs.pingidentity.com/sdks/latest/sdks/configure-your-server.html) for more details.

2. **Clone the Repository**:
    ```bash
    git clone https://github.com/ForgeRock/sdk-sample-apps.git
    ```

3. **Open the React Native Project** in Visual Studio Code.

4. **Set Up the Backend**:
    - Configure the [`../javascript/todo-api/`](../javascript/todo-api/) `.env` file.
    - This todo Api will introspect the token sent from the reactnative application
    - Run the backend using:
      ```bash
      cd sdk-sample-apps/javascript
      npm start --workspace todo-api
      ```

5. **Set API Base URL in the React Native Project to connect your ToDo Backend**:
   - Edit `.env.js` and set `API_BASE_URL` and `API_PORT` to connect your backend.
     - For example:
     - **iOS**: Use `http://localhost`  for running in Simulator 
     - **Android**: Use `http://10.0.2.2`  for running in Emulator
     ```javascript
     const API_BASE_URL = "http://10.0.2.2";
     const API_PORT = 9443;
     ```

6. **Configure iOS and Android**:
   - **iOS**: Update `Configuration.swift` with your **OAuth 2.0** details.  
   - **Android**: Update `Configuration.kt` with your **OAuth 2.0** details.
  
### Example Configuration Variables for Android/iOS

Update the following environment variables in `configuration.kt` for Android and `configuration.swift` for iOS dynamically:

| Variable                         | Description                                    | Example Value for iOS/Android                                      |
|-----------------------------------|------------------------------------------------|----------------------------------------------------|
| `oauthClientId`          | OAuth 2.0 Client ID                            | `AndroidTest` / `iOSClient`                        |
| `oauthRedirectURI`       | OAuth 2.0 Redirect URI                         | `org.ping.demo:/oauth2redirect` / `myapp://oauth2redirect` |
| `amURL`                      | PingAM Instance URL                            | `https://openam-xvc.forgeblock.com/am`             |
| `cookieName`              | PingAM Cookie Name                             | `5421aeddf91aa20`                                  |
| `realm`                    | PingAM Realm                                   | `alpha`                                            |
| `mainAuthenticationJourney`             | Authentication Service Name                    | `webAuthn`                                         |
| `registrationServiceName`     | Registration Service Name                      | `registration`                                     |

---

7. **Run the App**:
    - Launch on an **iOS device/simulator** or **Android device/emulator**.

### Step 2: Start the Metro Server

First, you will need to start **Metro**, the JavaScript _bundler_ that ships _with_ React Native.

To start Metro, run the following command from the _root_ of your React Native project:

```bash
# using npm
npm start

# OR using Yarn
yarn start
```

### Step 3: Start your Application

Let Metro Bundler run in its _own_ terminal. Open a _new_ terminal from the _root_ of your React Native project. Run the following command to start your _Android_ or _iOS_ app:

### For Android

```bash
# using npm
npm run android

# OR using Yarn
yarn android
```

### For iOS

```bash
# using npm
npm run ios

# OR using Yarn
yarn ios
```

If everything is set up _correctly_, you should see your new app running in your _Android Emulator_ or _iOS Simulator_ shortly provided you have set up your emulator/simulator correctly.

This is one way to run your app — you can also run it directly from within Android Studio and Xcode respectively.

### Step 4: Modifying your App

Now that you have successfully run the app, let's modify it.

1. Open `App.tsx` in your text editor of choice and edit some lines.
2. For **Android**: Press the <kbd>R</kbd> key twice or select **"Reload"** from the **Developer Menu** (<kbd>Ctrl</kbd> + <kbd>M</kbd> (on Window and Linux) or <kbd>Cmd ⌘</kbd> + <kbd>M</kbd> (on macOS)) to see your changes!

   For **iOS**: Hit <kbd>Cmd ⌘</kbd> + <kbd>R</kbd> in your iOS Simulator to reload the app and see your changes!

## Congratulations! :tada:

You've successfully run and modified your React Native App. 

### Now what?

- If you want to add this new React Native code to an existing application, check out the [Integration guide](https://reactnative.dev/docs/integration-with-existing-apps).
- If you're curious to learn more about React Native, check out the [Introduction to React Native](https://reactnative.dev/docs/getting-started).

# Troubleshooting

If you can't get this to work, see the [Troubleshooting](https://reactnative.dev/docs/troubleshooting) page.

# Learn More

To learn more about React Native, take a look at the following resources:

- [React Native Website](https://reactnative.dev) - learn more about React Native.
- [Getting Started](https://reactnative.dev/docs/environment-setup) - an **overview** of React Native and how setup your environment.
- [Learn the Basics](https://reactnative.dev/docs/getting-started) - a **guided tour** of the React Native **basics**.
- [Blog](https://reactnative.dev/blog) - read the latest official React Native **Blog** posts.
- [`@facebook/react-native`](https://github.com/facebook/react-native) - the Open Source; GitHub **repository** for React Native.
