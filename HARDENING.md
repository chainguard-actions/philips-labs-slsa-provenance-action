<!-- markdownlint-disable -->

# Hardening Report: philips-labs--slsa-provenance-action/v0.7.0

> This file was generated automatically by the hardening agent.

**Policy SHA:** `d636be7e43ef829af6e853da6b3c7566db9f72fe`

**Test Policy SHA:** `843adf9e4b8f85d0c08b27b9d0b09dd094b54702`

**Harden Agent Version:** `1`

Action **philips-labs--slsa-provenance-action/v0.7.0** was hardened automatically. 7 finding(s) were identified and resolved across 2 iteration(s).

## Findings Fixed

### script-injection (severity: high)

Rule (a): The 'compose arguments' step in action.yaml directly interpolates user-controlled inputs inside a run: shell command. Specifically, ${{ inputs.command }}, ${{ inputs.subcommand }}, and ${{ inputs.arguments }} are interpolated directly into the shell script, allowing an attacker to inject arbitrary shell commands. Example offending lines: `args=(${{ inputs.command }})`, `args+=(${{ inputs.subcommand }})`, `args+=(${{ inputs.arguments }})`.

Locations:

- `action.yaml:43`
- `action.yaml:44`
- `action.yaml:49`

### script-injection (severity: high)

Rule (a): The 'Generate provenance' step in action.yaml directly interpolates ${{ steps.compose-args.outputs.provenance_args }} inside a run: shell command. Step outputs can contain attacker-controlled content (derived from inputs.command, inputs.subcommand, inputs.arguments), enabling shell command injection. Offending line: `run: $INSTALL_PATH/slsa-provenance ${{ steps.compose-args.outputs.provenance_args }}`

Locations:

- `action.yaml:55`

### script-injection (severity: high)

Rule (b): The 'compose arguments' step uses unquoted shell variable expansions of env vars that hold workflow-controllable data. `echo ${GITHUB_CONTEXT}` and `echo ${RUNNER_CONTEXT}` are unquoted, allowing shell metacharacter injection from the github_context and runner_context inputs. These should be `echo "${GITHUB_CONTEXT}"` and `echo "${RUNNER_CONTEXT}"`.

Locations:

- `action.yaml:40`
- `action.yaml:41`

### github-env-injection (severity: high)

install-slsa-provenance.sh writes $INSTALL_PATH to $GITHUB_PATH without sanitization. INSTALL_PATH is set from the inputs.install-dir input (via the INSTALL_PATH env var in action.yaml), which is caller-controlled. The write `echo "$INSTALL_PATH" >> "${GITHUB_PATH:-...}"` does not apply the required `printf '%s' ... | tr -d '\n\r'` sanitization before writing to the special environment file, enabling newline injection into GITHUB_PATH.

Locations:

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

1. action.yaml - compose arguments step: Moved ${{ inputs.command }}, ${{ inputs.subcommand }}, and ${{ inputs.arguments }} out of the run: shell block into the step's env: map as INPUT_COMMAND, INPUT_SUBCOMMAND, and INPUT_ARGUMENTS respectively. These are now referenced as quoted shell variables ("${INPUT_COMMAND}", etc.) to prevent shell injection.

2. action.yaml - compose arguments step: Fixed unquoted echo ${GITHUB_CONTEXT} and echo ${RUNNER_CONTEXT} to use double quotes: echo "${GITHUB_CONTEXT}" and echo "${RUNNER_CONTEXT}".

3. action.yaml - Generate provenance step: Moved ${{ steps.compose-args.outputs.provenance_args }} out of the run: shell command into the step's env: map as PROVENANCE_ARGS, referenced as ${PROVENANCE_ARGS} in the shell command.

4. install-slsa-provenance.sh: Added newline sanitization before writing INSTALL_PATH to $GITHUB_PATH using `printf '%s' "$INSTALL_PATH" | tr -d '\n\r'`, storing the sanitized value in safe_install_path before the echo.

### Iteration 2

**Fixes applied:** github-env-injection, script-injection

**Notes:**

Fixed both high-severity findings in action.yaml:

1. github-env-injection (line 51): Sanitized each user-controlled input (INPUT_COMMAND, INPUT_SUBCOMMAND, INPUT_ARGUMENTS) with `printf '%s' ... | tr -d '\n\r'` before building the args array. Also sanitized the final args string before writing to $GITHUB_OUTPUT. Replaced the legacy `::set-output` mechanism with the modern `>> "$GITHUB_OUTPUT"` approach.

2. script-injection (line 57): Sanitized INSTALL_PATH with `printf '%s' ... | tr -d '\n\r'` and double-quoted the binary path as `"$safe_install_path/slsa-provenance"`. Split PROVENANCE_ARGS into a proper bash array using `read -ra prov_args <<< "${PROVENANCE_ARGS}"` and passed it as `"${prov_args[@]}"` to prevent shell metacharacter interpretation.

