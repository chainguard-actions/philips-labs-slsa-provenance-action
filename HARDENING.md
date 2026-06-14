<!-- markdownlint-disable -->

# Hardening Report: philips-labs--slsa-provenance-action/v0.7.2

> This file was generated automatically by the hardening agent.

**Policy SHA:** `d636be7e43ef829af6e853da6b3c7566db9f72fe`

**Test Policy SHA:** `843adf9e4b8f85d0c08b27b9d0b09dd094b54702`

**Harden Agent Version:** `1`

Action **philips-labs--slsa-provenance-action/v0.7.2** was hardened automatically. 5 finding(s) were identified and resolved across 3 iteration(s).

## Findings Fixed

### script-injection (severity: high)

Multiple ${{ }} expressions are directly interpolated inside run: shell command strings in action.yaml, violating sub-rule (a). Attacker-controlled inputs are expanded by the YAML template engine before the shell ever sees them, enabling command injection:
- Line 44: `args=(${{ inputs.command }})` — inputs.command injected directly into shell array construction
- Line 45: `args+=(${{ inputs.subcommand }})` — inputs.subcommand injected directly into shell array construction
- Line 50: `args+=(${{ inputs.arguments }})` — inputs.arguments injected directly into shell array construction
- Line 57: `run: $INSTALL_PATH/slsa-provenance ${{ steps.compose-args.outputs.provenance_args }}` — step output injected directly into shell command

Locations:

- `action.yaml:44`
- `action.yaml:45`
- `action.yaml:50`
- `action.yaml:57`

### github-env-injection (severity: high)

In install-slsa-provenance.sh (invoked by the 'install binary' step of action.yaml), the variable $INSTALL_PATH is written directly to $GITHUB_PATH without sanitization: `echo "$INSTALL_PATH" >> "${GITHUB_PATH:-...}"`. INSTALL_PATH is set from the untrusted input `inputs.install-dir` (via `env: INSTALL_PATH: ${{ inputs.install-dir }}`). A value containing newline characters could inject arbitrary entries into GITHUB_PATH. The required sanitization step (`printf '%s' "$INSTALL_PATH" | tr -d '\n\r'`) is missing before the write.

Locations:

- `install-slsa-provenance.sh:100`
- `action.yaml:37`

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

Fixed three categories of vulnerabilities:
1. script-injection in action.yaml: Moved ${{ inputs.command }}, ${{ inputs.subcommand }}, and ${{ inputs.arguments }} from the run: shell block into the env: block (as INPUT_COMMAND, INPUT_SUBCOMMAND, INPUT_ARGUMENTS). Also moved ${{ steps.compose-args.outputs.provenance_args }} from the run: shell command into the env: block as PROVENANCE_ARGS.
2. github-env-injection in install-slsa-provenance.sh: Added sanitization of INSTALL_PATH before writing to GITHUB_PATH using `safe_install_path="$(printf '%s' "$INSTALL_PATH" | tr -d '\n\r')"` to strip newline characters that could inject arbitrary entries.
3. static-inline-injection findings reference the same action.yaml file and are resolved by the same script-injection fixes above.

### Iteration 2

**Fixes applied:** script-injection

**Notes:**

Fixed two script-injection findings in action.yaml:
1. 'compose arguments' step (line 40): Double-quoted all unquoted variable expansions — `${GITHUB_CONTEXT}` and `${RUNNER_CONTEXT}` inside echo command substitutions, and `$INPUT_COMMAND`, `$INPUT_SUBCOMMAND`, `$INPUT_ARGUMENTS` in bash array assignments.
2. 'Generate provenance' step (line 63): Double-quoted `$INSTALL_PATH` in the binary path, and safely split `$PROVENANCE_ARGS` into a bash array using `read -ra provenance_args <<< "$PROVENANCE_ARGS"` then expanded as `"${provenance_args[@]}"` to prevent shell metacharacter injection while correctly passing multiple arguments.

### Iteration 3

**Fixes applied:** github-env-injection

**Notes:**

Fixed the newline injection vulnerability in the 'compose arguments' step of action.yaml. The original code wrote `${args[@]}` (containing caller-controlled inputs: $INPUT_ARGUMENTS, $INPUT_COMMAND, $INPUT_SUBCOMMAND) directly to `::set-output` without sanitization. The fix introduces a sanitization step: `safe_args="$(printf '%s' "${args[*]}" | tr -d '\n\r')"` before writing to `::set-output`, stripping all newline and carriage return characters to prevent newline injection attacks.

