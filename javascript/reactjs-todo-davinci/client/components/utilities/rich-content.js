/*
 * ping-sample-web-react-davinci
 *
 * rich-content.js
 *
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */
import React from 'react';

export function interpolateRichContent(richContent) {
  /**
   * Split the content on `{{key}}` placeholders. Because the regex has a
   * capture group, `split` interleaves results: even indices are literal
   * text, odd indices are replacement keys.
   *
   * Sample rich content:
   * {
   *   "content": "A translatable rich text link to {{link1}}.",
   *   "replacements": [
   *     {
   *       "key": "link1",
   *       "type": "link",
   *       "value": "Ping Identity",
   *       "href": "https://www.pingidentity.com",
   *       "target": "_self"
   *     }
   *   ]
   * }
   */
  const segments = richContent.content.split(/\{\{(\w+)\}\}/);

  // Index replacements by key so each placeholder can be looked up in O(1).
  const replacementMap = new Map(richContent.replacements.map((r) => [r.key, r]));

  return (
    <>
      {segments.map((segment, i) => {
        // Even index → plain text segment. Empty strings render as `null`
        // so React skips them instead of emitting empty text nodes.
        if (i % 2 === 0) {
          return segment || null;
        }

        // Odd index → placeholder key. Only "link" types are currently supported.
        // Skip anything that isn't a link.
        const replacement = replacementMap.get(segment);
        if (replacement?.type !== 'link') {
          return null;
        }

        // For external links, pair `target="_blank"` with `rel="noopener noreferrer"`
        // to prevent the new page from accessing `window.opener`.
        const isBlank = replacement.target === '_blank';
        return (
          <a
            key={i}
            href={replacement.href}
            target={replacement.target}
            rel={isBlank ? 'noopener noreferrer' : undefined}
          >
            {replacement.value}
          </a>
        );
      })}
    </>
  );
}
