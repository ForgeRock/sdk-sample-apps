import React, { useEffect, useState } from 'react';

export default function Error({ getError }) {
  const [error, setError] = useState(null);
  useEffect(() => {
    if (getError) {
      const err = getError();
      setError(err);
    }
  }, []);

  return error ? <pre>${error?.message ?? 'An Error Occured'}</pre> : null;
}
