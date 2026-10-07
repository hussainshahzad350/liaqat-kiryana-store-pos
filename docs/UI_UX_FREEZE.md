# UI/UX work boundary

Effective 2026-10-04, by the user's instruction: freeze the functional application and focus the next work on UI and UX.

The user subsequently authorized implementation of the redesign. Track its
presentation changes in [UI_UX_IMPLEMENTATION_PLAN.md](UI_UX_IMPLEMENTATION_PLAN.md).
The audit hashes remain historical evidence of the pre-redesign application;
protected business files must continue matching them.

## Protected behavior

Keep database schema/migrations, monetary units and rounding, stock calculations and movements, posting/reversal, repository contracts, PIN/recovery/lockout policy, exports, backup/restore, printing, routes, shortcuts and persistence behavior unchanged. Keep existing business regression coverage. A layout repair must not silently alter these contracts.

Future presentation work may change widget composition, responsive layouts, spacing, colors, typography, borders, navigation presentation, accessible labels, validation presentation and feedback wording. Preserve the underlying actions, validation rules and route destinations. Improving a placeholder's wording or disabled presentation does not authorize implementing its missing business operation.

## Audit baseline

The audit captured the current application using temporary synthetic data. It added audit harnesses and documentation only. All production files under `lib/` are recorded in [production-freeze.json](ui-ux-audit/production-freeze.json). Compare against that baseline to prove the audit itself did not alter production code. This includes existing uncommitted work; it is not a comparison against Git HEAD.

Audit evidence includes both live navigation and production dialog/snackbar specimens. A specimen confirms appearance, not execution of the associated business operation. Dynamic messages use labeled sample values. The native Windows frame, operating-system file pickers and physical printer dialogs are outside the Flutter-rendered capture surface.

## Verification policy

Use focused presentation checks while iterating; run the complete regression suite at each completed UI/UX phase, as the user requested. Resolve implementation bugs without requesting routine correction approval. During this audit, document observed production layout defects for the UI implementation phase; repair the audit harness when needed to finish capturing evidence.
