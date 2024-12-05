// /*
//  * forgerock-sample-web-react
//  *
//  * index.js
//  *
//  * Copyright (c) 2021 ForgeRock. All rights reserved.
//  * This software may be modified and distributed under the terms
//  * of the MIT license. See the LICENSE file for details.
//  */

// import React, { useEffect } from 'react';
// import { NativeModules } from 'react-native';
// import { SafeAreaProvider } from 'react-native-safe-area-context';

// /*
//  * Please ensure you have created an .env.js from the
//  * .env.example.js template!
//  */
// import { DEBUGGER_OFF } from '../.env';
// import Theme from './theme/index';
// import { AppContext, useGlobalStateMgmt } from './global-state';
// import Router from './router';

// const { FRAuthSampleBridge } = NativeModules;

// export default function App() {
//   const stateMgmt = useGlobalStateMgmt({});

//   useEffect(() => {
//     async function start() {
//       /* *******************************************************************
//        * NATIVE BRIDGE SDK INTEGRATION
//        * Summary: Call Start method to initialize SDK
//        * -------------------------------------------------------------------
//        * Details: It's important to start the FR SDK at the root level!
//        * Start is needed to be called and resolved before any other Native
//        * methods can be used.
//        *
//        * Important: Use `start` as early on as possible!
//        ********************************************************************/
//       // if (!DEBUGGER_OFF) debugger;
//       const { MyBridge } = FRAuthSampleBridge;
//       if (MyBridge) {
//         await MyBridge.start();
//       }
//     }
//     start();
//   }, []);

//   return (
//     <Theme>
//       <AppContext.Provider value={stateMgmt}>
//         <SafeAreaProvider>
//           <Router />
//         </SafeAreaProvider>
//       </AppContext.Provider>
//     </Theme>
//   );
// }
