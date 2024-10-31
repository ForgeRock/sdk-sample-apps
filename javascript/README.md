<p align="center">
  <a href="https://github.com/ForgeRock/sdk-sample-apps">
    <img src="https://cdn.forgerock.com/logo/interim/Logo-PingIdentity-ForgeRock-Hor-FullColor.svg" alt="Logo">
  </a>
  <hr/>
</p>

## Samples

Ping provides these samples to help demonstrate SDK functionality/implementation. They are provided "as is" and are not official products of Ping and are not officially supported.

### Integrate with PingOne Advanced Identity Cloud / PingAM:

To try out the Ping JavaScript SDK please look at one of our samples:

- [**Embedded login - `embedded-login`**](./javascript/embedded-login/README.md)

  - A barebones example of how to use the `@forgerock/javascript-sdk` in a vanilla html & javascript app with embedded login. The sample supports the OOTB Login Journey with Username and Password.

- [**Central login - `central-login-aic`**](./javascript/central-login-aic/README.md)

  - A barebones example of how to use the `@forgerock/javascript-sdk` in a vanilla html & javascript app with centralized login with AIC/AM (OIDC Login). 

- [**React Todo - `reactjs-todo`**](./javascript/reactjs-todo/README.md)

  - Todo application that involves authentication and authorization of a user to post Todos with the `@forgerock/javascript-sdk` in ReactJS.
    The main branch includes many flavors of callbacks, including WebAuthN, embedded login, and social login.

- [**Angular Todo - `angular-todo`**](./javascript/angular-todo/README.md)
  
  - Todo application that involves authentication and authorization of a user to post Todos with the `@forgerock/javascript-sdk` in Angular.
    The main branch includes many flavors of callbacks, including WebAuthN, embedded login, and social login.


### Integrate with PingOne:

 [**Central login PingOne - `central-login-pingone`**](./javascript/central-login-pingone/README.md)

  - A barebones example of how to use the `@forgerock/javascript-sdk` in a vanilla html & javascript app with centralized login with PingOne and Davinci (OIDC Login). 
  
  [Configure the central login sample app](https://docs.pingidentity.com/sdks/latest/sdks/tutorials/javascript/pingone/03_configuring-sample-for-pingone-js.html)

## Documentation

Documentation for the SDKs is provided on [ForgeRock Backstage](https://docs.pingidentity.com/sdks/latest/index.html), and includes topics such as:

- Introducing the SDK Features
- Preparing your server for use with the SDKs
- API Reference documentation

## Requirements

JavaScript
- Please use a modern web browser like Chrome, Safari, or Firefox
- Node >= 18
