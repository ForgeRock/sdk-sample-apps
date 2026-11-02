/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import React, { memo } from 'react';
import DaVinciBooleanField from './DaVinciBooleanField';
import DaVinciDeviceField from './DaVinciDeviceField';
import DaVinciFlowButton from './DaVinciFlowButton';
import DaVinciFidoField from './DaVinciFidoField';
import DaVinciIdpField from './DaVinciIdpField';
import DaVinciLabelField from './DaVinciLabelField';
import DaVinciMultiSelectField from './DaVinciMultiSelectField';
import DaVinciPasswordField from './DaVinciPasswordField';
import DaVinciPhoneNumberField from './DaVinciPhoneNumberField';
import DaVinciPollingField from './DaVinciPollingField';
import DaVinciQrCodeField from './DaVinciQrCodeField';
import DaVinciReadOnlyTextField from './DaVinciReadOnlyTextField';
import DaVinciSingleSelectField from './DaVinciSingleSelectField';
import DaVinciSubmitButton from './DaVinciSubmitButton';
import DaVinciTextField from './DaVinciTextField';
import DaVinciUnsupportedField from './DaVinciUnsupportedField';
import { fidoCollectorType } from '@ping-identity/rn-fido';
import { socialLoginCollectorType } from '@ping-identity/rn-external-idp';
import { protectCollectorType } from '@ping-identity/rn-protect';
import type { DaVinciCollectorRendererProps } from './types';

/**
 * Routes a normalised DaVinci collector to the appropriate molecule.
 *
 * @param props Renderer props.
 * @returns Field element, or `null` when the collector should be hidden.
 */
function DaVinciFieldRenderer(
  props: DaVinciCollectorRendererProps,
): React.ReactElement | null {
  const { collector } = props;

  switch (collector.type) {
    case 'TEXT':
      return <DaVinciTextField {...props} />;
    case 'PASSWORD':
    case 'PASSWORD_VERIFY':
      return <DaVinciPasswordField {...props} />;
    case 'SUBMIT_BUTTON':
      return <DaVinciSubmitButton {...props} />;
    case 'ACTION':
    case 'FLOW_BUTTON':
    case 'FLOW_LINK':
      return <DaVinciFlowButton {...props} />;
    case 'SINGLE_CHECKBOX':
      return <DaVinciBooleanField {...props} />;
    case 'LABEL':
      return <DaVinciLabelField {...props} />;
    case 'READ_ONLY_TEXT':
      return <DaVinciReadOnlyTextField {...props} />;
    case 'SINGLE_SELECT':
    case 'DROPDOWN':
    case 'RADIO':
      return <DaVinciSingleSelectField {...props} />;
    case 'MULTI_SELECT':
    case 'COMBOBOX':
    case 'CHECKBOX':
      return <DaVinciMultiSelectField {...props} />;
    case 'PHONE_NUMBER':
      return <DaVinciPhoneNumberField {...props} />;
    case 'DEVICE_REGISTRATION':
    case 'DEVICE_AUTHENTICATION':
      return <DaVinciDeviceField {...props} />;
    case socialLoginCollectorType:
      return (
        <DaVinciIdpField {...props} onIdpAuthorize={props.onIdpAuthorize} />
      );
    case fidoCollectorType:
      return (
        <DaVinciFidoField {...props} onFidoCeremony={props.onFidoCeremony} />
      );
    case protectCollectorType:
      return null;
    case 'POLLING':
      return <DaVinciPollingField {...props} />;
    case 'QR_CODE':
      return <DaVinciQrCodeField {...props} />;
    default:
      return <DaVinciUnsupportedField {...props} />;
  }
}

export default memo(DaVinciFieldRenderer);
