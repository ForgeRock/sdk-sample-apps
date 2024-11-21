/*
 * forgerock-sample-web-react
 *
 * constants.js
 *
 * Copyright (c) 2024 Ping Identity. All rights reserved.
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

export const SERVER_URL = process.env.SERVER_URL;
export const API_URL = process.env.API_URL;
// Yes, the debugger boolean is intentionally reversed
export const DEBUGGER = process.env.DEBUGGER_OFF === 'false';
export const JOURNEY_LOGIN = process.env.JOURNEY_LOGIN;
export const JOURNEY_REGISTER = process.env.JOURNEY_REGISTER;
export const WEB_OAUTH_CLIENT = process.env.WEB_OAUTH_CLIENT;
export const REALM_PATH = process.env.REALM_PATH;
export const CENTRALIZED_LOGIN = process.env.CENTRALIZED_LOGIN;
export const SESSION_URL = `${SERVER_URL}json/realms/root/sessions`;
export const SERVER_TYPE = process.env.SERVER_TYPE;
export const SCOPE = process.env.SCOPE;
export const WELLKNOWN_URL = process.env.WELLKNOWN_URL;
<<<<<<< Updated upstream
=======
console.log(WELLKNOWN_URL);
>>>>>>> Stashed changes
