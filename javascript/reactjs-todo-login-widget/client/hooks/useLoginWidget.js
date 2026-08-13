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
import { JOURNEY_LOGIN } from '../constants';

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

    return () => {
      componentEventUnsub();
    };
  }, [componentEvents]);

  useEffect(() => {
    const widget = new Widget({
      target: document.getElementById('login-modal'),
      props: { type: 'modal' },
    });

    return () => {
      widget.$destroy();
    };
  }, []);

  async function openModal() {
    const authSetters = setAuthRef.current;
    authSetters?.setError?.('');
    const urlParams = new URLSearchParams(window.location.search);
    const journeyName = urlParams.get('journey') || JOURNEY_LOGIN;

    componentEvents.open();

    try {
      const store = await journeyEvents.start({ journey: journeyName });
      authSetters?.setAuthentication?.(true);
      const loggedInUser = store.user.response;
      authSetters?.setUser?.(loggedInUser.name);
      authSetters?.setEmail?.(loggedInUser.email);
    } catch (err) {
      const message = err?.journey?.error?.message || err?.message || 'Authentication error';
      authSetters?.setError?.(message);
    }
  }

  return { openModal };
}
