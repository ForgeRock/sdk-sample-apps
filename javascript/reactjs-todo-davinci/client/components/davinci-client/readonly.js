/*
 * ping-sample-web-react-davinci
 *
 * readonly.js
 *
 * Copyright (c) 2025 - 2026 Ping Identity Corporation. All rights reserved.
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import React from 'react';
import { interpolateRichContent } from '../utilities/rich-content';

export default function ReadOnly({ collector }) {
  const collectorType = collector.type;
  const output = collector.output;

  if (collectorType === 'ReadOnlyCollector') {
    return (
      <>
        {/* Display agreement title if it exists */}
        {output.title && <h3>{output.title}</h3>}
        <p>{output.content}</p>
      </>
    );
  } else if (collectorType === 'RichTextCollector') {
    const { richContent } = output;

    if (!richContent?.replacements?.length) {
      return <p>{output.content}</p>;
    }

    return <p>{interpolateRichContent(richContent)}</p>;
  } else {
    return null;
  }
}
