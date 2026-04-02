<p align="center">
  <a href="https://github.com/ForgeRock/sdk-sample-apps">
    <img src="https://www.pingidentity.com/content/dam/picr/nav/Ping-Logo-2.svg" alt="Ping Identity Logo">
  </a>
  <hr/>
</p>

## Samples

_Ping provides these samples to help demonstrate SDK functionality/implementation. They are provided "as is" and are not official products of Ping and are not officially supported._

The Ping SDK for JavaScript enables you to integrate your SPA with our services.

There are two UI deployment options:
- Embedded:
  - With this option, each app has to have its own login User Interface (UI).
  - Users  authenticate natively to your application.
- OIDC (Redirect) Login:
  - Often referred to as centralized login, with this option you reuse a central UI (such as hosted pages for PingOne Advanced Identity Cloud or the Login Widget for PingOne/PingOne DaVinci) your own web application for login requests in multiple apps and sites.
  - User's are redirected via a browser to a central place for authentication.

We provide samples that demonstrate both methods.


### Integrate with PingOne Advanced Identity Cloud / PingAM:

- [**React Todo Journey - `reactjs-todo-journey`**](./reactjs-todo-journey/README.md)

  - Todo application that involves authentication and authorization of a user to post Todos with the `@forgerock/journey-client` and `@forgerock/oidc-client` packages in ReactJS.
    This sample is focused on embedded journey login patterns, including callback-rich experiences such as WebAuthN and social login.

### Integrate with PingOne DaVinci:

- [**React Todo DaVinci - `reactjs-todo-davinci`**](./reactjs-todo-davinci/README.md)

  - Todo application that involves authentication and authorization of a user to post Todos with the `@forgerock/davinci-client` and `@forgerock/oidc-client` packages in ReactJS.
  Demonstrates handling DaVinci flows and collectors.

### OIDC Login:

- [**React Todo OIDC - `reactjs-todo-oidc`**](./reactjs-todo-oidc/README.md)

  - React todo sample app for centralized OIDC login using the current OIDC client patterns and the `@forgerock/oidc-client` package.

## Documentation

Detailed [documentation](https://docs.pingidentity.com/sdks) is provided, and includes topics such as:

- Tutorial walkthroughs for each server
- Integrating functionality such as PingOne Protect, WebAuthn, and more
- Code snippets
- API Reference documentation

## Requirements

JavaScript
- Please use a modern web browser like Chrome, Safari, or Firefox
- Node >= 18
