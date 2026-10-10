<!-- markdownlint-disable -->

# Hardening Report: philips-labs--slsa-provenance-action/v0.9.0

> This file was generated automatically by the hardening agent.

**Policy SHA:** `d636be7e43ef829af6e853da6b3c7566db9f72fe`

**Test Policy SHA:** `843adf9e4b8f85d0c08b27b9d0b09dd094b54702`

**Harden Agent Version:** `2`

Action **philips-labs--slsa-provenance-action/v0.9.0** was hardened automatically. 8 finding(s) were identified and resolved across 1 iteration(s).

## Findings Fixed

### script-injection (severity: high)

Rule (a): In the 'compose arguments' step, three inputs are directly interpolated as ${{ }} expressions inside the run: shell script without any quoting or sanitization. `args=(${{ inputs.command }})`, `args+=(${{ inputs.subcommand }})`, and `args+=(${{ inputs.arguments }})` allow an attacker to inject arbitrary shell commands by supplying values containing shell metacharacters (e.g. semicolons, backticks, subshell syntax). These are composite-action inputs fully controlled by the calling workflow.

Locations:

- `action.yaml:47`
- `action.yaml:48`
- `action.yaml:53`

### script-injection (severity: high)

Rule (a): In the 'Generate provenance' step, `${{ steps.compose-args.outputs.provenance_args }}` is directly interpolated inside the run: shell command string. Step outputs are workflow-controllable values and must never be interpolated directly into run: blocks. An attacker who can influence the output of the prior step (e.g. via inputs.command/subcommand/arguments) can achieve command injection here.

Locations:

- `action.yaml:61`

### script-injection (severity: high)

Rule (b): In the 'compose arguments' step, `${GITHUB_CONTEXT}` and `${RUNNER_CONTEXT}` are expanded unquoted inside command substitutions: `encoded_github="$(echo ${GITHUB_CONTEXT} | base64 -w 0)"` and `encoded_runner="$(echo ${RUNNER_CONTEXT} | base64 -w 0)"`. These env vars hold `inputs.github_context` and `inputs.runner_context` respectively (attacker-controllable). Unquoted expansion allows shell word-splitting and glob expansion on the values before they reach base64.

Locations:

- `action.yaml:44`
- `action.yaml:45`

### github-env-injection (severity: high)

In the 'compose arguments' step, `echo "provenance_args=${args[@]}" >> $GITHUB_OUTPUT` writes to GITHUB_OUTPUT without sanitization. The `args` array is populated directly from `${{ inputs.command }}`, `${{ inputs.subcommand }}`, and `${{ inputs.arguments }}` — all attacker-controlled inputs. A value containing a newline character would allow injection of arbitrary key=value pairs into GITHUB_OUTPUT, enabling environment variable injection in subsequent steps. The required sanitization (`printf '%s' ... | tr -d '\n\r'`) is absent.

Locations:

- `action.yaml:56`

### github-env-injection (severity: high)

In install-slsa-provenance.sh, `echo "$INSTALL_PATH" >> "${GITHUB_PATH:-...}"` writes the INSTALL_PATH variable to GITHUB_PATH without sanitization. INSTALL_PATH is set from `inputs.install-dir` (via the env: block `INSTALL_PATH: ${{ inputs.install-dir }}`), which is an attacker-controlled input. A newline-containing value would allow injection of arbitrary paths into GITHUB_PATH. The required sanitization (`printf '%s' "$INSTALL_PATH" | tr -d '\n\r'`) is absent before the write.

Locations:

- `install-slsa-provenance.sh:126`
- `action.yaml:40`

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

1. **script-injection / static-inline-injection** (action.yaml compose arguments step): Moved `${{ inputs.command }}`, `${{ inputs.subcommand }}`, and `${{ inputs.arguments }}` from inline run: interpolation to the step's env: block as INPUT_COMMAND, INPUT_SUBCOMMAND, INPUT_ARGUMENTS. Used xargs-based tokenization with guards to safely split these list inputs into array elements.

2. **script-injection** (action.yaml Generate provenance step): Moved `${{ steps.compose-args.outputs.provenance_args }}` from inline run: interpolation to the step's env: block as PROVENANCE_ARGS, then tokenized via xargs into an array before passing to the binary.

3. **script-injection** (unquoted expansions): Fixed `echo ${GITHUB_CONTEXT}` and `echo ${RUNNER_CONTEXT}` to use proper double-quoting: `echo "${GITHUB_CONTEXT}"` and `echo "${RUNNER_CONTEXT}"`.

4. **github-env-injection** (action.yaml GITHUB_OUTPUT write): Sanitized the args array before writing to GITHUB_OUTPUT using `printf '%s' "${args[*]}" | tr -d '\n\r'`.

5. **github-env-injection** (install-slsa-provenance.sh GITHUB_PATH write): Added sanitization before writing INSTALL_PATH to GITHUB_PATH: `safe_install_path="$(printf '%s' "$INSTALL_PATH" | tr -d '\n\r')"` then writing `$safe_install_path`.

