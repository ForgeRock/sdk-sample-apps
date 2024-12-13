<p align="center">
  <a href="https://github.com/ForgeRock/sdk-sample-apps">
    <img src="https://cdn.forgerock.com/logo/interim/Logo-PingIdentity-ForgeRock-Hor-FullColor.svg" alt="Ping Identity Logo">
  </a>
  <hr/>
</p>

# Ping SDKs Sample App Using React Native

This repository contains React Native sample apps provided by **Ping Identity** to demonstrate SDK functionality and implementation. These samples are for demonstration purposes only, are provided **"as is"**, and are not official Ping products nor supported by Ping.

The sample app uses a **bridgeless** or **bridging architecture** to integrate **Ping SDKs** with React Native. It relies on the [`../javascript/todo-api/`](../javascript/todo-api/) project for backend storage, specifically for a simple **To-Do** list example.

---

## Requirements

- **Xcode**: Latest version recommended
- **Android Studio**: Latest version recommended
- **Node.js**: Latest version recommended
- **Visual Studio Code**: Latest version recommended
- **PingAM** or **AIC** for authentication

---

## Getting Started

### Step 1: Configuration

> **Note**: Before starting, complete the [React Native Environment Setup](https://reactnative.dev/docs/environment-setup) through the **"Creating a new application"** step.

1. **Configure PingAM/AIC**:
    - Register an **OAuth 2.0 application** for native mobile apps in **PingAM/AIC**. Refer to the official [Server Configuration Guide](https://backstage.forgerock.com/docs/sdks/latest/sdks/serverconfiguration/onpremise/index.html) for more details.

2. **Set Up the Backend**:
    - Configure the `todo-api` `.env` file.
    - Run the backend using:
      ```bash
      npm start --workspace todo-api
      ```

3. **Clone the Repository**:
    ```bash
    git clone https://github.com/ForgeRock/sdk-sample-apps.git
    ```

4. **Open the React Native Project** in Visual Studio Code.

5. **Configure iOS**:
    - Open the `FRAuthSampleBridge.swift` file.
    - Locate `FRAuth.plist` and replace placeholder strings with your **OAuth 2.0 application** details.

6. **Configure Android**:
    - Open the `FRAuthSampleBridge.kt` file.
    - Locate `Strings.xml` and update placeholder strings with your **OAuth 2.0 application** details.

7. **Set API Base URL**:
    - Edit `.env.js` and set `API_BASE_URL` to the IP and port of your `todo-api` backend:
      - For **iOS**: Use `localhost`
      - For **Android**: Use `10.0.2.2`
      ```javascript
      const API_URL = "http://10.0.2.2:9443/todos";
      ```

8. **Run the App**:
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

#### For Android

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
