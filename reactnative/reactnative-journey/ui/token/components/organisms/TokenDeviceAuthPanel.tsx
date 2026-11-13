/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import React from 'react';
import TokenActionsCard from '../molecules/TokenActionsCard';
import TokenOutputCard from '../molecules/TokenOutputCard';

type Props = {
  tokenOutput: string;
  loading: boolean;
  onAccessToken: () => void;
  onRefresh: () => void;
  onRevoke: () => void;
  onClear: () => void;
};

/** Renders token actions for the Device Authorization Grant session. */
export default function TokenDeviceAuthPanel({
  tokenOutput,
  loading,
  onAccessToken,
  onRefresh,
  onRevoke,
  onClear,
}: Props): React.ReactElement {
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
