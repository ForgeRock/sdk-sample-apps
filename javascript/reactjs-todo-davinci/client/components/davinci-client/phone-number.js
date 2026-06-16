/*
 * ping-sample-web-react-davinci
 *
 * phone-number.js
 *
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import React, { useState } from 'react';

export default function PhoneNumberComponent({ collector, updater, inputName }) {
  const [phoneValue, setPhoneValue] = useState({
    phoneNumber: collector.input.value?.phoneNumber ?? '',
    extension: collector.input.value?.extension ?? '',
  });

  if (collector.type === 'PhoneNumberCollector') {
    const phoneInputId = `${inputName}-phone-number`;
    const required = collector.input.validation?.some(
      (validation) => validation.type === 'required' && validation.rule === true,
    );

    return (
      <>
        <label htmlFor={phoneInputId} className={'form-label mb-2 mt-2'}>
          {collector.output.label || 'Phone Number'}
        </label>
        <input
          type="text"
          className={'mb-2 mt-2'}
          id={phoneInputId}
          name={phoneInputId}
          placeholder="Enter phone number"
          value={phoneValue.phoneNumber}
          onChange={(event) => {
            const updatedPhone = event.target.value;
            setPhoneValue((prev) => ({ ...prev, phoneNumber: updatedPhone }));
            updater({
              phoneNumber: updatedPhone,
              countryCode: collector.input.value?.countryCode,
            });
          }}
          required={required}
        />
      </>
    );
  } else if (collector.type === 'PhoneNumberExtensionCollector') {
    const phoneInputId = `${inputName}-phone-number`;
    const extensionInputId = `${inputName}-extension`;
    const required = collector.input.validation?.some(
      (validation) => validation.type === 'required' && validation.rule === true,
    );
    return (
      <>
        <label htmlFor={phoneInputId} className={'form-label mb-2 mt-2'}>
          {collector.output.label || 'Phone Number'}
        </label>
        <input
          type="text"
          className={'mb-2'}
          id={phoneInputId}
          name={phoneInputId}
          placeholder="Enter phone number"
          value={phoneValue.phoneNumber}
          onChange={(event) => {
            const updatedPhoneNumber = event.target.value;
            const updatedPhoneValue = { ...phoneValue, phoneNumber: updatedPhoneNumber };
            setPhoneValue(updatedPhoneValue);
            updater({
              phoneNumber: updatedPhoneValue.phoneNumber,
              countryCode: collector.input.value?.countryCode,
              extension: updatedPhoneValue.extension,
            });
          }}
          required={required}
        />
        <label htmlFor={extensionInputId} className={'form-label mb-2 mt-2'}>
          {collector.output.extensionLabel || 'Extension'}
        </label>
        <input
          type="text"
          className={'mb-2'}
          id={extensionInputId}
          name={extensionInputId}
          placeholder="Enter extension"
          value={phoneValue.extension}
          onChange={(event) => {
            const updatedExtension = event.target.value;
            const updatedPhoneValue = { ...phoneValue, extension: updatedExtension };
            setPhoneValue(updatedPhoneValue);
            updater({
              phoneNumber: updatedPhoneValue.phoneNumber,
              countryCode: collector.input.value?.countryCode,
              extension: updatedPhoneValue.extension,
            });
          }}
          required={required}
        />
      </>
    );
  } else {
    return null;
  }
}
