/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import React from 'react';
import { Linking, Text } from 'react-native';
import type { RichContent } from '@ping-identity/rn-davinci';
import { colors } from '../../../../src/styles/colors';

type Props = {
  /** Plain-text fallback when no richContent is provided. */
  text: string;
  /** Optional rich content with link replacements. */
  richContent?: RichContent;
  style?: object;
};

/**
 * Renders a string with optional inline hyperlinks from {@link RichContent}.
 *
 * Splits `richContent.content` on `{{token}}` placeholders and replaces each
 * with a tappable `Text` span that opens `replacement.href` via `Linking`.
 * Falls back to plain `text` when `richContent` is absent.
 */
export default function RichTextLabel({
  text,
  richContent,
  style,
}: Props): React.ReactElement {
  if (!richContent || !richContent.replacements) {
    return <Text style={style}>{text}</Text>;
  }

  const parts = splitRichContent(richContent);

  return (
    <Text style={style}>
      {parts.map((part, index) =>
        part.href ? (
          <Text
            key={index}
            style={linkStyle}
            onPress={() => {
              if (part.href) {
                Linking.openURL(part.href).catch(() => {});
              }
            }}
            accessibilityRole="link"
            accessibilityLabel={part.value}
          >
            {part.value}
          </Text>
        ) : (
          <Text key={index}>{part.value}</Text>
        ),
      )}
    </Text>
  );
}

type ContentPart = { value: string; href?: string };

function splitRichContent(richContent: RichContent): ContentPart[] {
  const { content, replacements } = richContent;
  const parts: ContentPart[] = [];
  const tokenPattern = /\{\{(\w+)\}\}/g;
  let lastIndex = 0;
  let match: RegExpExecArray | null;

  while ((match = tokenPattern.exec(content)) !== null) {
    if (match.index > lastIndex) {
      parts.push({ value: content.slice(lastIndex, match.index) });
    }
    const token = match[1];
    const replacement = replacements[token];
    if (replacement) {
      parts.push({ value: replacement.value, href: replacement.href });
    } else {
      parts.push({ value: match[0] });
    }
    lastIndex = match.index + match[0].length;
  }

  if (lastIndex < content.length) {
    parts.push({ value: content.slice(lastIndex) });
  }

  return parts;
}

const linkStyle = {
  color: colors.primary,
  textDecorationLine: 'underline' as const,
};
