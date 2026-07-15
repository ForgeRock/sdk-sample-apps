## 0.0.1

#### Added
- Added `ping_journey`, a Pigeon-generated bridge over the native Ping Journey SDK: `configureJourney`, `start`, `next`, `getSession`, `signOff`, and `dispose` [SDKS-4613]
- Added Dart sealed types for `JourneyNode` (`ContinueNode`/`SuccessNode`/`ErrorNode`/`FailureNode`) and the v1 callback set (`NameCallback`, `PasswordCallback`, `ValidatedUsernameCallback`, `ValidatedPasswordCallback`, `ChoiceCallback`, `KbaCreateCallback`, `TermsAndConditionsCallback`, `TextInputCallback`, `TextOutputCallback`, `StringAttributeInputCallback`, `NumberAttributeInputCallback`, `BooleanAttributeInputCallback`) [SDKS-4613]
- Pinned both platforms to native Ping SDK `2.0.0` (Android Maven, iOS SPM)
