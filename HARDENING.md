<!-- markdownlint-disable -->

# Hardening Report: philips-labs--slsa-provenance-action/v0.7.0

> This file was generated automatically by the hardening agent.

**Policy SHA:** `d636be7e43ef829af6e853da6b3c7566db9f72fe`

**Test Policy SHA:** `843adf9e4b8f85d0c08b27b9d0b09dd094b54702`

**Harden Agent Version:** `2`

Action **philips-labs--slsa-provenance-action/v0.7.0** was hardened automatically. 5 finding(s) were identified and resolved across 2 iteration(s).

## Findings Fixed

### script-injection (severity: high)

Rule (a): The 'compose arguments' step directly interpolates untrusted input expressions inside the `run:` shell script. `${{ inputs.command }}`, `${{ inputs.subcommand }}`, and `${{ inputs.arguments }}` are expanded by the YAML template engine before the shell ever sees them, allowing an attacker to inject arbitrary shell commands. These values should be passed via `env:` variables and then referenced as quoted shell variables.

Rule (b): `echo ${GITHUB_CONTEXT}` and `echo ${RUNNER_CONTEXT}` use unquoted shell variable expansions of workflow-controlled values, allowing shell metacharacter injection.

Additionally, the 'Generate provenance' step interpolates `${{ steps.compose-args.outputs.provenance_args }}` directly in the `run:` command string (rule a), which is derived from the attacker-controlled inputs above.

Locations:

- `action.yaml:43`
- `action.yaml:44`
- `action.yaml:46`
- `action.yaml:47`
- `action.yaml:52`
- `action.yaml:61`

### github-env-injection (severity: high)

The install script writes `$INSTALL_PATH` to `$GITHUB_PATH` without sanitization. `INSTALL_PATH` is set from `${{ inputs.install-dir }}` (an untrusted user-controlled input) via the `env:` block in action.yaml. Because no `printf '%s' ... | tr -d '\n\r'` sanitization is applied before the write, an attacker can inject newlines into `$GITHUB_PATH` to smuggle arbitrary environment variable assignments or path entries, potentially hijacking subsequent steps.

Locations:

- `action.yaml:37`
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

1. script-injection / static-inline-injection: Moved ${{ inputs.command }}, ${{ inputs.subcommand }}, and ${{ inputs.arguments }} from the run: block into the env: block as INPUT_COMMAND, INPUT_SUBCOMMAND, and INPUT_ARGUMENTS. Used xargs-based NUL-delimited tokenization to safely expand these list-style inputs into bash arrays. Fixed unquoted ${GITHUB_CONTEXT} and ${RUNNER_CONTEXT} shell variable expansions. Moved ${{ steps.compose-args.outputs.provenance_args }} from the Generate provenance run: block into env: as PROVENANCE_ARGS, then tokenized it with xargs. Also updated deprecated ::set-output to use $GITHUB_OUTPUT.

2. github-env-injection: In install-slsa-provenance.sh, sanitized $INSTALL_PATH before writing to $GITHUB_PATH using printf '%s' "$INSTALL_PATH" | tr -d '\n\r' to strip newlines and carriage returns that could be used to inject additional entries.

### Iteration 2

**Fixes applied:** github-env-injection

**Notes:**

Fixed the github-env-injection finding in hardened/action/action.yaml. In the 'compose arguments' step, the line `echo "provenance_args=${args[*]}" >> "$GITHUB_OUTPUT"` was replaced with two lines: first capturing the sanitized value `safe_args="$(printf '%s' "${args[*]}" | tr -d '\n\r')"`, then writing `echo "provenance_args=${safe_args}" >> "$GITHUB_OUTPUT"`. This strips any newline characters from the composed arguments before writing to GITHUB_OUTPUT, preventing injection of additional key=value pairs by a caller who embeds newlines in inputs like `command`, `subcommand`, `arguments`, `github_context`, or `runner_context`.

