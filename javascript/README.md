<p align="center">
  <a href="https://github.com/ForgeRock/sdk-sample-apps">
    <img src="https://www.pingidentity.com/content/dam/picr/nav/Ping-Logo-2.svg" alt="Ping Identity Logo">
  </a>
  <hr/>
</p>

## Samples

Ping provides these samples to help demonstrate SDK functionality/implementation. They are provided "as is" and are not official products of Ping and are not officially supported.

The Ping SDK for JavaScript enables you to integrate your SPA with our services.
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

 - Coming soon

### OIDC Login:

- [**Central login - `central-login-oidc`**](./central-login-oidc/README.md)

  - A barebones example of how to use the `@forgerock/javascript-sdk` in a vanilla html & javascript app with centralized login with AIC/AM or PingOne services(OIDC Login). Configure the server type on the `.env` file. 

## Documentation

Detailed [documentation](https://docs.pingidentity.com/sdks/latest/sdks/index.html) is provided, and includes topics such as:

- Introducing the SDK features
- Preparing your server for use with the SDKs
- API Reference documentation

## Requirements

JavaScript
- Please use a modern web browser like Chrome, Safari, or Firefox
- Node >= 18

