<!-- markdownlint-disable -->

# Hardening Report: philips-labs--slsa-provenance-action/v0.8.0

> This file was generated automatically by the hardening agent.

**Policy SHA:** `d636be7e43ef829af6e853da6b3c7566db9f72fe`

**Test Policy SHA:** `843adf9e4b8f85d0c08b27b9d0b09dd094b54702`

**Harden Agent Version:** `2`

Action **philips-labs--slsa-provenance-action/v0.8.0** was hardened automatically. 5 finding(s) were identified and resolved across 2 iteration(s).

## Findings Fixed

### script-injection (severity: high)

Multiple direct ${{ }} expression interpolations appear inside run: shell command strings in action.yaml, violating sub-rule (a). (1) Line 43: `args=(${{ inputs.command }})` — the user-controlled input `inputs.command` is interpolated directly into the shell script, allowing an attacker to inject arbitrary shell commands. (2) Line 44: `args+=(${{ inputs.subcommand }})` — same issue with `inputs.subcommand`. (3) Line 47: `args+=(${{ inputs.arguments }})` — same issue with `inputs.arguments`. (4) Line 57: `$INSTALL_PATH/slsa-provenance ${{ steps.compose-args.outputs.provenance_args }}` — the step output `steps.compose-args.outputs.provenance_args` (itself derived from attacker-controlled inputs) is interpolated directly into the shell command. All four cases allow shell metacharacter injection before the shell ever sees the value.

Locations:

- `action.yaml:43`
- `action.yaml:44`
- `action.yaml:47`
- `action.yaml:57`

### github-env-injection (severity: high)

In install-slsa-provenance.sh (invoked by the 'install binary' step of action.yaml), the variable `$INSTALL_PATH` is written directly to `$GITHUB_PATH` without sanitization: `echo "$INSTALL_PATH" >> "${GITHUB_PATH:-...}"`. `INSTALL_PATH` is set from `${{ inputs.install-dir }}` via the step's `env:` block — an attacker-controlled input. No `printf '%s' ... | tr -d '\n\r'` sanitization is applied before the write, so a newline-containing value could inject arbitrary entries into GITHUB_PATH (environment file injection).

Locations:

- `install-slsa-provenance.sh:96`
- `action.yaml:35`

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

1. action.yaml - compose arguments step: Moved ${{ inputs.command }}, ${{ inputs.subcommand }}, and ${{ inputs.arguments }} from inline run: shell strings into the env: block as INPUT_COMMAND, INPUT_SUBCOMMAND, INPUT_ARGUMENTS. Used the xargs/read-loop tokenization idiom (with guards) since these are argument-list inputs.

2. action.yaml - Generate provenance step: Moved ${{ steps.compose-args.outputs.provenance_args }} from inline run: shell string into the env: block as PROVENANCE_ARGS. Used the same xargs/read-loop tokenization idiom to safely expand the argument list.

3. install-slsa-provenance.sh line 96: Added sanitization of INSTALL_PATH before writing to GITHUB_PATH using `printf '%s' "$INSTALL_PATH" | tr -d '\n\r'` to prevent newline injection into the GITHUB_PATH environment file.

### Iteration 2

**Fixes applied:** script-injection

**Notes:**

Fixed unquoted variable expansions in the 'compose arguments' step of action.yaml. Changed `echo ${GITHUB_CONTEXT}` to `echo "${GITHUB_CONTEXT}"` and `echo ${RUNNER_CONTEXT}` to `echo "${RUNNER_CONTEXT}"` on lines 37-38. This prevents shell metacharacters in attacker-controlled input values (github_context and runner_context) from being interpreted as shell commands during the base64 encoding step.

