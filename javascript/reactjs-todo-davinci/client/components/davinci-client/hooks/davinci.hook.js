/*
 * ping-sample-web-react-davinci
 *
 * davinci.hook.js
 *
 * Copyright (c) 2025 - 2026 Ping Identity Corporation. All rights reserved.
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import { useEffect, useMemo, useState } from 'react';
import createClient from './create-client.utils.js';

const urlParams = new URLSearchParams(window.location.search);
const continueToken = urlParams.get('continueToken');
const acrValue = urlParams.get('acrValue');

/**
 * @function useDavinci - Custom React hook that manages the DaVinci flow state
 * @returns {Object} - An array with state at index 0 and setter methods at index 1
 */
export default function useDavinci() {
  // Create local state to manage DaVinci flows
  const [davinciClient, setDavinciClient] = useState(null);
  const [node, setNode] = useState(null);

  const { formName, formAction, collectors } = useMemo(() => {
    /***********************************************************************
     * SDK INTEGRATION POINT
     * Summary: Create state needed to render the form
     * ----------------------------------------------------------------------
     * Details: Whenever the node changes we will get the updated client
     * info and extract data needed to render the form. We take advantage of a
     * useMemo hook to keep node and collector state in sync and prevent
     * unnecessary re-renders of the form when either the node or collectors
     * change.
     ************************************************************************* */

    if (node && davinciClient) {
      const clientInfo = davinciClient.getClient() ?? null;
      const formName = clientInfo?.name ?? '';
      const formAction = clientInfo?.action ?? '';
      const collectors = node.status === 'continue' ? davinciClient.getCollectors() : null;
      return { formName, formAction, collectors };
    } else {
      return { formName: null, formAction: null, collectors: null };
    }
  }, [node, davinciClient]);

  /** *********************************************************************
   * SDK INTEGRATION POINT
   * Summary: Initialize the Davinci client and flow
   * ----------------------------------------------------------------------
   * Details: Start the DaVinci flow to get the first node for rendering the form.
   ********************************************************************* */
  useEffect(() => {
    async function initDavinci() {
      try {
        const client = await createClient();
        setDavinciClient(client);

        if (continueToken) {
          /**
           * If we were redirected here from an IDP with a continueToken, then resume the flow
           */
          const resumeNode = await client?.resume({ continueToken });
          setNode(resumeNode);
        } else {
          const initialNode = await client?.start(
            /**
             * Optional: If your OAuth client has more than one policy, you can select
             * a policy to execute by passing in the policy ID as an ACR value to the
             * query option of the DaVinci client start method
             */
            acrValue ? { query: { acr_values: acrValue } } : undefined,
          );
          setNode(initialNode);
        }
      } catch (error) {
        console.error(`Error initializing DaVinci; ${error}`);
      }
    }

    if (!davinciClient && !node) {
      initDavinci();
    }
  }, [davinciClient, node]);

  /**
   * @function updater - Gets the DaVinci client updater function for a collector
   * @returns {function} - A function to call with the updated value for the collector's input
   */
  function updater(collector) {
    return davinciClient.update(collector);
  }

  /**
   * @function setNext - Get the next node in the DaVinci flow
   * @returns {Promise<void>}
   */
  async function setNext() {
    /** *********************************************************************
     * SDK INTEGRATION POINT
     * Summary: Get the next node in the DaVinci flow
     * ----------------------------------------------------------------------
     * Details: Get the next node in the flow from DaVinci. No need to pass
     * the node with set values on collectors since the DaVinci client will
     * manage the state of the current node. Updates local node state with the
     * next node.
     ********************************************************************* */
    try {
      const nextNode = await davinciClient.next();
      setNode(nextNode);
    } catch (error) {
      console.error('Error getting next node', error);
    }
  }

  /**
   * @function startNewFlow - Starts a new DaVinci flow from a flow collector
   * @returns {Promise<void>}
   */
  async function startNewFlow(collector) {
    /** *********************************************************************
     * SDK INTEGRATION POINT
     * Summary: Start a new DaVinci flow from a flow collector
     * ----------------------------------------------------------------------
     * Details: The DaVinci client provides a flow method for retrieving
     * the first node from a new flow. We set the local node state to this
     * flow node to start a new flow.
     ********************************************************************* */
    if (davinciClient && collector?.type === 'FlowCollector') {
      try {
        const getFlowNode = davinciClient.flow({ action: collector.name });
        const flowNode = await getFlowNode(collector.output.key);
        setNode(flowNode);
      } catch (error) {
        console.error('Error getting flow node: ', error);
      }
    } else {
      console.error('Error starting new flow');
    }
  }

  return [
    { formName, formAction, node, collectors },
    {
      setNext,
      startNewFlow,
      updater,
      externalIdp: davinciClient && davinciClient.externalIdp(),
      getError: davinciClient && davinciClient.getError,
    },
  ];
}
