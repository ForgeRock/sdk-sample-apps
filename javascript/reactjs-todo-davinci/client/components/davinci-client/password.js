/*
 * ping-sample-web-react-davinci
 *
 * password.js
 *
 * Copyright (c) 2025 - 2026 Ping Identity Corporation. All rights reserved.
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */
import React, { useState, useContext } from 'react';
import { ThemeContext } from '../../context/theme.context.js';
import EyeIcon from '../icons/eye-icon';

const UPPERCASE_RE = /^[A-Z]+$/;
const LOWERCASE_RE = /^[a-z]+$/;
const DIGIT_RE = /^[0-9]+$/;

function buildRequirements(validation) {
  const items = [];

  if (validation.length) {
    const { min, max } = validation.length;
    if (min != null && max != null) {
      items.push(`${min}–${max} characters`);
    } else if (min != null) {
      items.push(`At least ${min} characters`);
    } else if (max != null) {
      items.push(`At most ${max} characters`);
    }
  }

  if (validation.minCharacters) {
    for (const [charset, count] of Object.entries(validation.minCharacters)) {
      if (UPPERCASE_RE.test(charset)) {
        items.push(`At least ${count} uppercase letter(s)`);
      } else if (LOWERCASE_RE.test(charset)) {
        items.push(`At least ${count} lowercase letter(s)`);
      } else if (DIGIT_RE.test(charset)) {
        items.push(`At least ${count} number(s)`);
      } else {
        items.push(`At least ${count} special character(s)`);
      }
    }
  }

  return items;
}

const Password = ({ collector, inputName, updater, validator, verify }) => {
  const theme = useContext(ThemeContext);
  const [isPrimaryVisible, setPrimaryVisible] = useState(false);
  const [isConfirmVisible, setConfirmVisible] = useState(false);
  const [validationErrors, setValidationErrors] = useState([]);
  const [confirmValue, setConfirmValue] = useState('');
  const [confirmError, setConfirmError] = useState('');
  const [primaryValue, setPrimaryValue] = useState('');

  const passwordLabel = collector.output.label;
  const isValidated = collector.type === 'ValidatedPasswordCollector';
  const requirements =
    isValidated && collector.input.validation ? buildRequirements(collector.input.validation) : [];

  function handlePrimaryChange(e) {
    const value = e.target.value;
    setPrimaryValue(value);

    if (validator) {
      const errors = validator(value);
      setValidationErrors(errors);
    }

    const result = updater(value);
    if (result && result.error) {
      console.error('Error updating password collector:', result.error.message);
    }

    // Keep confirm error in sync as the primary value changes
    if (confirmValue && value !== confirmValue) {
      setConfirmError('Passwords do not match');
    } else if (confirmValue) {
      setConfirmError('');
    }
  }

  function handleConfirmChange(e) {
    const value = e.target.value;
    setConfirmValue(value);
    if (primaryValue && value !== primaryValue) {
      setConfirmError('Passwords do not match');
    } else {
      setConfirmError('');
    }
  }

  return (
    <div>
      {requirements.length > 0 && (
        <ul className="password-requirements">
          {requirements.map((req, i) => (
            <li key={i}>{req}</li>
          ))}
        </ul>
      )}

      <div className="cstm_form-floating input-group form-floating mb-3">
        <input
          className={`cstm_input-password form-control border-end-0 bg-transparent ${theme.textClass} ${theme.borderClass}`}
          id={inputName}
          name={inputName}
          type={isPrimaryVisible ? 'text' : 'password'}
          onChange={handlePrimaryChange}
        />
        <label htmlFor={inputName}>{passwordLabel}</label>
        <button
          className={`cstm_input-icon border-start-0 input-group-text bg-transparent ${theme.textClass} ${theme.borderClass}`}
          onClick={() => setPrimaryVisible(!isPrimaryVisible)}
          type="button"
        >
          <EyeIcon visible={isPrimaryVisible} />
        </button>
      </div>

      {validationErrors.length > 0 && (
        <ul className={`${inputName}-error`}>
          {validationErrors.map((msg, i) => (
            <li key={i}>{msg}</li>
          ))}
        </ul>
      )}

      {verify && (
        <div>
          <div className="cstm_form-floating input-group form-floating mb-3">
            <input
              className={`cstm_input-password form-control border-end-0 bg-transparent ${theme.textClass} ${theme.borderClass}`}
              id={`${inputName}-confirm`}
              name={`${inputName}-confirm`}
              type={isConfirmVisible ? 'text' : 'password'}
              onChange={handleConfirmChange}
            />
            <label htmlFor={`${inputName}-confirm`}>Confirm Password</label>
            <button
              className={`cstm_input-icon border-start-0 input-group-text bg-transparent ${theme.textClass} ${theme.borderClass}`}
              onClick={() => setConfirmVisible(!isConfirmVisible)}
              type="button"
            >
              <EyeIcon visible={isConfirmVisible} />
            </button>
          </div>
          {confirmError && (
            <p className={`${inputName}-confirm-error`} style={{ color: 'red' }}>
              {confirmError}
            </p>
          )}
        </div>
      )}
    </div>
  );
};

export default Password;
