<!-- markdownlint-disable -->

# Hardening Report: philips-labs--slsa-provenance-action/v0.7.2

> This file was generated automatically by the hardening agent.

**Policy SHA:** `d636be7e43ef829af6e853da6b3c7566db9f72fe`

**Test Policy SHA:** `843adf9e4b8f85d0c08b27b9d0b09dd094b54702`

**Harden Agent Version:** `2`

Action **philips-labs--slsa-provenance-action/v0.7.2** was hardened automatically. 6 finding(s) were identified and resolved across 1 iteration(s).

## Findings Fixed

### script-injection (severity: high)

Rule (a): The 'compose arguments' step directly interpolates user-controlled inputs into the run: shell script without quoting. Specifically: `args=(${{ inputs.command }})`, `args+=(${{ inputs.subcommand }})`, and `args+=(${{ inputs.arguments }})` allow an attacker to inject arbitrary shell commands by supplying crafted input values (e.g. containing semicolons, backticks, or subshell syntax). Rule (b): `${GITHUB_CONTEXT}` and `${RUNNER_CONTEXT}` are used unquoted in `echo ${GITHUB_CONTEXT} | base64 -w 0` and `echo ${RUNNER_CONTEXT} | base64 -w 0`, allowing shell metacharacter injection from those env vars.

Locations:

- `action.yaml:43`
- `action.yaml:44`
- `action.yaml:49`
- `action.yaml:40`
- `action.yaml:41`

### script-injection (severity: high)

Rule (a): The 'Generate provenance' step directly interpolates a step output expression into the run: shell command: `$INSTALL_PATH/slsa-provenance ${{ steps.compose-args.outputs.provenance_args }}`. Since `provenance_args` is itself built from user-controlled inputs (command, subcommand, arguments), this allows arbitrary shell command injection.

Locations:

- `action.yaml:55`

### github-env-injection (severity: high)

The install-slsa-provenance.sh script writes `$INSTALL_PATH` directly to `$GITHUB_PATH` without sanitization: `echo "$INSTALL_PATH" >> "${GITHUB_PATH:-...}"`. The `INSTALL_PATH` variable is set from `inputs.install-dir` (via the `INSTALL_PATH` env var in action.yaml line 34) and is never sanitized with `printf '%s' ... | tr -d '\n\r'` before the write. A calling workflow can supply a newline-containing value for `inputs.install-dir` to inject arbitrary entries into `$GITHUB_PATH`.

Locations:

- `install-slsa-provenance.sh:91`
- `action.yaml:34`

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

1. action.yaml 'compose arguments' step: Moved ${{ inputs.command }}, ${{ inputs.subcommand }}, and ${{ inputs.arguments }} to env: block as INPUT_COMMAND, INPUT_SUBCOMMAND, INPUT_ARGUMENTS. Used xargs-based tokenization into bash arrays to safely handle list-style inputs. Fixed unquoted ${GITHUB_CONTEXT} and ${RUNNER_CONTEXT} by replacing 'echo ${VAR}' with 'printf "%s" "${VAR}"'.

2. action.yaml 'Generate provenance' step: Moved ${{ steps.compose-args.outputs.provenance_args }} to env: block as PROVENANCE_ARGS, then safely tokenized it with xargs into a bash array before invoking the binary.

3. install-slsa-provenance.sh line 91: Added sanitization of INSTALL_PATH before writing to GITHUB_PATH using 'printf "%s" "$INSTALL_PATH" | tr -d '\n\r'' to prevent newline injection into GITHUB_PATH.

