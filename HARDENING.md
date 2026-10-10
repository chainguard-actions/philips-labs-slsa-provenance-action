<!-- markdownlint-disable -->

# Hardening Report: philips-labs--slsa-provenance-action/v0.7.1

> This file was generated automatically by the hardening agent.

**Policy SHA:** `d636be7e43ef829af6e853da6b3c7566db9f72fe`

**Test Policy SHA:** `843adf9e4b8f85d0c08b27b9d0b09dd094b54702`

**Harden Agent Version:** `2`

Action **philips-labs--slsa-provenance-action/v0.7.1** was hardened automatically. 6 finding(s) were identified and resolved across 1 iteration(s).

## Findings Fixed

### script-injection (severity: high)

Sub-rule (a): Multiple ${{ }} expressions are directly interpolated inside run: shell command strings in action.yaml. Specifically: `args=(${{ inputs.command }})`, `args+=(${{ inputs.subcommand }})`, `args+=(${{ inputs.arguments }})` (in the 'compose arguments' step), and `$INSTALL_PATH/slsa-provenance ${{ steps.compose-args.outputs.provenance_args }}` (in the 'Generate provenance' step). An attacker controlling these inputs can inject arbitrary shell commands. inputs.command and inputs.subcommand have defaults but are not required, and inputs.arguments is required — all are caller-controlled. steps.compose-args.outputs.provenance_args is derived from those same untrusted inputs.

Locations:

- `action.yaml:43`
- `action.yaml:44`
- `action.yaml:48`
- `action.yaml:57`

### script-injection (severity: high)

Sub-rule (b): In the 'compose arguments' step, the env vars ${GITHUB_CONTEXT} and ${RUNNER_CONTEXT} (which hold inputs.github_context and inputs.runner_context — caller-controlled values) are expanded unquoted inside command substitutions: `$(echo ${GITHUB_CONTEXT} | base64 -w 0)` and `$(echo ${RUNNER_CONTEXT} | base64 -w 0)`. Unquoted shell variable expansion allows shell metacharacters (semicolons, pipes, backticks, etc.) embedded in the values to be interpreted by the shell, enabling command injection.

Locations:

- `action.yaml:40`
- `action.yaml:41`

### github-env-injection (severity: high)

In install-slsa-provenance.sh (invoked by the 'install binary' step of action.yaml), the variable $INSTALL_PATH — which is set from inputs.install-dir via the INSTALL_PATH env var and is therefore caller-controlled — is written directly to $GITHUB_PATH without the required sanitization step (`printf '%s' ... | tr -d '\n\r'`). A value containing a newline character could inject additional entries into GITHUB_PATH, potentially hijacking PATH-based binary lookups in subsequent steps. The offending line is: `echo "$INSTALL_PATH" >> "${GITHUB_PATH:-"$INSTALL_PATH/GITHUB_PATH"}"`

Locations:

- `install-slsa-provenance.sh:100`
- `action.yaml:33`

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

1. script-injection (Sub-rule a): Moved inputs.command, inputs.subcommand, and inputs.arguments from inline ${{ }} expressions in run: blocks to env: maps as INPUT_COMMAND, INPUT_SUBCOMMAND, INPUT_ARGUMENTS. Used the xargs/read-loop idiom to safely tokenize them into bash arrays.

2. script-injection (Sub-rule b): Fixed unquoted ${GITHUB_CONTEXT} and ${RUNNER_CONTEXT} in command substitutions by replacing `echo ${VAR}` with `printf '%s' "${VAR}"`, which properly quotes the variables and prevents shell metacharacter interpretation.

3. github-env-injection: In install-slsa-provenance.sh, sanitized $INSTALL_PATH before writing to $GITHUB_PATH using `printf '%s' "$INSTALL_PATH" | tr -d '\n\r'` to strip newlines.

4. static-inline-injection: Moved ${{ steps.compose-args.outputs.provenance_args }} from the Generate provenance step's run: block to an env var PROVENANCE_ARGS, then safely tokenized it with the xargs/read-loop idiom before passing to the binary.

