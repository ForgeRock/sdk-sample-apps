/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import type {
  JourneyFormValue,
  JourneyNormalizedField,
} from '@ping-identity/rn-journey';

/**
 * Common props for all Journey callback field renderer components.
 */
export type JourneyFieldRendererProps = {
  field: JourneyNormalizedField;
  currentValue: JourneyFormValue | undefined;
  setFieldValue: (fieldId: string, value: JourneyFormValue) => void;
  onSelectIdpProvider?: (fieldId: string, provider: string) => Promise<void>;
};
