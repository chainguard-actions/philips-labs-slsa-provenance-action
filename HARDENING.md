<!-- markdownlint-disable -->

# Hardening Report: philips-labs--slsa-provenance-action/v0.7.2

> This file was generated automatically by the hardening agent.

**Policy SHA:** `d636be7e43ef829af6e853da6b3c7566db9f72fe`

**Test Policy SHA:** `843adf9e4b8f85d0c08b27b9d0b09dd094b54702`

**Harden Agent Version:** `2`

Action **philips-labs--slsa-provenance-action/v0.7.2** was hardened automatically. 6 finding(s) were identified and resolved across 1 iteration(s).

## Findings Fixed

### script-injection (severity: high)

Rule (a): the 'compose arguments' step puts user-supplied input expressions straight into the run: script: `args=(${{ inputs.command }})`, `args+=(${{ inputs.subcommand }})` and `args+=(${{ inputs.arguments }})`. Text in these inputs such as $(...), backticks or ; is run by bash. Rule (b): `echo ${GITHUB_CONTEXT}` and `echo ${RUNNER_CONTEXT}` expand input-sourced env vars without quotes. Fix: move each input into an env: variable and expand it in double quotes.

Locations:

- `action.yaml:46`
- `action.yaml:47`
- `action.yaml:52`
- `action.yaml:43`

### script-injection (severity: high)

Rule (a): the 'Generate provenance' step puts a step output expression straight into the run: script: `$INSTALL_PATH/slsa-provenance ${{ steps.compose-args.outputs.provenance_args }}`. That output is built from untrusted inputs. Rule (b): `$INSTALL_PATH` comes from inputs.install-dir and is expanded without quotes.

Locations:

- `action.yaml:61`

### github-env-injection (severity: high)

The 'install binary' step passes inputs.install-dir to the script as INSTALL_PATH. The script then runs `echo "$INSTALL_PATH" >> "${GITHUB_PATH:-...}"` with no `printf '%s' ... | tr -d '\n\r'` cleanup first, so a value containing newlines can add extra entries to GITHUB_PATH.

Locations:

- `action.yaml:35`
- `install-slsa-provenance.sh:109`

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

action.yaml: I merged the 'compose arguments' and 'Generate provenance' steps into one step (id compose-args is kept). The command, subcommand and arguments inputs now come in through env: variables. Each one is split into a bash array with the quote-aware xargs method, which splits the same way the inlined expressions did upstream. The binary is called as "$INSTALL_PATH/slsa-provenance" "${args[@]}". This removes the deprecated ::set-output and the second inlining of the step output. The GITHUB_CONTEXT and RUNNER_CONTEXT values are now quoted before base64 encoding. The install script path is quoted as well. install-slsa-provenance.sh: INSTALL_PATH has \n and \r removed before it is written to GITHUB_PATH. None of this has been run or tested yet.

