/*
 * forgerock-sample-web-react
 *
 * index.mjs
 *
 * Copyright (c) 2024 Ping Identity. All rights reserved.
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */
import 'dotenv/config';
import cors from 'cors/lib/index.js';
import express from 'express';
import cookieParser from 'cookie-parser';
import { createServer } from 'http';

import { SERVER_URL, PORT } from './app/constants.js';
import routes from './app/routes.js';

/**
 * Create and configure Express
 */
const app = express();
app.use(express.json());
app.use(cookieParser());
app.use(
  cors({
    credentials: true,
    origin: function (origin, callback) {
      // DON'T DO THIS IN PRODUCTION!
      return callback(null, true);
    },
  }),
);

/**
 * Log all server interactions
 */
app.use((req, res, next) => {
  console.log(`${req.method} ${req.path}`);
  next();
});

/**
 * Initialize routes
 */
routes(app);

/**
 * Attach application to port and listen for requests
 */
if (!SERVER_URL) {
  createServer(() => null).listen(PORT);

  console.error(
    'ERROR: Missing .env value. Ensure you have an .env file within the dir of this sample app.',
  );
  console.error(
    'Ensure you have a .env file with appropriate values and the proper security certificate and key.',
  );
  console.error('Please stop this process.');
} else {
  // Prod uses Nginx, so run regular server
  console.log('Creating Node HTTP server');
  createServer(app).listen(PORT, '0.0.0.0');

  console.log(`Node server listening on port: ${PORT}.`);
}
