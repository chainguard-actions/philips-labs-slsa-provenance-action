<!-- markdownlint-disable -->

# Hardening Report: philips-labs--slsa-provenance-action/v0.9.0

> This file was generated automatically by the hardening agent.

**Policy SHA:** `d636be7e43ef829af6e853da6b3c7566db9f72fe`

**Test Policy SHA:** `843adf9e4b8f85d0c08b27b9d0b09dd094b54702`

**Harden Agent Version:** `1`

Action **philips-labs--slsa-provenance-action/v0.9.0** was hardened automatically. 5 finding(s) were identified and resolved across 2 iteration(s).

## Findings Fixed

### script-injection (severity: high)

Sub-rule (a): Multiple ${{ }} expressions are directly interpolated inside run: shell command strings in action.yaml, allowing an attacker-controlled value to be executed as shell code.

1. Line 44: `args=(${{ inputs.command }})` — inputs.command injected directly into shell array construction.
2. Line 45: `args+=(${{ inputs.subcommand }})` — inputs.subcommand injected directly.
3. Line 50: `args+=(${{ inputs.arguments }})` — inputs.arguments injected directly; this is the most dangerous as it accepts arbitrary CLI arguments.
4. Line 57: `run: $INSTALL_PATH/slsa-provenance ${{ steps.compose-args.outputs.provenance_args }}` — the composed args (which themselves contain unsanitized inputs) are interpolated directly into the shell command.

Sub-rule (b): Unquoted shell variable expansions of untrusted data on lines 40–41:
- `echo ${GITHUB_CONTEXT} | base64 -w 0` — GITHUB_CONTEXT holds ${{ inputs.github_context }} (the full github context JSON) and is unquoted, allowing shell metacharacter injection.
- `echo ${RUNNER_CONTEXT} | base64 -w 0` — RUNNER_CONTEXT holds ${{ inputs.runner_context }} and is unquoted.

All of these should use env: vars with proper quoting and no direct ${{ }} in run: blocks.

Locations:

- `action.yaml:40`
- `action.yaml:41`
- `action.yaml:44`
- `action.yaml:45`
- `action.yaml:50`
- `action.yaml:57`

### github-env-injection (severity: high)

Unsanitized untrusted input values are written to GitHub special environment files without the required `printf '%s' ... | tr -d '\n\r'` sanitization step.

1. action.yaml line 52: `echo "provenance_args=${args[@]}" >> $GITHUB_OUTPUT` — the args array contains values derived directly from ${{ inputs.command }}, ${{ inputs.subcommand }}, and ${{ inputs.arguments }} (all interpolated without sanitization on lines 44, 45, 50). A newline in any of these inputs would allow injection of additional key=value pairs into GITHUB_OUTPUT, enabling environment variable poisoning for subsequent steps.

2. install-slsa-provenance.sh (last line): `echo "$INSTALL_PATH" >> "${GITHUB_PATH:-...}"` — INSTALL_PATH is set from ${{ inputs.install-dir }} (action.yaml line 35) and written directly to $GITHUB_PATH without sanitization. A newline in inputs.install-dir would allow an attacker to inject arbitrary paths into GITHUB_PATH.

Locations:

- `action.yaml:52`
- `action.yaml:35`
- `install-slsa-provenance.sh:97`

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

Fixed all script-injection and github-env-injection findings in action.yaml and install-slsa-provenance.sh:

1. action.yaml - compose arguments step: Moved ${{ inputs.command }}, ${{ inputs.subcommand }}, and ${{ inputs.arguments }} from the run: block into the env: block (as INPUT_COMMAND, INPUT_SUBCOMMAND, INPUT_ARGUMENTS). They are now referenced as properly double-quoted shell variables.

2. action.yaml - compose arguments step: Fixed unquoted ${GITHUB_CONTEXT} and ${RUNNER_CONTEXT} by replacing `echo ${VAR}` with `printf '%s' "${VAR}"` to prevent shell metacharacter injection.

3. action.yaml - compose arguments step: Added newline sanitization before writing to GITHUB_OUTPUT: `safe_args=$(printf '%s' "${args[*]}" | tr -d '\n\r')` then `echo "provenance_args=${safe_args}" >> "$GITHUB_OUTPUT"`.

4. action.yaml - Generate provenance step: Moved ${{ steps.compose-args.outputs.provenance_args }} from the run: block into the env: block as PROVENANCE_ARGS, referenced as ${PROVENANCE_ARGS} in the shell command.

5. install-slsa-provenance.sh: Added sanitization of INSTALL_PATH before writing to GITHUB_PATH: `safe_install_path=$(printf '%s' "$INSTALL_PATH" | tr -d '\n\r')` then writing $safe_install_path instead.

### Iteration 2

**Fixes applied:** script-injection

**Notes:**

Fixed the unquoted shell variable expansion in the 'Generate provenance' step. Changed `run: $INSTALL_PATH/slsa-provenance ${PROVENANCE_ARGS}` to use `read -ra args <<< "${PROVENANCE_ARGS}"` to safely split the space-separated arguments into a bash array, then expand with `"$INSTALL_PATH/slsa-provenance" "${args[@]}"`. This prevents shell metacharacters (`;`, `|`, `&`, `$(...)`, etc.) embedded in PROVENANCE_ARGS from being interpreted by the shell, while still correctly passing multiple arguments to the binary.

