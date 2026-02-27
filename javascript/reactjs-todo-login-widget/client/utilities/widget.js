/*
 * forgerock-sample-web-react
 *
 * widget.js
 *
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import Widget, { component, journey } from '@forgerock/login-widget';
import React, { createContext, useCallback, useContext, useEffect, useMemo } from 'react';
import { useNavigate } from 'react-router-dom';

import { AppContext } from '../global-state';

// This context exposes a small public API
// Consumers don't need access to the widget instance or subscription details
const LoginWidgetContext = createContext({
  openModal: () => {},
});

/**
 * @function LoginWidgetProvider - Owns login widget lifecycle and exposes actions via context
 * @param {Object} props - React props
 * @param {Object} props.children - All React elements/components nested inside LoginWidgetProvider.
 * @returns {Object} - React component
 */
export function LoginWidgetProvider({ children }) {
  const [, setter] = useContext(AppContext);
  const navigate = useNavigate();

  // `component()` and `journey()` return objects
  // Creating them inside render without memoization would create new instances on every re-render,
  // which can lead to subtle bugs like subscribing on one instance but calling `open()` on another
  // `useMemo` keeps one instance per mount of this Provider
  const componentEvents = useMemo(() => component(), []);
  const journeyEvents = useMemo(() => journey(), []);

  // `openModal` is part of the context API
  // `useCallback` keeps a stable function identity across Provider re-renders,
  // which helps avoid unnecessary re-renders in context consumers
  const openModal = useCallback(() => {
    journeyEvents.start();
    componentEvents.open();
  }, [journeyEvents, componentEvents]);

  useEffect(() => {
    // The widget event APIs follow an Observable-style pattern:
    // `subscribe(handler)` registers a listener and returns an unsubscribe function
    // We call the unsubscribe functions in the effect cleanup to avoid memory leaks
    // and duplicate event handlers if this Provider ever remounts
    const componentEventUnsub = componentEvents.subscribe((event) => {
      console.log(event);
    });

    const journeyEventUnsub = journeyEvents.subscribe((event) => {
      if (event?.user?.successful) {
        if (event?.user?.response) {
          const user = event.user.response;
          setter.setUser(user.name);
          setter.setEmail(user.email);
          setter.setAuthentication(true);
        }
      }
    });

    return () => {
      // Cleanup is critical with observable subscriptions; otherwise listeners
      // can stack up across mounts, leading to duplicated logs/state updates
      componentEventUnsub();
      journeyEventUnsub();
    };
  }, [componentEvents, journeyEvents, setter, navigate]);

  useEffect(() => {
    // Create the widget once per Provider mount
    // We keep `[]` so this doesn't recreate/destroy the widget on every re-render
    // Cleanup calls `$destroy()` to release listeners/DOM bindings when the Provider unmounts
    const widget = new Widget({
      target: document.getElementById('login-modal'),
      props: { type: 'modal' },
    });

    return () => {
      widget.$destroy();
    };
  }, []);

  // Returning the Context Provider makes `openModal` available to child components in Router
  // Any descendant can call `useLoginWidget()` without prop drilling
  return (
    <LoginWidgetContext.Provider value={{ openModal }}>{children}</LoginWidgetContext.Provider>
  );
}

/**
 * @function useLoginWidget - Hook for consuming login widget actions
 * @returns {Object} - login widget actions
 */
export function useLoginWidget() {
  return useContext(LoginWidgetContext);
}
