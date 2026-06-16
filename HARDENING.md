<!-- markdownlint-disable -->

# Hardening Report: philips-labs--slsa-provenance-action/v0.8.0

> This file was generated automatically by the hardening agent.

**Policy SHA:** `d636be7e43ef829af6e853da6b3c7566db9f72fe`

**Test Policy SHA:** `843adf9e4b8f85d0c08b27b9d0b09dd094b54702`

**Harden Agent Version:** `1`

Action **philips-labs--slsa-provenance-action/v0.8.0** was hardened automatically. 6 finding(s) were identified and resolved across 2 iteration(s).

## Findings Fixed

### script-injection (severity: high)

Rule (a): Multiple direct ${{ ... }} expression interpolations appear inside run: shell command strings in action.yaml. (1) Line 44: `args=(${{ inputs.command }})` — attacker-controlled input interpolated directly into shell array construction. (2) Line 45: `args+=(${{ inputs.subcommand }})` — same issue. (3) Line 51: `args+=(${{ inputs.arguments }})` — same issue; inputs.arguments is a free-form string that can contain shell metacharacters. (4) Line 57: `run: $INSTALL_PATH/slsa-provenance ${{ steps.compose-args.outputs.provenance_args }}` — the step output (itself derived from the above inputs) is interpolated directly into the run: command. All four allow an attacker to inject arbitrary shell commands by supplying crafted input values.

Locations:

- `action.yaml:44`
- `action.yaml:45`
- `action.yaml:51`
- `action.yaml:57`

### script-injection (severity: high)

Rule (b): Unquoted shell variable expansions of untrusted env vars in the 'compose arguments' step. Line 41: `echo ${GITHUB_CONTEXT} | base64 -w 0` and line 42: `echo ${RUNNER_CONTEXT} | base64 -w 0` — GITHUB_CONTEXT and RUNNER_CONTEXT are set from inputs.github_context and inputs.runner_context respectively (attacker-controllable). The unquoted expansions allow word-splitting and glob expansion of shell metacharacters embedded in those values.

Locations:

- `action.yaml:41`
- `action.yaml:42`

### github-env-injection (severity: high)

The install-slsa-provenance.sh script (invoked by the 'install binary' step) writes the INSTALL_PATH environment variable directly to $GITHUB_PATH without sanitization: `echo "$INSTALL_PATH" >> "${GITHUB_PATH:-...}"`. INSTALL_PATH is inherited from the calling action step's env block where it is set to `${{ inputs.install-dir }}` (an attacker-controlled input). A newline embedded in inputs.install-dir would allow injection of arbitrary entries into GITHUB_PATH. The required sanitization step (`printf '%s' "$INSTALL_PATH" | tr -d '\n\r'`) is absent.

Locations:

- `install-slsa-provenance.sh:98`
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

1. action.yaml - compose arguments step: Moved ${{ inputs.command }}, ${{ inputs.subcommand }}, and ${{ inputs.arguments }} from the run: shell block into the env: block as INPUT_COMMAND, INPUT_SUBCOMMAND, INPUT_ARGUMENTS. Shell script now uses properly quoted "${INPUT_COMMAND}", "${INPUT_SUBCOMMAND}", "${INPUT_ARGUMENTS}".

2. action.yaml - Generate provenance step: Moved ${{ steps.compose-args.outputs.provenance_args }} from the run: shell command into the env: block as PROVENANCE_ARGS. Run command now uses ${PROVENANCE_ARGS}.

3. action.yaml - compose arguments step lines 41-42: Fixed unquoted ${GITHUB_CONTEXT} and ${RUNNER_CONTEXT} by switching from 'echo ${VAR}' to 'printf \'%s\' "${VAR}"' to prevent word-splitting and glob expansion.

4. install-slsa-provenance.sh line 98: Added sanitization of INSTALL_PATH before writing to $GITHUB_PATH using 'printf \'%s\' "$INSTALL_PATH" | tr -d \'\n\r\'' to strip embedded newlines that could inject arbitrary entries into GITHUB_PATH.

### Iteration 2

**Fixes applied:** github-env-injection, script-injection

**Notes:**

Fixed two high-severity findings in action.yaml:
1. github-env-injection (line 53): Added newline sanitization using `printf '%s' "${args[*]}" | tr -d '\n\r'` before writing to the legacy ::set-output mechanism. The sanitized value is stored in `safe_args` and used in the echo command.
2. script-injection (line 63): Replaced the unquoted `${PROVENANCE_ARGS}` shell expansion with a safe pattern: `read -ra provenance_args <<< "${PROVENANCE_ARGS}"` splits the space-separated args into a bash array, then `"$INSTALL_PATH/slsa-provenance" "${provenance_args[@]}"` executes with proper quoting, preventing shell metacharacter injection.

