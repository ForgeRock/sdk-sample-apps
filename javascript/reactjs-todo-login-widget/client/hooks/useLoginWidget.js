/*
 * forgerock-sample-web-react
 *
 * useLoginWidget.js
 *
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import Widget, { component, journey } from '@forgerock/login-widget';
import { useContext, useEffect, useRef } from 'react';

import { AuthContext } from '../context/auth.context';

/**
 * @function useLoginWidget - A custom React hook that owns login widget lifecycle and returns a small API
 * @returns {Object} - An object that opens the login widget modal
 */
export function useLoginWidget() {
  const [, setAuth] = useContext(AuthContext);

  // Keep the latest AuthContext setter API without forcing re-subscription
  const setAuthRef = useRef(setAuth);
  setAuthRef.current = setAuth;

  // `component()` and `journey()` return the widget's event controllers
  // React can re-render often. If we recreated these controllers on every render,
  // we'd end up re-subscribing repeatedly (or accidentally listening more than once)
  // Storing them in refs makes them "create once, reuse forever" for this mount
  const componentEventsRef = useRef(null);
  const journeyEventsRef = useRef(null);

  if (!componentEventsRef.current) {
    componentEventsRef.current = component();
  }

  if (!journeyEventsRef.current) {
    journeyEventsRef.current = journey();
  }

  const componentEvents = componentEventsRef.current;
  const journeyEvents = journeyEventsRef.current;

  useEffect(() => {
    const componentEventUnsub = componentEvents.subscribe((event) => {
      console.log(event);
    });

    const journeyEventUnsub = journeyEvents.subscribe((event) => {
      const authSetters = setAuthRef.current;

      if (event?.user?.successful && event?.user?.response) {
        const loggedInUser = event.user.response;
        authSetters?.setError?.('');
        authSetters?.setUser?.(loggedInUser.name);
        authSetters?.setEmail?.(loggedInUser.email);
        authSetters?.setAuthentication?.(true);
      } else if (event?.journey?.completed) {
        let errorSet = false;

        for (const [scope, payload] of Object.entries(event)) {
          if (payload?.error) {
            console.error(`[login-widget] ${scope} error:`, payload.error);

            if (!errorSet) {
              const message = payload.error?.message || 'Authentication error';
              authSetters?.setError?.(message);
              errorSet = true;
            }
          }
        }
      }
    });

    return () => {
      componentEventUnsub();
      journeyEventUnsub();
    };
  }, [componentEvents, journeyEvents]);

  useEffect(() => {
    // Instantiate the Widget and assign it to a variable
    const widget = new Widget({
      // Target needs to be an actual DOM element, so ref is needed with inline type
      target: document.getElementById('login-modal'),
      props: { type: 'modal' }, // Type is modal by default, but declaring here for clarity
    });

    // Ensure you return a function that destroys the Widget on unmount
    return () => {
      widget.$destroy();
    };
  }, []);

  function openModal() {
    const authSetters = setAuthRef.current;
    authSetters?.setError?.('');
    journeyEvents.start();
    componentEvents.open();
  }

  return { openModal };
}
