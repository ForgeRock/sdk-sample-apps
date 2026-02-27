/*
 * ping-sample-web-react-davinci
 *
 * flow-link.js
 *
 * Copyright (c) 2025 - 2026 Ping Identity Corporation. All rights reserved.
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */
import React from 'react';
import { Link } from 'react-router-dom';

export default function FlowLink({ collector, startNewFlow }) {
  return (
    <Link
      to="#"
      className="mb-2 d-flex flex-row justify-content-center"
      onClick={() => startNewFlow(collector)}
    >
      {collector.output.label}
    </Link>
  );
}
