/*
 * ping-sample-web-react-journey
 *
 * protect.context.js
 *
 * Copyright (c) 2026 Ping Identity Ping Identity Corporation. All rights reserved.
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */
import { createContext } from 'react';

/**
 * @constant ProtectContext - Creates React Context to store Protect API
 * This provides the capability to set a global Protect API state in React
 * without having to pass the state as props through parent-child components.
 */
export const ProtectContext = createContext(null);