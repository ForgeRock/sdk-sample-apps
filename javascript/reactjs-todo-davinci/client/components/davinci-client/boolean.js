/*
 * ping-sample-web-react-davinci
 *
 * boolean.js
 *
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import React, { useState } from 'react';
import { interpolateRichContent } from '../utilities/rich-content';

export default function BooleanComponent({ collector, inputName, updater }) {
  const [isChecked, setIsChecked] = useState(collector.output.value ?? false);

  const fieldId = collector.output.key || `${inputName}-checkbox-field`;

  const { richContent } = collector.output;
  const label = richContent?.replacements?.length
    ? interpolateRichContent(richContent)
    : collector.output.label || '';

  const required = collector.input.validation?.some(
    (validation) => validation.type === 'required' && validation.rule === true,
  );

  const handleChange = (event) => {
    const value = event.target.checked;
    setIsChecked(value);
    updater(value);
  };

  return (
    <div className={'mb-5 form-check'}>
      <label htmlFor={fieldId} className="form-label">
        {label}
      </label>
      <input
        type="checkbox"
        id={fieldId}
        name={fieldId}
        checked={isChecked}
        onChange={handleChange}
        className="form-check-input"
        required={required}
      />
    </div>
  );
}
