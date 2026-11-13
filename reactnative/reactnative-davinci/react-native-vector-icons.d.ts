/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

type VectorIconProps = import('react-native').TextProps & {
  name: string;
  size?: number;
  color?: string;
};

type VectorIconComponent = import('react').ComponentType<VectorIconProps> & {
  loadFont: () => Promise<void>;
};

declare module 'react-native-vector-icons/MaterialIcons' {
  const MaterialIcons: VectorIconComponent;
  export default MaterialIcons;
}

declare module 'react-native-vector-icons/FontAwesome' {
  const FontAwesome: VectorIconComponent;
  export default FontAwesome;
}
