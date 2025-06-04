import React from 'react';

export default function Readonly({ collector }) {
  return (
    <div className="form-group">
      <p>{collector.output.label}</p>
    </div>
  );
}
