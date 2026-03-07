/*
 * forgerock-sample-web-react
 *
 * header.js
 *
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import React, { useContext } from 'react';
import { Link, useLocation } from 'react-router-dom';

import AccountIcon from '../icons/account-icon';
import { useLoginWidget } from '../../utilities/widget';
import ForgeRockIcon from '../icons/forgerock-icon';
import HomeIcon from '../icons/home-icon';
import ReactIcon from '../icons/react-icon';
import TodosIcon from '../icons/todos-icon';
import { AuthContext } from '../../context/auth.context';
import { ThemeContext } from '../../context/theme.context';

/**
 * @function Header - Header React view
 * @returns {Object} - React component object
 */
export default function Header() {
  /**
   * Collects the global state for detecting user auth for rendering
   * appropriate navigational items.
   * The destructing of the hook's array results in index 0 having the state value,
   * and index 1 having the "setter" method to set new state values.
   */
  const [auth] = useContext(AuthContext);
  const theme = useContext(ThemeContext);
  const location = useLocation();
  const { openModal } = useLoginWidget();

  let TodosItem;
  let LoginOrOutItem;

  /**
   * Render different navigational items depending on authenticated status
   */
  if (auth.isAuthenticated) {
    TodosItem = [
      <li
        key="home"
        className={`cstm_nav-item ${
          location.pathname === '/' ? 'cstm_nav-item_active' : ''
        } nav-item mx-1`}
      >
        <Link className="cstm_nav-link nav-link d-flex align-items-center h-100 p-0 ps-1" to="/">
          <HomeIcon />
          <span className="px-2 fs-6">Home</span>
        </Link>
      </li>,
      <li
        key="todos"
        className={`cstm_nav-item ${
          location.pathname === '/todos' ? 'cstm_nav-item_active' : ''
        } nav-item`}
      >
        <Link
          className="cstm_nav-link nav-link d-flex align-items-center h-100 p-0 ps-2"
          to="/todos"
        >
          <TodosIcon />
          <span className="px-2 fs-6">Todos</span>
        </Link>
      </li>,
    ];
    LoginOrOutItem = (
      <div className="d-flex align-items-center">
        <div className="dropdown text-end">
          <button
            aria-expanded="false"
            className="btn h-auto p-0"
            data-bs-toggle="dropdown"
            id="account_dropdown"
          >
            <AccountIcon classes="cstm_profile-icon" size="48px" />
          </button>
          <ul
            className={`dropdown-menu dropdown-menu-end shadow-sm pb-0 ${theme.dropdownClass}`}
            aria-labelledby="account_dropdown"
          >
            <li>
              <div className={`dropdown-header border-bottom ${theme.borderClass}`}>
                <p
                  className={`fw-bold fs-6 mb-0 ${theme.textClass ? theme.textClass : 'text-dark'}`}
                >
                  {auth.username}
                </p>
                <p className="mb-2">{auth.email}</p>
              </div>
            </li>
            <li>
              <Link className="dropdown-item py-2" to="/logout">
                Sign Out
              </Link>
            </li>
          </ul>
        </div>
      </div>
    );
  } else {
    TodosItem = null;
    LoginOrOutItem = (
      <div className="d-flex py-3">
        <a
          className={`cstm_login-link py-2 px-3 mx-1 ${
            theme.mode === 'dark' ? 'cstm_login-link_dark' : ''
          }`}
          onClick={openModal}
          href="#"
        >
          Sign In
        </a>
        <Link
          className="btn btn-primary disabled"
          to="/register"
          aria-disabled="true"
          onClick={(e) => e.preventDefault()}
        >
          Sign Up
        </Link>
      </div>
    );
  }

  return (
    <nav
      className={`navbar navbar-expand ${theme.navbarClass} ${theme.borderHighContrastClass} py-0 border-bottom`}
    >
      <div className="cstm_container container-fluid d-flex align-items-stretch">
        <Link
          to="/"
          className={`cstm_navbar-brand ${
            auth.isAuthenticated ? 'cstm_navbar-brand_auth' : ''
          } navbar-brand ${
            auth.isAuthenticated ? 'd-none d-sm-none d-md-block' : ''
          } py-3 pe-4 me-4 ${theme.borderHighContrastClass}`}
        >
          <ForgeRockIcon size="31px" /> + <ReactIcon size="38px" />
        </Link>
        <div className="navbar-collapse d-flex align-items-stretch" id="navbarNav">
          <ul className="navbar-nav d-flex align-items-stretch me-auto">{TodosItem}</ul>
          {LoginOrOutItem}
        </div>
      </div>
    </nav>
  );
}
