/*
 * UserInfo.tsx
 *
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */
import type { UserInfoResponse } from '@forgerock/oidc-client/types';

export default function UserInfo({ user }: { user: UserInfoResponse | null }) {
  if (!user) {
    return <div>No user information available</div>;
  }

  return (
    <div className="user-info">
      <h3>User Information</h3>
      <ul>
        {Object.entries(user).map(([key, value]) => (
          <li key={key}>
            <strong>{key}:</strong> {String(value)}
          </li>
        ))}
      </ul>
    </div>
  );
}
