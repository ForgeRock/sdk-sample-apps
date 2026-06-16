/*
 * ping-sample-web-react-davinci
 *
 * device.js
 *
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import React, { useEffect, useContext, useState } from 'react';
import { ThemeContext } from '../../context/theme.context.js';

export default function DeviceComponent({ collector, updater }) {
  const [selectedDevice, setSelectedDevice] = useState(
    collector.output.options?.[0]?.value ?? null,
  );
  const theme = useContext(ThemeContext);

  useEffect(() => {
    if (selectedDevice) {
      const result = updater(selectedDevice);
      if (result && 'error' in result) {
        console.error('Failed to update device', result.error);
      }
    }
  }, [selectedDevice, updater]);

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
        onChange={(event) => setSelectedDevice(event.target.value)}
      >
        {collector.output.options?.map((option) => (
          <option key={option.value + option.label} value={option.value}>
            {option.label}
          </option>
        ))}
      </select>
      <button type="submit" className="mt-5 justify-content w-100 btn btn-primary">
        Next
      </button>
    </div>
  );
}
