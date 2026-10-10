<!-- markdownlint-disable -->

# Hardening Report: philips-labs--slsa-provenance-action/v0.9.0

> This file was generated automatically by the hardening agent.

**Policy SHA:** `d636be7e43ef829af6e853da6b3c7566db9f72fe`

**Test Policy SHA:** `843adf9e4b8f85d0c08b27b9d0b09dd094b54702`

**Harden Agent Version:** `2`

Action **philips-labs--slsa-provenance-action/v0.9.0** was hardened automatically. 5 finding(s) were identified and resolved across 1 iteration(s).

## Findings Fixed

### script-injection (severity: high)

Sub-rule (a): Multiple `${{ ... }}` expressions are interpolated directly inside `run:` shell command strings in action.yaml.

1. Line 43: `args=(${{ inputs.command }})` — the `inputs.command` value is injected directly into the shell array without quoting or env-var indirection, allowing an attacker to inject arbitrary shell commands.
2. Line 44: `args+=(${{ inputs.subcommand }})` — same issue with `inputs.subcommand`.
3. Line 49: `args+=(${{ inputs.arguments }})` — same issue with `inputs.arguments`; this input is caller-controlled and particularly dangerous.
4. Line 56: `run: $INSTALL_PATH/slsa-provenance ${{ steps.compose-args.outputs.provenance_args }}` — the step output (which was built from the above untrusted inputs) is interpolated directly into the shell command string, compounding the injection risk.

All four occurrences allow a caller to supply values containing shell metacharacters (`;`, `|`, `&`, `$(...)`, backticks, etc.) that will be interpreted by bash before any quoting takes effect.

Locations:

- `action.yaml:43`
- `action.yaml:44`
- `action.yaml:49`
- `action.yaml:56`

### github-env-injection (severity: high)

Two unsanitized writes to GitHub special environment files:

1. action.yaml line 51: `echo "provenance_args=${args[@]}" >> $GITHUB_OUTPUT` — the `args` array was built directly from `${{ inputs.command }}`, `${{ inputs.subcommand }}`, and `${{ inputs.arguments }}` (all caller-controlled). No `printf '%s' ... | tr -d '\n\r'` sanitization is applied before writing to `$GITHUB_OUTPUT`. A newline in any of these inputs can inject arbitrary key=value pairs into the output file, poisoning subsequent steps.

2. install-slsa-provenance.sh (last line): `echo "$INSTALL_PATH" >> "${GITHUB_PATH:-...}"` — `INSTALL_PATH` is set by the calling step's `env:` block from `${{ inputs.install-dir }}` (a caller-controlled input). The value is written directly to `$GITHUB_PATH` without sanitization (`printf '%s' "$INSTALL_PATH" | tr -d '\n\r'`), allowing a newline-containing path to inject additional entries into `$GITHUB_PATH`.

Locations:

- `action.yaml:51`
- `install-slsa-provenance.sh:96`

### static-inline-injection (severity: high)

shell injection: expression "${{ inputs.command }}" appears directly in run: block of step "compose arguments"; move to env: map

Locations:

- `action.yml:46`

### static-inline-injection (severity: high)

shell injection: expression "${{ inputs.subcommand }}" appears directly in run: block of step "compose arguments"; move to env: map

Locations:

- `action.yml:47`

### static-inline-injection (severity: high)

shell injection: expression "${{ inputs.arguments }}" appears directly in run: block of step "compose arguments"; move to env: map

Locations:

- `action.yml:52`

## Iteration Notes

### Iteration 1

**Fixes applied:** script-injection, github-env-injection, static-inline-injection

**Notes:**

Fixed all findings in action.yaml and install-slsa-provenance.sh:

1. **script-injection / static-inline-injection**: Merged the 'compose arguments' and 'Generate provenance' steps into a single 'Generate provenance' step. All ${{ }} expressions moved to env: blocks (INPUT_COMMAND, INPUT_SUBCOMMAND, INPUT_ARGUMENTS, GITHUB_CONTEXT, RUNNER_CONTEXT, INSTALL_PATH). INPUT_COMMAND and INPUT_SUBCOMMAND are single values used with double-quoting in the array. INPUT_ARGUMENTS is a list input tokenized via xargs with the guarded while/read/NUL-delimited loop pattern.

2. **github-env-injection (action.yaml)**: Eliminated entirely by removing the intermediate $GITHUB_OUTPUT write - the args array is built and used directly in the same step.

3. **github-env-injection (install-slsa-provenance.sh)**: Added sanitization of INSTALL_PATH before writing to $GITHUB_PATH: `safe_install_path="$(printf '%s' "$INSTALL_PATH" | tr -d '\n\r')"` then writing `$safe_install_path` instead of `$INSTALL_PATH`.

