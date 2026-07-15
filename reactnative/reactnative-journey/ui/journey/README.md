<!--
Copyright (c) 2026 Ping Identity Corporation. All rights reserved.

This software may be modified and distributed under the terms
of the MIT license. See the LICENSE file for details.
-->

# Journey Sample UI Documentation

This folder contains the helper-only Journey sample implementation used by the sample app.

The sample is intentionally UI-owned:
- SDK (`@ping-identity/rn-journey`) provides Journey state/actions and helper APIs.
- Sample app renders callbacks and controls progression.
- Device profile is an explicit user action; polling is handled automatically by sample UI logic.
- Native SDK remains authoritative for callback validation and flow progression.

## Folder Structure

- `components/organisms/`: Journey flow composition panels.
- `components/molecules/renderers/`: callback field renderer components and shared renderer utilities.
- `utils/`: debug payload sanitation and trace helpers.

## Runtime Flow

1. `JourneyFullScreen` renders `JourneyClientPanel`.
2. `JourneyClientPanel` reads Journey tuple state/actions from `useJourney(journeyClient)`.
3. `useJourneyForm(node)` maps callbacks into normalized fields, manages form values, and derives submit planning.
4. User input is tracked by normalized field id (`<type>:<typeIndex>`).
5. `form.input` and `form.issues` come from helper submit planning.
6. Screen handles explicit integrations:
   - `DeviceProfileCallback` -> `collectDeviceProfileForJourney(...)`
   - `PollingWaitCallback` -> automatic timed `next({})` using callback `waitTime`
7. Terminal states and logout are rendered directly in `JourneyClientPanel`.
8. `JourneyDebugPanel` remains available for callback/progression tracing.

## Components

### `components/organisms/JourneyClientPanel.tsx`

Top-level helper-driven Journey UI orchestrator.

Responsibilities:
- Composes focused Journey panel subcomponents.
- Uses `useJourney(...)` and `useJourneyForm(node)` directly.
- Owns only screen-level behavior not provided by package helpers
  (journey suggestions, debug timeline, session card, polling strategy, and explicit integrations).

### `components/organisms/JourneyContinuePanel.tsx`

Continue-node rendering section:
- callback field rendering
- integration-required/unsupported notices
- device profile action
- resume action
- manual continue action
- auto-polling informational state

### `components/organisms/JourneyStartPanel.tsx`

Journey bootstrap controls:
- journey name input
- recent journey chips
- start button

### `components/organisms/JourneyDebugPanel.tsx`

Displays sanitized callback and progression debug events.

### `components/molecules/renderers/JourneyFieldRenderer.tsx`

Routes each normalized callback field to a specialized renderer component:
- `JourneyBooleanField`
- `JourneyChoiceField`
- `JourneyKbaField`
- `JourneyOutputField`
- `JourneyTextField`
- `JourneyUnsupportedField`

## Supporting Utilities

### `utils/clientPanel.ts`

Shared Journey panel helper functions:
- session display-name extraction
- polling wait-time parsing

## Explicit Integration Paths

### Device Profile

1. Detect `DeviceProfileCallback` in normalized fields.
2. Call `collectDeviceProfileForJourney(journeyClient, collectors)`.
3. If successful and no additional manual callbacks are pending, call `next({})`.

### Polling Wait

1. Detect `PollingWaitCallback` in normalized fields.
2. Start a timer using callback `waitTime` (fallback to sample default).
3. On timer completion, call `next({})` automatically.

## Security Notes

- Debug payloads are sanitized via `utils/debug.ts`.
- Sensitive keys (`password`, `token`, `secret`, etc.) are redacted before rendering.
- Sample debug output is for local validation; do not log raw callback data in production.
