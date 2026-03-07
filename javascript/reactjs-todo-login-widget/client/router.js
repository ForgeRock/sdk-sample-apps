/*
 * forgerock-sample-web-react
 *
 * router.js
 *
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import React, { useEffect } from 'react';
import { BrowserRouter, Routes, Route, useLocation } from 'react-router-dom';

import { LoginWidgetProvider } from './utilities/widget';
import { ProtectedRoute } from './utilities/route';
import Todos from './views/todos';
import Footer from './components/layout/footer';
import Header from './components/layout/header';
import Home from './views/home';
import Logout from './views/logout';

function ScrollToTop() {
  const { pathname } = useLocation();

  useEffect(() => {
    window.scrollTo(0, 0);
  }, [pathname]);

  return null;
}

/**
 * @function App - Application React view
 * @returns {Object} - React component object
 */
export default function Router() {
  return (
    <BrowserRouter>
      <LoginWidgetProvider>
        <Routes>
          <Route
            path="todos"
            element={
              <ProtectedRoute>
                <Header />
                <Todos />
                <Footer />
              </ProtectedRoute>
            }
          />
          <Route path="logout" element={<Logout />} />
          <Route
            path="/"
            element={
              <>
                <ScrollToTop />
                <Header />
                <Home />
                <Footer />
              </>
            }
          />
        </Routes>
      </LoginWidgetProvider>
    </BrowserRouter>
  );
}
