/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import React, { useCallback, useEffect, useMemo, useState } from 'react';
import {
  Animated,
  Easing,
  TextInput,
  TouchableOpacity,
  type StyleProp,
  type TextInputProps,
  type TextStyle,
  type ViewStyle,
  View,
} from 'react-native';
import MaterialIcon from 'react-native-vector-icons/MaterialIcons';
import { colors } from '../../../src/styles/colors';
import { pingTextInputStyles as styles } from '../../../src/styles/componentStyles';

type PingTextInputProps = TextInputProps & {
  label?: string;
  showFloatingLabel?: boolean;
  allowPasswordToggle?: boolean;
  containerStyle?: StyleProp<ViewStyle>;
  inputWrapperStyle?: StyleProp<ViewStyle>;
  labelStyle?: StyleProp<TextStyle>;
  labelBackgroundColor?: string;
  activeBorderColor?: string;
  inactiveBorderColor?: string;
  activeTextColor?: string;
  inactiveTextColor?: string;
};

/**
 * Reusable outlined text input with active/inactive visual states.
 *
 * @remarks
 * Active state is shown while focused or when a value is present.
 * When active, a floating label is rendered at the top edge.
 *
 * @param props Input props.
 * @param props.label Optional field label for floating active state.
 * @param props.showFloatingLabel Whether to show floating label behavior.
 * @param props.allowPasswordToggle Enables eye icon toggle for secure text.
 * @param props.containerStyle Optional container style override.
 * @param props.inputWrapperStyle Optional wrapper style override.
 * @param props.labelStyle Optional floating label style override.
 * @param props.labelBackgroundColor Background color behind floating label.
 * @param props.activeBorderColor Border color in active state.
 * @param props.inactiveBorderColor Border color in inactive state.
 * @param props.activeTextColor Text color in active (focused) state.
 * @param props.inactiveTextColor Text color in inactive state.
 * @returns Styled text input component.
 */
export default function PingTextInput(
  props: PingTextInputProps,
): React.ReactElement {
  const {
    label,
    showFloatingLabel = true,
    allowPasswordToggle = false,
    containerStyle,
    inputWrapperStyle,
    labelStyle,
    labelBackgroundColor = colors.surface,
    activeBorderColor = colors.primary,
    inactiveBorderColor = colors.inputInactiveBorder,
    activeTextColor = colors.primary,
    inactiveTextColor = colors.inputInactiveText,
    value,
    placeholder,
    placeholderTextColor = colors.inputPlaceholder,
    secureTextEntry,
    onFocus,
    onBlur,
    style,
    ...textInputProps
  } = props;

  const [isFocused, setIsFocused] = useState<boolean>(false);
  const [passwordVisible, setPasswordVisible] = useState<boolean>(false);

  const hasValue = useMemo((): boolean => {
    if (typeof value === 'string') {
      return value.length > 0;
    }
    if (typeof value === 'number') {
      return true;
    }
    return value != null && String(value).length > 0;
  }, [value]);

  const active = isFocused || hasValue;
  const selected = isFocused;
  const floatingLabel = showFloatingLabel ? (label ?? placeholder ?? '') : '';
  const [labelAnimation] = useState<Animated.Value>(
    () => new Animated.Value(active ? 1 : 0),
  );
  const supportsSecureToggle = Boolean(allowPasswordToggle || secureTextEntry);
  const secureMode = supportsSecureToggle
    ? !passwordVisible
    : Boolean(secureTextEntry);
  const inputWrapperStateStyle = useMemo(
    () => ({
      borderColor: selected ? activeBorderColor : inactiveBorderColor,
      borderWidth: selected ? 2 : 1.5,
    }),
    [selected, activeBorderColor, inactiveBorderColor],
  );
  const floatingLabelStateStyle = useMemo(
    () => ({
      color: selected ? activeBorderColor : inactiveBorderColor,
      backgroundColor: active ? labelBackgroundColor : 'transparent',
    }),
    [
      selected,
      active,
      activeBorderColor,
      inactiveBorderColor,
      labelBackgroundColor,
    ],
  );
  const animatedLabelStyle = useMemo(
    () => ({
      transform: [
        {
          translateY: labelAnimation.interpolate({
            inputRange: [0, 1],
            outputRange: [0, -27],
          }),
        },
      ],
      fontSize: labelAnimation.interpolate({
        inputRange: [0, 1],
        outputRange: [16, 12],
      }),
      paddingHorizontal: labelAnimation.interpolate({
        inputRange: [0, 1],
        outputRange: [0, 5],
      }),
    }),
    [labelAnimation],
  );
  const inputTextStateStyle = useMemo(
    () => ({
      color: selected ? activeTextColor : inactiveTextColor,
    }),
    [selected, activeTextColor, inactiveTextColor],
  );

  useEffect(() => {
    Animated.timing(labelAnimation, {
      toValue: active ? 1 : 0,
      duration: 180,
      easing: Easing.out(Easing.ease),
      useNativeDriver: false,
    }).start();
  }, [active, labelAnimation]);

  const handleFocus = useCallback<NonNullable<TextInputProps['onFocus']>>(
    (event): void => {
      setIsFocused(true);
      onFocus?.(event);
    },
    [onFocus],
  );

  const handleBlur = useCallback<NonNullable<TextInputProps['onBlur']>>(
    (event): void => {
      setIsFocused(false);
      onBlur?.(event);
    },
    [onBlur],
  );

  return (
    <View style={[styles.container, containerStyle]}>
      <View
        style={[styles.inputWrapper, inputWrapperStateStyle, inputWrapperStyle]}
      >
        {showFloatingLabel && floatingLabel.length > 0 ? (
          <Animated.Text
            pointerEvents="none"
            style={[
              styles.label,
              animatedLabelStyle,
              floatingLabelStateStyle,
              labelStyle,
            ]}
          >
            {floatingLabel}
          </Animated.Text>
        ) : null}
        <TextInput
          {...textInputProps}
          style={[styles.input, inputTextStateStyle, style]}
          value={value}
          onFocus={handleFocus}
          onBlur={handleBlur}
          multiline={false}
          placeholder={showFloatingLabel ? '' : placeholder}
          placeholderTextColor={placeholderTextColor}
          secureTextEntry={secureMode}
        />
        {supportsSecureToggle ? (
          <TouchableOpacity
            accessibilityRole="button"
            accessibilityLabel={
              passwordVisible ? 'Hide password' : 'Show password'
            }
            onPress={() => setPasswordVisible(previousValue => !previousValue)}
            style={styles.passwordToggle}
          >
            <MaterialIcon
              name={passwordVisible ? 'visibility' : 'visibility-off'}
              size={26}
              color={selected ? activeBorderColor : inactiveBorderColor}
            />
          </TouchableOpacity>
        ) : null}
      </View>
    </View>
  );
}
