/*
 * ping-sample-web-react-davinci
 *
 * image.js
 *
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */
import React from 'react';

/**
 * @function parseSafeHref - Only http/https URLs are safe to render in an href;
 * DaVinci's own type doc requires consumers to sanitize this value.
 * @param {string} href - The unsanitized href from collector.output.href
 * @returns {string|null} - The href if its scheme is allowed, otherwise null
 */
function parseSafeHref(href) {
  try {
    const url = new URL(href, window.location.origin);
    return ['http:', 'https:'].includes(url.protocol) ? href : null;
  } catch {
    return null;
  }
}

export default function ImageComponent({ collector }) {
  if (collector.error) {
    return (
      <p className="alert alert-danger mt-1" role="alert">
        {`Image error: ${collector.error}`}
      </p>
    );
  }

  const image = (
    <img
      src={collector.output.src}
      alt={collector.output.alt}
      data-testid="form-image"
      className="img-fluid"
    />
  );

  const safeHref = collector.output.href ? parseSafeHref(collector.output.href) : null;

  return (
    <div className="d-flex flex-column align-items-center mb-3">
      {safeHref ? <a href={safeHref}>{image}</a> : image}
    </div>
  );
}
