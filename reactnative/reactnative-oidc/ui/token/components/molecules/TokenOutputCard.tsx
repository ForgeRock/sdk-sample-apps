/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import React from 'react';
import CardSection from '../../../components/molecules/CardSection';
import PayloadViewer from '../../../components/atoms/PayloadViewer';

/**
 * Props for the token output card.
 */
type TokenOutputCardProps = {
  /**
   * Current token/session payload text.
   */
  tokenOutput: string;
  /**
   * Whether to show the "coming soon" badge in the header.
   */
  showComingSoonBadge: boolean;
};

/**
 * Renders token output in a scrollable payload card.
 *
 * @param props - Output card props.
 * @returns Token output card element.
 */
export default function TokenOutputCard(
  props: TokenOutputCardProps,
): React.ReactElement {
  const { tokenOutput, showComingSoonBadge } = props;

  return (
    <CardSection
      title="Token Output"
      badgeText={showComingSoonBadge ? 'COMING SOON' : undefined}
    >
      <PayloadViewer payload={tokenOutput} />
    </CardSection>
  );
}
