/*
 * ping-sample-web-react-davinci
 *
 * object-value.js
 *
 * Copyright (c) 2025 - 2026 Ping Identity Corporation. All rights reserved.
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import React, { useEffect, useContext, useState } from 'react';
import { ThemeContext } from '../../context/theme.context.js';

export default function ObjectValueComponent({ collector, updater, inputName }) {
  const [selectedDevice, setSelectedDevice] = useState(
    collector.output.options?.[0]?.value ?? null,
  );
  const [phoneValue, setPhoneValue] = useState({
    phoneNumber: collector.input.value?.phoneNumber ?? '',
    extension: collector.input.value?.extension ?? '',
  });
  const theme = useContext(ThemeContext);

  useEffect(() => {
    if (
      collector.type === 'DeviceAuthenticationCollector' ||
      collector.type === 'DeviceRegistrationCollector'
    ) {
      updater(selectedDevice);
    }
  }, [selectedDevice, updater, collector.type]);

  const handleChangeDevice = (event) => {
    event.preventDefault();
    setSelectedDevice(event.target.value);
  };
  if (
    collector.type === 'DeviceAuthenticationCollector' ||
    collector.type === 'DeviceRegistrationCollector'
  ) {
    return (
      <div className="d-flex flex-column align-items-center mt-2 mb-2">
        <label
          htmlFor="device-select"
          className={`form-label cstm_subhead-text mb-4 fw-bold text-center ${theme.textMutedClass}`}
        >
          {collector.output.label || 'select an option'}
        </label>
        <select
          id="device-select"
          className="form-select form-select-lg w-100"
          value={selectedDevice}
          onChange={handleChangeDevice}
        >
          {collector.output.options.map((option) => (
            <option key={option.value + option.label} value={option.value}>
              {option.label}
            </option>
          ))}
        </select>
        <button className="mt-5 justify-content w-100 btn btn-primary">Next</button>
      </div>
    );
  } else if (collector.type === 'PhoneNumberCollector') {
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
    return null; // Or handle other collector types, if applicable
  }
}
