# DaVinci Sample UI Documentation

This folder contains the helper-only DaVinci sample implementation used by the sample app.

The sample is intentionally UI-owned:

- SDK (`@ping-identity/rn-davinci`) provides DaVinci state/actions and helper APIs.
- Sample app renders collectors and controls flow progression.
- Session state is re-resolved on every screen focus so that external revocations are reflected immediately.
- Native SDK remains authoritative for collector validation and flow progression.

## Folder Structure

- `components/organisms/`: DaVinci flow composition panels.
- `components/molecules/`: collector field renderer components and shared renderer utilities.
- `components/atoms/`: low-level field primitives (labels, error lists, picker modal).
- `hooks/`: auto-start effect, session controller, and panel controller composition hooks.

## Runtime Flow

1. `DaVinciClientPanel` renders the appropriate state panel based on the active node type.
2. `useDaVinciClientPanelController` composes `useDaVinci`, `useDaVinciForm`, `useDaVinciSessionController`, and `useDaVinciAutoStartEffect` into a single flat panel contract.
3. `useDaVinciSessionController` checks for an active session on every screen focus before allowing auto-start.
4. `useDaVinciAutoStartEffect` fires `start()` once when no node and no active session are present.
5. When a `ContinueNode` is active, `DaVinciContinueNodePanel` renders the collector form.
6. `DaVinciFieldRenderer` routes each normalized collector to a dedicated molecule component.
7. User input is tracked by collector key.
8. `form.canSubmit` and `form.issues` come from `useDaVinciForm` submit planning.
9. Terminal states (`SuccessNode`, `ErrorNode`, `FailureNode`) and logout are rendered directly in `DaVinciClientPanel`.

## Components

### `components/organisms/DaVinciClientPanel.tsx`

Top-level helper-driven DaVinci UI orchestrator.

Responsibilities:

- Composes focused DaVinci panel subcomponents.
- Uses `useDaVinciClientPanelController` directly.
- Owns only screen-level behavior not provided by package helpers
  (auto-start gating, session card, loading overlay, and terminal-state rendering).

### `components/organisms/DaVinciContinueNodePanel.tsx`

Continue-node rendering section:

- unsupported-field skip notices
- collector field rendering via `DaVinciFieldRenderer`
- fallback submit button when no interactive submit collector is present
- form validation warning

### `components/molecules/DaVinciFieldRenderer.tsx`

Routes each normalized DaVinci collector to the appropriate molecule component:

- `DaVinciTextField` — `TEXT`
- `DaVinciPasswordField` — `PASSWORD`, `PASSWORD_VERIFY`
- `DaVinciSubmitButton` — `SUBMIT_BUTTON`
- `DaVinciFlowButton` — `ACTION`, `FLOW_BUTTON`, `FLOW_LINK`
- `DaVinciLabelField` — `LABEL`
- `DaVinciSingleSelectField` — `SINGLE_SELECT`, `DROPDOWN`, `RADIO`
- `DaVinciMultiSelectField` — `MULTI_SELECT`, `COMBOBOX`, `CHECKBOX`
- `DaVinciPhoneNumberField` — `PHONE_NUMBER`
- `DaVinciDeviceField` — `DEVICE_REGISTRATION`, `DEVICE_AUTHENTICATION`
- `DaVinciUnsupportedField` — all unrecognised collector types

### `components/atoms/DaVinciErrorList.tsx`

Renders a stack of inline validation error messages beneath a field. Maps `REQUIRED` error codes to a human-readable sentence; falls back to the SDK-provided message for all other codes.

### `components/atoms/DaVinciFieldLabel.tsx`

Renders a field label with an optional required indicator.

### `components/atoms/PickerModal.tsx`

Modal picker used by `DaVinciSingleSelectField` and `DaVinciMultiSelectField` on iOS and Android.

## Supporting Hooks

### `hooks/useDaVinciClientPanelController.ts`

Composes DaVinci sample panel behavior into a single controller hook:

- pairs `useDaVinci` (flow + session actions) with `useDaVinciForm` (headless form state)
- delegates session lifecycle to `useDaVinciSessionController`
- delegates auto-start timing to `useDaVinciAutoStartEffect`
- exposes a flat `UseDaVinciClientPanelControllerResult` contract consumed by `DaVinciClientPanel`

### `hooks/useDaVinciSessionController.ts`

Session/bootstrap state manager:

- re-resolves the active session on every screen focus via `useFocusEffect`
- marks the session active immediately when the flow reaches `SuccessNode`
- exposes `hasActiveSession`, `setHasActiveSession`, and `isSessionCheckRunning`

### `hooks/useDaVinciAutoStartEffect.ts`

Auto-starts the DaVinci flow once when no node and no active session are present:

- guards against duplicate starts with a `useRef` flag
- resets the flag if `start()` fails so the user can retry

## Explicit Integration Paths

### Device Registration and Authentication

1. `DaVinciFieldRenderer` dispatches `DEVICE_REGISTRATION` and `DEVICE_AUTHENTICATION` collectors to `DaVinciDeviceField`.
2. `DaVinciDeviceField` renders each device option as a tappable card.
3. Selecting a card calls `onChange` with `{ type }` for registration or `{ type, id, description }` for authentication.
4. The value is included in the `next()` payload by `useDaVinciForm`.

### Fallback Submit

1. `DaVinciContinueNodePanel` checks whether the collector list contains at least one `SUBMIT_BUTTON`, `ACTION`, or `FLOW_BUTTON`.
2. If none are present, a fallback "Next" button is rendered to allow progression.

## Security Notes

- Collector values containing passwords or secrets are never logged by sample components.
- `DaVinciErrorList` surfaces only SDK-provided validation messages; no raw server payloads are rendered.
- Sample output is for local validation; do not log raw collector data in production.
