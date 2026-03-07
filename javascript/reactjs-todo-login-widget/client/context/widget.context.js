/*
 * forgerock-sample-web-react
 *
 * widget.context.js
 *
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import Widget, { component, journey } from '@forgerock/login-widget';
import { createContext, useContext, useEffect, useRef } from 'react';

import { AuthContext } from './auth.context';

/**
 * @function useInitLoginWidgetState - Owns login widget lifecycle and exposes a small API via context
 * @returns {Object} - Opens the login widget modal

 */
export function useInitLoginWidgetState() {
  const [, setAuth] = useContext(AuthContext);

  /**
   * Why `useRef` here?
   * The login widget exposes event streams (journey/component) that we subscribe to.
   * We want to subscribe only once to avoid unsubscribe/resubscribe on every React re-render.
   *
   * The subscription callback still needs access to the latest auth setters
   * from `AuthContext`. If we referenced `setAuth` directly inside the callback,
   * the callback could capture a stale value from the first render (stale closure).
   *
   * Store the latest `setAuth` in a ref. Refs are stable across renders,
   * and reading `setAuthRef.current` inside the callback always gives the newest
   * setters without forcing the effect to re-run.
   */
  const setAuthRef = useRef(setAuth);
  setAuthRef.current = setAuth;

  /**
   * Create widget event sources once per mount
   * `component()` / `journey()` create the login widget’s event sources.
   * We keep them in refs so we get a single, stable instance for the lifetime
   * of this provider (instead of recreating them on every render).
   */
  const componentEventsRef = useRef(null);
  if (!componentEventsRef.current) componentEventsRef.current = component();

  const journeyEventsRef = useRef(null);
  if (!journeyEventsRef.current) journeyEventsRef.current = journey();

  // Local aliases for readability
  const componentEvents = componentEventsRef.current;
  const journeyEvents = journeyEventsRef.current;

  useEffect(() => {
    const componentEventUnsub = componentEvents.subscribe((event) => {
      console.log(event);
    });

    const journeyEventUnsub = journeyEvents.subscribe((event) => {
      if (event?.user?.successful && event?.user?.response) {
        const loggedInUser = event.user.response;
        const setter = setAuthRef.current;
        setter?.setUser?.(loggedInUser.name);
        setter?.setEmail?.(loggedInUser.email);
        setter?.setAuthentication?.(true);
      }
    });

    return () => {
      componentEventUnsub();
      journeyEventUnsub();
    };
  }, []);

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
    journeyEvents.start();
    componentEvents.open();
  }

  return { openModal };
}

/**
 * @constant LoginWidgetContext - Creates React Context API
 * This provides access to the login widget openModal without prop drilling.
 */
export const LoginWidgetContext = createContext({
  openModal: () => {},
});
