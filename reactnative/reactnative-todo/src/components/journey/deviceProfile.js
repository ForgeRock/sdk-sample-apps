import { FormControl, Spinner, Center } from 'native-base';
import React, { useEffect, useState } from 'react';

/**
 * @function DeviceProfile - React component used for displaying device profile callback
 * @param {Object} props - React props object passed from parent
 * @param {Object} props.callback - The callback object from AM
 * @returns {Object} - React component object
 */
export default function DeviceProfile({ callback }) {
  const callbackType = callback.getType();
  const [timer, setTimer] = useState(5);
  useEffect(() => {
    const interval = setInterval(() => {
      setTimer(prev => (prev <= 1 ? 0 : prev - 1));
    }, 1000);
    return () => clearInterval(interval);
  }, []);

  return (
    <FormControl>
      <FormControl.Label>
        {`Collecting metadata from your device, callback type: ${callbackType}`}
      </FormControl.Label>
      <Center mt={4}>
        {timer > 0 && (
          <Spinner accessibilityLabel="Loading device profile" />
        )}
        <FormControl.HelperText mt={2}>
          {timer > 0
            ? `Please wait... (${timer}s)`
            : 'You may now continue.'}
        </FormControl.HelperText>
      </Center>
    </FormControl>
  );
}
