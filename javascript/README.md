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

To try out the Ping JavaScript SDK please look at one of our samples:

- [**Embedded login - `embedded-login`**](./embedded-login/README.md)

  - A barebones example of how to use the `@forgerock/javascript-sdk` in a vanilla html & javascript app with embedded login. The sample supports the OOTB Login Journey with Username and Password.

- [**React Todo - `reactjs-todo`**](./reactjs-todo/README.md)

  - Todo application that involves authentication and authorization of a user to post Todos with the `@forgerock/javascript-sdk` in ReactJS.
    The main branch includes many flavors of callbacks, including WebAuthN, embedded login, and social login.

- [**Angular Todo - `angular-todo`**](./angular-todo/README.md)
  
  - Todo application that involves authentication and authorization of a user to post Todos with the `@forgerock/javascript-sdk` in Angular.
    The main branch includes many flavors of callbacks, including WebAuthN, embedded login, and social login.

### Integrate with flows - PingOne DaVinci:

- [**Embedded Login DaVinci - `embedded-login-davinci`**](./embedded-login-davinci/)

  - This sample app uses the PingOne Sign on With Sessions OOTB in DaVinci environments and found in the marketplace.       Demonstrates use cases such as user authentication, registration, and account recovery.

- [**React Todo DaVinci - `reactjs-todo-davinci`**](./embedded-login-davinci/)

  - Todo application that involves authentication and authorization of a user to post Todos with DaVinci in ReactJS.
  Demonstrates handling DaVinci flows and collectors.

### OIDC Login:

- [**Central login - `central-login-oidc`**](./central-login-oidc/README.md)

  - A barebones example of how to use the `@forgerock/javascript-sdk` in a vanilla html & javascript app with centralized login with AIC/AM or PingOne services(OIDC Login). Configure the server type on the `.env` file. 

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

