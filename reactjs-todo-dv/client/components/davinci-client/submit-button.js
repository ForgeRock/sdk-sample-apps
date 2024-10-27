/*
 * forgerock-sample-web-react
 *
 * submit-button.js
 *
 * Copyright (c) 2021 ForgeRock. All rights reserved.
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */
import React from 'react';

export default function SubmitButton({ collector }) {
  return (
    <button
      type="submit"
      className="btn btn-primary w-100 mb-2"
      value={collector.output.key}
      key={collector.output.key}
    >
      <span>{collector.output.label}</span>
    </button>
  );
}
