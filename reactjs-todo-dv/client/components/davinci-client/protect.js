/*
 * forgerock-sample-web-react
 *
 * protect.js
 *
 * Copyright (c) 2021 ForgeRock. All rights reserved.
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */
import React from 'react';

export default function ({ collector, updater }) {
  updater('fakeprofile');
  return <p key={collector.output.key}>{collector.output.label}</p>;
}
