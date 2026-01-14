import type { InternalErrorResponse, IdpCollector } from '@forgerock/davinci-client/types';

export default function idpCollectorButton(
  formEl: HTMLFormElement,
  collector: IdpCollector,
  updater: () => Promise<void | InternalErrorResponse>,
) {
  const button = document.createElement('button');
  button.value = collector.output.label;
  button.innerHTML = collector.output.label;
  button.onclick = async () => {
    await updater();
    window.location.assign(collector.output.url);
  };

  formEl?.appendChild(button);
}
