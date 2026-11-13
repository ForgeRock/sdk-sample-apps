/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import React from 'react';
import { Text, View } from 'react-native';
import MaterialIcon from 'react-native-vector-icons/MaterialIcons';
import type { PasswordPolicy } from '@ping-identity/rn-davinci';
import { colors } from '../../../../src/styles/colors';
import { davinciFieldStyles } from '../../../../src/styles/davinciStyles';

/**
 * Props for {@link DaVinciPasswordRequirements}.
 */
export type DaVinciPasswordRequirementsProps = {
  /**
   * Password policy resolved from the server payload.
   */
  policy: PasswordPolicy;
  /**
   * Current password value used for live rule satisfaction checks.
   */
  value: string;
};

type Requirement = {
  label: string;
  satisfied: boolean;
};

/**
 * Counts how many characters in {@link value} are members of the literal
 * character set {@link charSet}.
 *
 * The server sends `minCharacters` as a map whose keys are literal character
 * sets (e.g. `"ABCDEFGHIJKLMNOPQRSTUVWXYZ"` for uppercase). Each character
 * in the password that appears in the key string counts as one match.
 *
 * @param value Current password value.
 * @param charSet Literal string of allowed characters for this class.
 * @returns Number of matching characters in value.
 */
function countInCharSet(value: string, charSet: string): number {
  const set = new Set(charSet);
  let count = 0;
  for (const ch of value) {
    if (set.has(ch)) {
      count++;
    }
  }
  return count;
}

/**
 * Derives a human-readable label for a character-set key from the server.
 * Falls back to the raw key string when the class is unrecognised.
 *
 * @param charSet Literal character set string used as the policy key.
 * @returns Human-readable class name.
 */
function charSetLabel(charSet: string): string {
  if (/^[A-Z]+$/.test(charSet)) return 'uppercase';
  if (/^[a-z]+$/.test(charSet)) return 'lowercase';
  if (/^[0-9]+$/.test(charSet)) return 'numeric';
  return 'special';
}

/**
 * Builds the list of requirements derived from the policy and current value.
 *
 * @param policy Password policy.
 * @param value Current password.
 * @returns Array of requirement entries with satisfaction state.
 */
function buildRequirements(
  policy: PasswordPolicy,
  value: string,
): Requirement[] {
  const requirements: Requirement[] = [];

  if (policy.length?.min) {
    requirements.push({
      label: `At least ${policy.length.min} characters`,
      satisfied: value.length >= policy.length.min,
    });
  }
  if (policy.length?.max && policy.length.max > 0) {
    requirements.push({
      label: `At most ${policy.length.max} characters`,
      satisfied: value.length <= policy.length.max,
    });
  }

  Object.entries(policy.minCharacters ?? {}).forEach(([charSet, required]) => {
    if (required <= 0) {
      return;
    }
    const matches = countInCharSet(value, charSet);
    const label = charSetLabel(charSet);
    requirements.push({
      label: `At least ${required} ${label} character${required === 1 ? '' : 's'}`,
      satisfied: matches >= required,
    });
  });

  if (policy.maxRepeatedCharacters > 0) {
    const repeatedPattern = new RegExp(
      `(.)\\1{${policy.maxRepeatedCharacters},}`,
    );
    requirements.push({
      label: `No more than ${policy.maxRepeatedCharacters} repeated characters`,
      satisfied: !repeatedPattern.test(value),
    });
  }

  if (policy.minUniqueCharacters > 0) {
    const uniqueCount = new Set(value.split('')).size;
    requirements.push({
      label: `At least ${policy.minUniqueCharacters} unique characters`,
      satisfied: uniqueCount >= policy.minUniqueCharacters,
    });
  }

  return requirements;
}

/**
 * Renders a live password policy checklist beneath a password field.
 *
 * @param props Component props.
 * @returns Password requirements card, or `null` when policy yields no rules.
 */
export default function DaVinciPasswordRequirements(
  props: DaVinciPasswordRequirementsProps,
): React.ReactElement | null {
  const { policy, value } = props;
  const requirements = buildRequirements(policy, value);

  if (requirements.length === 0) {
    return null;
  }

  return (
    <View style={davinciFieldStyles.passwordRequirementsCard}>
      <Text style={davinciFieldStyles.passwordRequirementsTitle}>
        Password must meet:
      </Text>
      {requirements.map((requirement, index) => (
        <View
          key={`${requirement.label}-${index}`}
          style={davinciFieldStyles.passwordRequirementsRow}
        >
          <MaterialIcon
            name={
              requirement.satisfied ? 'check-circle' : 'radio-button-unchecked'
            }
            size={14}
            color={requirement.satisfied ? colors.success : colors.gray}
            style={davinciFieldStyles.passwordRequirementsIcon}
          />
          <Text style={davinciFieldStyles.passwordRequirementsText}>
            {requirement.label}
          </Text>
        </View>
      ))}
    </View>
  );
}
