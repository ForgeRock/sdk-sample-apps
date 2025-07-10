import React, { useState } from 'react';

export default function SingleSelectComponent({ collector, collectorName, updater }) {
  const [selectedValue, setSelectedValue] = useState('');

  const fieldId = collector.output.key || 'dropdown-field';
  const label = collector.output.label || 'Select an option';

  const handleChange = (event) => {
    const value = event.target.value;
    setSelectedValue(value);
    updater(value);
  };

  return (
    <div className={`mb-5}`} key={collectorName}>
      <label htmlFor={fieldId} className="form-label fw-semibold mt-2 mb-2">
        {label}
      </label>
      <select
        id={fieldId}
        name={fieldId}
        value={selectedValue}
        onChange={handleChange}
        className="form-select form-select-sm mt-2 mb-2"
        required
      >
        <option value="" disabled>
          Choose an option...
        </option>
        {collector.output.options.map((option) => (
          <option key={option.value} value={option.value}>
            {option.label}
          </option>
        ))}
      </select>
    </div>
  );
}
