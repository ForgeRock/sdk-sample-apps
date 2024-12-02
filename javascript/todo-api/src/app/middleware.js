/*
 * forgerock-sample-web-react
 *
 * server.middleware.mjs
 *
 * Copyright (c) 2024 Ping Identity. All rights reserved.
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import request from 'superagent';

import {
  SERVER_URL,
  CONFIDENTIAL_CLIENT,
  REALM_PATH,
  SERVER_TYPE,
  REST_OAUTH_CLIENT,
} from './constants.js';
/**
 * @function auth - Auth middleware for checking the validity of user's auth
 * @param {Object} req - Node.js' req object
 * @param {Object} res - Node.js' res object
 * @param {function} next - Node.js' req next method to proceed through middleware
 * @return {void}
 */
export async function auth(req, res, next) {
  let response;
  const path = `${
    SERVER_TYPE === 'AIC'
      ? `${SERVER_URL}oauth2/realms/root${
          REALM_PATH === 'root' ? '' : '/realms/' + REALM_PATH
        }/introspect`
      : `${SERVER_URL}as/introspect`
  }`;
  try {
    if (req.headers.authorization) {
      // eslint-disable-next-line no-unused-vars
      const [_, token] = req.headers.authorization.split(' ');
      console.log(`Token: ${token}`);
      if (SERVER_TYPE === 'AIC') {
        response = await request
          .post(path)
          .set('Content-Type', 'application/json')
          .set('Authorization', `Basic ${CONFIDENTIAL_CLIENT}`)
          .send({ token });
      } else {
        response = await request
          .post(path)
          .type('form')
          .set('Content-Type', 'application/x-www-form-urlencoded')
          .send(`token=${token}`)
          .send(`client_id=${REST_OAUTH_CLIENT}`);
      }
    }
  } catch (err) {
    console.log(JSON.stringify(err));
    console.log(`Error: auth middleware: ${err}`);
    response = {
      body: {},
    };
  }

  if (response?.body?.active) {
    req.user = response.body;
    next();
  } else {
    console.log('Error: user failed auth validation');
    console.log(JSON.stringify(response));
    res.status(401).send();
  }
}
