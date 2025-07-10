import {
  InternalErrorResponse,
  ActionCollector,
  SubmitCollector,
} from '@forgerock/davinci-client/types';

export default function submitButtonComponent(
  formEl: HTMLFormElement,
  collector: SubmitCollector,
  updater: () => Promise<void | InternalErrorResponse>,
) {
  const button = document.createElement('button');

  button.type = 'submit';
  button.innerText = collector.output.label;

  formEl?.appendChild(button);
}
