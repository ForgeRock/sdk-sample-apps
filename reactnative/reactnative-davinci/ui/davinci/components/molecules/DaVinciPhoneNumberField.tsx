/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import React, { useState } from 'react';
import { View } from 'react-native';
import type {
  DaVinciFieldValidationError,
  PhoneNumberCollector,
} from '@ping-identity/rn-davinci';
import PingTextInput from '../../../components/atoms/PingTextInput';
import DaVinciErrorList from '../atoms/DaVinciErrorList';
import DaVinciFieldLabel from '../atoms/DaVinciFieldLabel';
import PickerModal from '../atoms/PickerModal';
import { davinciFieldStyles } from '../../../../src/styles/davinciStyles';
import type { DaVinciCollectorRendererProps } from './types';

/**
 * Country entry — mirrors the `Country` struct in the iOS PingExample sample.
 * `countryCode` is the ISO 3166-1 alpha-2 code (e.g. "US").
 * `dialCode` is the numeric part of the ITU dial code without the leading "+"
 * (e.g. "1" for the US).
 * Add more countries as needed.
 */
type Country = {
  countryCode: string;
  name: string;
  dialCode: string;
};

const COUNTRIES: Country[] = [
  { countryCode: 'US', name: 'United States', dialCode: '1' },
  { countryCode: 'CA', name: 'Canada', dialCode: '1' },
  { countryCode: 'GB', name: 'United Kingdom', dialCode: '44' },
  { countryCode: 'AU', name: 'Australia', dialCode: '61' },
  { countryCode: 'DE', name: 'Germany', dialCode: '49' },
  { countryCode: 'FR', name: 'France', dialCode: '33' },
  { countryCode: 'JP', name: 'Japan', dialCode: '81' },
  { countryCode: 'CN', name: 'China', dialCode: '86' },
  { countryCode: 'IN', name: 'India', dialCode: '91' },
  { countryCode: 'BR', name: 'Brazil', dialCode: '55' },
  { countryCode: 'RU', name: 'Russia', dialCode: '7' },
  { countryCode: 'IT', name: 'Italy', dialCode: '39' },
  { countryCode: 'KR', name: 'South Korea', dialCode: '82' },
  { countryCode: 'MX', name: 'Mexico', dialCode: '52' },
  { countryCode: 'ES', name: 'Spain', dialCode: '34' },
  { countryCode: 'ZA', name: 'South Africa', dialCode: '27' },
  { countryCode: 'HK', name: 'Hong Kong', dialCode: '852' },
];

function dialCodeForCountryCode(isoCode: string): string | undefined {
  return COUNTRIES.find(c => c.countryCode === isoCode)?.dialCode;
}

function countryCodeForDialCode(dialCode: string): string | undefined {
  return COUNTRIES.find(c => c.dialCode === dialCode)?.countryCode;
}

/**
 * Resolves the current ISO country code and phone number from form state.
 *
 * @remarks
 * Mirrors the iOS sample app's resolution logic: if `field.countryCode` is set
 * use it; otherwise fall back to `field.defaultCountryCode`. When the stored
 * value looks like a dial code (starts with "+") it is reverse-mapped to an
 * ISO code so both formats are handled gracefully.
 */
function resolveValue(
  value: unknown,
  collector: PhoneNumberCollector,
): { countryCode: string; phoneNumber: string; extension: string } {
  let rawCode =
    value &&
    typeof value === 'object' &&
    'countryCode' in value &&
    typeof (value as { countryCode: unknown }).countryCode === 'string'
      ? (value as { countryCode: string }).countryCode
      : collector.countryCode || collector.defaultCountryCode;

  // Normalise a dial-code value (e.g. "+1") to its ISO country code.
  if (rawCode.startsWith('+')) {
    rawCode = countryCodeForDialCode(rawCode.slice(1)) ?? rawCode;
  }

  const phoneNumber =
    value &&
    typeof value === 'object' &&
    'phoneNumber' in value &&
    typeof (value as { phoneNumber: unknown }).phoneNumber === 'string'
      ? (value as { phoneNumber: string }).phoneNumber
      : (collector.phoneNumber ?? '');

  const extension =
    value &&
    typeof value === 'object' &&
    'extension' in value &&
    typeof (value as { extension: unknown }).extension === 'string'
      ? (value as { extension: string }).extension
      : (collector.extension ?? '');

  return { countryCode: rawCode, phoneNumber, extension };
}

/**
 * Returns the label shown in the trigger button: "+{dialCode}" when the ISO
 * code is known, otherwise the raw `countryCode` value, otherwise a prompt.
 */
function triggerLabel(isoCode: string): string {
  const dial = dialCodeForCountryCode(isoCode);
  if (dial) {
    return `+${dial}`;
  }
  if (isoCode) {
    return isoCode;
  }
  return '';
}

/**
 * Renders a {@link PhoneNumberCollector} as a country code picker + phone
 * number input row.
 *
 * @remarks
 * The country code picker stores the ISO 3166-1 alpha-2 country code in
 * `countryCode` (e.g. "US"), matching the iOS SDK sample app. The trigger
 * button displays the derived dial code (e.g. "+1"). The lookup table mirrors
 * the `listOfCountries` array in the iOS `PhoneNumberView.swift` sample.
 *
 * @param props Renderer props.
 * @returns Phone number field element.
 */
export default function DaVinciPhoneNumberField(
  props: DaVinciCollectorRendererProps,
): React.ReactElement {
  const { collector, value, onChange, onValidate } = props;
  const phoneCollector = collector as PhoneNumberCollector;
  const current = resolveValue(value, phoneCollector);

  const [modalVisible, setModalVisible] = useState(false);
  const [validationErrors, setValidationErrors] = useState<
    DaVinciFieldValidationError[] | null
  >(null);

  const pickerOptions = COUNTRIES.map(c => ({
    value: c.countryCode,
    label: `+${c.dialCode} (${c.name})`,
  }));

  return (
    <View style={davinciFieldStyles.card}>
      <DaVinciFieldLabel
        label={phoneCollector.label}
        required={phoneCollector.required}
      />
      <View style={davinciFieldStyles.phoneRow}>
        <View style={davinciFieldStyles.phoneCountry}>
          <PickerModal
            label="Country code"
            options={pickerOptions}
            selectedValue={current.countryCode}
            triggerLabel={triggerLabel(current.countryCode)}
            visible={modalVisible}
            onOpen={() => setModalVisible(true)}
            onClose={() => setModalVisible(false)}
            onSelect={isoCode => {
              setValidationErrors(null);
              onChange({
                countryCode: isoCode,
                phoneNumber: current.phoneNumber,
                extension: current.extension,
              });
            }}
          />
        </View>
        <View style={davinciFieldStyles.phoneNumber}>
          <PingTextInput
            label="Phone number"
            value={current.phoneNumber}
            onChangeText={text => {
              setValidationErrors(null);
              onChange({
                countryCode: current.countryCode,
                phoneNumber: text,
                extension: current.extension,
              });
            }}
            onBlur={() => {
              onValidate(collector.key, current.phoneNumber)
                .then(setValidationErrors)
                .catch(error => {
                  console.warn(
                    '[DaVinci] Phone number validation failed:',
                    error,
                  );
                });
            }}
            keyboardType="phone-pad"
            containerStyle={{ marginBottom: 0 }}
          />
        </View>
      </View>
      {phoneCollector.showExtension ? (
        <PingTextInput
          label={phoneCollector.extensionLabel}
          value={current.extension}
          onChangeText={extension => {
            setValidationErrors(null);
            onChange({
              countryCode: current.countryCode,
              phoneNumber: current.phoneNumber,
              extension,
            });
          }}
          keyboardType="phone-pad"
        />
      ) : null}
      <DaVinciErrorList errors={validationErrors ?? undefined} />
    </View>
  );
}
