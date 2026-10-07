# Mouse input verification — 2026-10-06

UI scope: optional app-wide on-screen keyboard and cart quantity arrows.
Field formatters, callbacks, monetary calculations and payment processing remain
in the existing flow. All 69 protected Dart files under core, bloc, domain and
models matched the hashes captured before this change.

- Static analysis: no issues.
- Phase-end VM suite: 522 passed, one optional test skipped.
- Native mouse checkout: two scenarios passed, English/light and Urdu/dark at
  1024×720. Each clicks through PIN entry, product search, quantity, price,
  discount and payment. Isolated database assertions verify the exact invoice
  total, product quantity/price and Cash/Bank Transfer method.
- Existing native keyboard suite: four scenarios passed, covering Tab navigation
  and F9 checkout. Test-runner teardown is reported as an additional passing case.
- Focused widget coverage includes real mouse clicks on the keyboard launcher,
  masked PIN input, formatters, cancel, read-only fields, English/Urdu layouts,
  light/dark themes and quantity callbacks. These cases are included in the VM run.

Native screenshots: `build/mouse-input-review/`. Logs: `.local/mouse-analyze.log`,
`.local/mouse-phase-tests.log`, `.local/mouse-input-native.log` and
`.local/mouse-keyboard-regression.log`. Tests use disposable databases and do not
modify the live store or the persistent performance-lab dataset.

The complete cashier cycle was verified. This does not claim a mouse-only
acceptance run of every administrative workflow.
