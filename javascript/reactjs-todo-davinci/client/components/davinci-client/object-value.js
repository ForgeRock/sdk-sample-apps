import React, { useContext, useState } from 'react';
import { ThemeContext } from '../../context/theme.context.js';

export default function ObjectValueComponent({ collector, inputName, updater, submitForm }) {
  const [selected, setSelected] = useState(collector.output.options[0].value);
  const theme = useContext(ThemeContext);

  const handleChange = (event) => {
    event.preventDefault();
    setSelected(event.target.value);
    updater(event.target.value);
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
          value={selected}
          onChange={handleChange}
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
    return (
      <>
        <label htmlFor={'form-label phone-number-input'} className={'mb-2 mt-2'}>
          {collector.output.label || 'Phone Number'}
        </label>
        <input
          type="text"
          className={'mb-2 mt-2'}
          id="phone-number-input"
          name="phone-number-input"
          placeholder="Enter phone number"
          onChange={(event) => {
            const selectedValue = event.target.value;
            if (!selectedValue) {
              console.error('No value found for the selected option');
              return;
            }
            updater({ phoneNumber: selectedValue, countryCode: collector.input.value.countryCode });
          }}
        />
      </>
    );
  } else {
    return null; // Or handle other collector types, if applicable
  }
}
