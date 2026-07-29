/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import React from 'react';
import TokenActionsCard from '../molecules/TokenActionsCard';
import TokenOutputCard from '../molecules/TokenOutputCard';

/**
 * Props for the OIDC token panel.
 */
type TokenOidcPanelProps = {
  /**
   * Current token/session payload text.
   */
  tokenOutput: string;
  /**
   * Whether token actions are currently running.
   */
  loading: boolean;
  /**
   * Trigger access-token retrieval.
   */
  onAccessToken: () => void;
  /**
   * Trigger token refresh.
   */
  onRefresh: () => void;
  /**
   * Trigger token revoke.
   */
  onRevoke: () => void;
  /**
   * Clear currently displayed output.
   */
  onClear: () => void;
};

/**
 * Renders OIDC token output and actions.
 *
 * @param props OIDC token panel props.
 * @returns OIDC token panel element.
 */
export default function TokenOidcPanel(
  props: TokenOidcPanelProps,
): React.ReactElement {
  const { tokenOutput, loading, onAccessToken, onRefresh, onRevoke, onClear } =
    props;

  return (
    <>
      <TokenOutputCard tokenOutput={tokenOutput} showComingSoonBadge={false} />
      <TokenActionsCard
        loading={loading}
        onAccessToken={onAccessToken}
        onRefresh={onRefresh}
        onRevoke={onRevoke}
        onClear={onClear}
      />
    </>
  );
}
