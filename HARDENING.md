<!-- markdownlint-disable -->

# Hardening Report: philips-labs--slsa-provenance-action/v0.7.0

> This file was generated automatically by the hardening agent.

**Policy SHA:** `d636be7e43ef829af6e853da6b3c7566db9f72fe`

**Test Policy SHA:** `843adf9e4b8f85d0c08b27b9d0b09dd094b54702`

**Harden Agent Version:** `2`

Action **philips-labs--slsa-provenance-action/v0.7.0** was hardened automatically. 6 finding(s) were identified and resolved across 1 iteration(s).

## Findings Fixed

### script-injection (severity: high)

Sub-rule (a): The 'compose arguments' step directly interpolates untrusted inputs into the run: shell script without going through env: variables. Specifically: `args=(${{ inputs.command }})`, `args+=(${{ inputs.subcommand }})`, and `args+=(${{ inputs.arguments }})` allow an attacker-controlled value to be parsed by the shell as arbitrary commands. Sub-rule (b): `${GITHUB_CONTEXT}` and `${RUNNER_CONTEXT}` are used unquoted in `echo ${GITHUB_CONTEXT} | base64 -w 0` and `echo ${RUNNER_CONTEXT} | base64 -w 0`, allowing shell metacharacter injection from workflow-controlled env vars.

Locations:

- `action.yaml:42`

### script-injection (severity: high)

Sub-rule (a): The 'Generate provenance' step directly interpolates `${{ steps.compose-args.outputs.provenance_args }}` into the run: shell command string. Step outputs are workflow-controllable and this interpolation allows shell command injection before the shell ever sees the value.

Locations:

- `action.yaml:56`

### github-env-injection (severity: high)

The install-slsa-provenance.sh script writes `$INSTALL_PATH` to `$GITHUB_PATH` without sanitization: `echo "$INSTALL_PATH" >> "${GITHUB_PATH:-...}"`. The `INSTALL_PATH` env var is set from `${{ inputs.install-dir }}` in action.yaml's env: block. An attacker-controlled value containing newlines could inject arbitrary entries into GITHUB_PATH (e.g., to hijack PATH lookups). The required sanitization step (`printf '%s' "$INSTALL_PATH" | tr -d '\n\r'`) is absent.

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

1. **script-injection / static-inline-injection (compose arguments)**: Moved `${{ inputs.command }}`, `${{ inputs.subcommand }}`, and `${{ inputs.arguments }}` out of the `run:` shell string into the `env:` block as `INPUT_COMMAND`, `INPUT_SUBCOMMAND`, `INPUT_ARGUMENTS`. Used xargs-based NUL-delimited tokenization (`printf '%s' "$VAR" | xargs printf '%s\0'` with a `while IFS= read -r -d '' t` loop) to safely split these list-style inputs into bash arrays.

2. **script-injection (unquoted env vars)**: Fixed `echo ${GITHUB_CONTEXT}` and `echo ${RUNNER_CONTEXT}` (unquoted, susceptible to word-splitting/glob expansion) to use `printf '%s' "${GITHUB_CONTEXT}"` and `printf '%s' "${RUNNER_CONTEXT}"` (properly quoted).

3. **script-injection (Generate provenance step)**: Eliminated direct interpolation of `${{ steps.compose-args.outputs.provenance_args }}`. The compose-args step now serializes the args array as NUL-delimited base64 to `/tmp/slsa_provenance_args` and writes the file path to `$GITHUB_OUTPUT`. The Generate provenance step reads the path via `PROVENANCE_ARGS_FILE` env var, decodes the file, and reconstructs the array safely.

4. **github-env-injection (install-slsa-provenance.sh line 96)**: Added `safe_install_path="$(printf '%s' "$INSTALL_PATH" | tr -d '\n\r')"` before writing to `$GITHUB_PATH`, preventing newline injection attacks.

