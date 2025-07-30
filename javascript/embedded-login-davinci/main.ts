import './style.css';

import { Config, FRUser, TokenManager } from '@forgerock/javascript-sdk';
import { davinci } from '@forgerock/davinci-client';

import usernameComponent from './components/text.js';
import passwordComponent from './components/password.js';
import submitButtonComponent from './components/submit-button.js';
import protect from './components/protect.js';
import flowLinkComponent from './components/flow-link.js';
import idpCollectorButton from './components/social-login-button.js';
import { InternalErrorResponse, NodeStates } from '@forgerock/davinci-client/types';

console.log(import.meta.env);

const config = {
  clientId: import.meta.env.VITE_WEB_OAUTH_CLIENT,
  redirectUri: window.location.origin + '/',
  scope: 'openid profile email name revoke',
  serverConfig: {
    wellknown: import.meta.env.VITE_WELLKNOWN_URL,
  },
};

const urlParams = new URLSearchParams(window.location.search);
const continueToken = urlParams.get('continueToken');

(async () => {
  const formEl = document.getElementById('form') as HTMLFormElement;
  const davinciClient = await davinci({ config });
  let resumed: NodeStates | InternalErrorResponse | undefined;

  if (continueToken) {
    resumed = await davinciClient.resume({ continueToken });
  }
  await Config.setAsync(config);

  if (davinciClient) {
    davinciClient.subscribe(() => {
      const client = davinciClient.getClient();
      console.log('Event emitted from observable:', client);
    });
  }

  function renderComplete() {
    const clientInfo = davinciClient.getClient();
    const serverInfo = davinciClient.getServer();

    let code = '';
    let session = '';
    let state = '';

    if (clientInfo?.status === 'success') {
      code = clientInfo.authorization?.code || '';
      state = clientInfo.authorization?.state || '';
    }

    if (serverInfo && serverInfo.status === 'success') {
      session = serverInfo.session || '';
    }

    let tokens;

    formEl.innerHTML = `
      <h2>Complete</h2>
      <pre>Session: ${session}</pre>
      <pre>Authorization: ${code}</pre>
      <pre>Access Token:</pre>
      <pre
        id="accessToken"
        style="display: block; max-width: 400px; text-wrap: wrap; overflow-wrap: anywhere;"
      >
        --
      </pre>
      <button type="button" id="tokensButton">Get Tokens</button><br />
      <button type="button" id="logoutButton">Logout</button>
    `;

    const tokenBtn = document.getElementById('tokensButton') as HTMLButtonElement;

    tokenBtn.addEventListener('click', async () => {
      tokens = await TokenManager.getTokens({ query: { code, state } });

      console.log(tokens);

      const tokenPreEl = document.getElementById('accessToken') as HTMLPreElement;

      tokenPreEl.innerText = tokens?.accessToken || '';
    });

    const loginBtn = document.getElementById('logoutButton') as HTMLButtonElement;

    loginBtn.addEventListener('click', async () => {
      await FRUser.logout({ logoutRedirectUri: window.location.href });

      window.location.reload();
    });
  }

  function renderError() {
    const error = davinciClient.getError();

    formEl.innerHTML = `
      <h2>Error</h2>
      <pre>${error?.message}</pre>
    `;
  }

  async function renderForm() {
    formEl.innerHTML = '';
    let formName = '';

    const clientInfo = davinciClient.getClient();

    if (clientInfo?.status === 'continue') {
      formName = clientInfo.name || '';
    }

    const header = document.createElement('h2');
    header.innerText = formName || '';
    formEl.appendChild(header);

    const collectors = davinciClient.getCollectors();
    collectors.forEach((collector) => {
      if (collector.type === 'TextCollector' && collector.name === 'protectsdk') {
        protect(formEl, collector, davinciClient.update(collector));
      } else if (collector.type === 'TextCollector') {
        usernameComponent(formEl, collector, davinciClient.update(collector));
      } else if (collector.type === 'PasswordCollector') {
        passwordComponent(formEl, collector, davinciClient.update(collector));
      } else if (collector.type === 'SubmitCollector') {
        submitButtonComponent(formEl, collector);
      } else if (collector.type === 'IdpCollector') {
        idpCollectorButton(formEl, collector, davinciClient.externalIdp());
      } else if (collector.type === 'FlowCollector') {
        flowLinkComponent(
          formEl,
          collector,
          davinciClient.flow({ action: collector.output.key }),
          renderForm,
        );
      }
    });

    if (davinciClient.getCollectors().find((collector) => collector.name === 'protectsdk')) {
      mapRenderer(await davinciClient.next());
    }
  }

  function mapRenderer(node) {
    if (node.status === 'continue') {
      renderForm();
    } else if (node.status === 'success') {
      renderComplete();
    } else if (node.status === 'error') {
      renderError();
    } else {
      console.error('Unknown node status', node);
    }
  }

  formEl.addEventListener('submit', async (event) => {
    event.preventDefault();

    mapRenderer(await davinciClient.next());
  });

  if (continueToken) {
    mapRenderer(resumed);
    resumed = null;
  } else {
    mapRenderer(await davinciClient.start());
  }
})();
