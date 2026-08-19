<!-- markdownlint-disable -->

# Hardening Report: philips-labs--slsa-provenance-action/v0.7.2

> This file was generated automatically by the hardening agent.

**Policy SHA:** `d636be7e43ef829af6e853da6b3c7566db9f72fe`

**Test Policy SHA:** `843adf9e4b8f85d0c08b27b9d0b09dd094b54702`

**Harden Agent Version:** `2`

Action **philips-labs--slsa-provenance-action/v0.7.2** was hardened automatically. 5 finding(s) were identified and resolved across 4 iteration(s).

## Findings Fixed

### script-injection (severity: high)

Multiple ${{ }} expressions are directly interpolated into run: shell commands in action.yaml, violating rule (a). Attacker-controlled inputs are injected directly into shell code before the shell ever sees them:
- Line 44: `args=(${{ inputs.command }})` — inputs.command interpolated directly into shell array
- Line 45: `args+=(${{ inputs.subcommand }})` — inputs.subcommand interpolated directly into shell array
- Line 49: `args+=(${{ inputs.arguments }})` — inputs.arguments interpolated directly into shell array (highest risk: arbitrary arguments from caller)
- Line 57: `run: $INSTALL_PATH/slsa-provenance ${{ steps.compose-args.outputs.provenance_args }}` — step output interpolated directly into shell command

Additionally, rule (b) is violated on lines 41–42: `${GITHUB_CONTEXT}` and `${RUNNER_CONTEXT}` are expanded unquoted inside command substitution (`echo ${GITHUB_CONTEXT} | base64 -w 0`), allowing shell metacharacter injection from the github/runner context values passed in via env vars.

Locations:

- `action.yaml:41`
- `action.yaml:42`
- `action.yaml:44`
- `action.yaml:45`
- `action.yaml:49`
- `action.yaml:57`

### github-env-injection (severity: high)

In install-slsa-provenance.sh (called from the 'install binary' step of action.yaml), the variable $INSTALL_PATH is written directly to $GITHUB_PATH without sanitization. $INSTALL_PATH is set from the `inputs.install-dir` input via the env: block in action.yaml (line 36: `INSTALL_PATH: ${{ inputs.install-dir }}`). A caller can supply a value containing newlines to inject arbitrary entries into the runner's PATH. The required sanitization step (`printf '%s' "$INSTALL_PATH" | tr -d '\n\r'`) is absent before the write.

Locations:

- `install-slsa-provenance.sh:97`
- `action.yaml:36`

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

1. action.yaml - compose arguments step: Moved ${{ inputs.command }}, ${{ inputs.subcommand }}, and ${{ inputs.arguments }} out of the run: shell block into the env: map as INPUT_COMMAND, INPUT_SUBCOMMAND, INPUT_ARGUMENTS. These are now referenced as plain env vars in the shell script with proper quoting.

2. action.yaml - compose arguments step: Fixed unquoted ${GITHUB_CONTEXT} and ${RUNNER_CONTEXT} in command substitution by using printf '%s' "${VAR}" | base64 -w 0 instead of echo ${VAR} | base64 -w 0.

3. action.yaml - Generate provenance step: Moved ${{ steps.compose-args.outputs.provenance_args }} out of the run: shell command into the env: block as PROVENANCE_ARGS. The shell now uses read -r -a to safely split the args and executes with proper quoting.

4. install-slsa-provenance.sh line 97: Added sanitization of INSTALL_PATH before writing to GITHUB_PATH using printf '%s' "$INSTALL_PATH" | tr -d '\n\r' to prevent newline injection into the runner PATH.

5. Also updated deprecated ::set-output syntax to use $GITHUB_OUTPUT.

### Iteration 2

**Fixes applied:** script-injection, github-env-injection, unpinned-uses, missing-permissions

**Notes:**

Fixed all four findings across action.yaml and three workflow files:

1. script-injection: Moved all ${{ }} expressions from run: blocks to env: blocks in ci.yaml (github.actor, github.ref_name, matrix.repo, needs.release.outputs.container_digest) and example-local.yaml (github.event.inputs.ingredient_input, github.event.inputs.car_input). Shell scripts now reference plain environment variables.

2. github-env-injection: In action.yaml, sanitized the provenance_args value before writing to GITHUB_OUTPUT using `printf '%s' "${args[*]}" | tr -d '\n\r'` to strip newlines that could inject additional key=value pairs.

3. unpinned-uses: Pinned all 10 action references to full 40-character SHA commit hashes (resolved via lookup_action_sha), preserving original tags in comments.

4. missing-permissions: Added `permissions: {}` at the top level of all three workflow files (ci.yaml, example-local.yaml, example-publish.yaml), plus minimal job-level permissions (contents: read for build jobs, contents: write + packages: write for release/provenance jobs that need them).

### Iteration 3

**Fixes applied:** script-injection

**Notes:**

Fixed unquoted/unsafe shell variable expansions in .github/workflows/example-local.yaml at lines 37 and 44. Replaced `echo ", $INGREDIENT_INPUT" >> salsa.txt` and `echo ", $CAR_INPUT" >> cars.txt` with `printf ', %s' "$INGREDIENT_INPUT" >> salsa.txt` and `printf ', %s' "$CAR_INPUT" >> cars.txt` respectively. Using printf with a %s format specifier ensures the variable content is treated as a literal string, preventing shell metacharacters (such as command substitution via `$(...)` or backticks) in attacker-controlled workflow_dispatch inputs from being interpreted by the shell.

### Iteration 4

**Fixes applied:** script-injection

**Notes:**

Fixed all 8 script-injection findings in .github/workflows/ci.yaml. In every affected step, ${{ secrets.DOCKER_PASSWORD }}, ${{ secrets.GITHUB_TOKEN }}, ${{ secrets.COSIGN_PRIVATE_KEY }}, and ${{ secrets.COSIGN_PUBLIC_KEY }} were moved from direct run: shell interpolation into the step env: block and referenced as plain shell variables. echo was replaced with printf '%s' for key material. The unquoted ${TAGS} word-split in the sbom Attach SBOM step was fixed by replacing the for loop with a safe while/IFS/read loop using a here-string.

