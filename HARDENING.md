<!-- markdownlint-disable -->

# Hardening Report: philips-labs--slsa-provenance-action/v0.7.1

> This file was generated automatically by the hardening agent.

**Policy SHA:** `d636be7e43ef829af6e853da6b3c7566db9f72fe`

**Test Policy SHA:** `843adf9e4b8f85d0c08b27b9d0b09dd094b54702`

**Harden Agent Version:** `2`

Action **philips-labs--slsa-provenance-action/v0.7.1** was hardened automatically. 13 finding(s) were identified and resolved across 4 iteration(s).

## Findings Fixed

### script-injection (severity: high)

Sub-rule (a): Direct expression interpolation inside run: blocks. In action.yaml, the 'compose arguments' step directly interpolates inputs into shell commands: `args=(${{ inputs.command }})`, `args+=(${{ inputs.subcommand }})`, and `args+=(${{ inputs.arguments }})`. A malicious caller can inject shell metacharacters. The 'Generate provenance' step also directly interpolates a step output: `$INSTALL_PATH/slsa-provenance ${{ steps.compose-args.outputs.provenance_args }}`.

Locations:

- `action.yaml:46`
- `action.yaml:47`
- `action.yaml:52`
- `action.yaml:61`

### script-injection (severity: high)

Sub-rule (a): Direct expression interpolation inside run: blocks in ci.yaml. Multiple steps interpolate github context and matrix values directly into shell commands: (1) `docker login -u ${{ github.actor }}` (lines ~91, ~163, ~207); (2) `export CONTAINER_DIGEST=$(make container-digest GITHUB_REF=${{ github.ref_name }})` (line ~117); (3) `cosign verify --key cosign.pub ${{ matrix.repo }}:${t}`, `syft ${{ matrix.repo }}:${t}`, `cosign attest ... ${{ matrix.repo }}:${t}`, `cosign verify-attestation ... ${{ matrix.repo }}:${t}` (lines ~170-173); (4) `cosign attest ... ${{ matrix.repo }}@${{ needs.release.outputs.container_digest }}` and `cosign verify-attestation ... ${{ matrix.repo }}@${{ needs.release.outputs.container_digest }}` (lines ~213, ~218). These allow shell injection via attacker-controlled values.

Locations:

- `.github/workflows/ci.yaml:91`
- `.github/workflows/ci.yaml:117`
- `.github/workflows/ci.yaml:163`
- `.github/workflows/ci.yaml:170`
- `.github/workflows/ci.yaml:171`
- `.github/workflows/ci.yaml:172`
- `.github/workflows/ci.yaml:173`
- `.github/workflows/ci.yaml:207`
- `.github/workflows/ci.yaml:213`
- `.github/workflows/ci.yaml:218`

### script-injection (severity: high)

Sub-rule (a): Direct expression interpolation of attacker-controlled workflow_dispatch inputs inside run: blocks in example-local.yaml. The steps 'Input workflow ingredient' and 'Input workflow cars' directly interpolate user-supplied inputs into shell echo commands: `echo ", ${{github.event.inputs.ingredient_input}}" >> salsa.txt` and `echo ", ${{github.event.inputs.car_input}}" >> cars.txt`. An attacker can inject arbitrary shell commands via these inputs.

Locations:

- `.github/workflows/example-local.yaml:26`
- `.github/workflows/example-local.yaml:31`

### github-env-injection (severity: high)

The install-slsa-provenance.sh script writes the INSTALL_PATH variable to $GITHUB_PATH without sanitization: `echo "$INSTALL_PATH" >> "${GITHUB_PATH:-...}"`. INSTALL_PATH is set from the caller-controlled input `${{ inputs.install-dir }}` via the env block in action.yaml (`INSTALL_PATH: ${{ inputs.install-dir }}`). A malicious caller can inject newlines into the install-dir input to write arbitrary entries to GITHUB_PATH, enabling PATH hijacking. The required sanitization (`printf '%s' "$INSTALL_PATH" | tr -d '\n\r'`) is absent.

Locations:

- `action.yaml:37`
- `install-slsa-provenance.sh:84`

### unpinned-uses (severity: high)

Multiple uses: references in ci.yaml are pinned to mutable tags or version strings instead of immutable 40-character commit SHAs, making the workflow vulnerable to supply-chain attacks: `actions/setup-go@v2.2.0` (×2), `actions/checkout@v2.4.0` (×2), `actions/cache@v2.1.7`, `codecov/codecov-action@v2.1.0`, `sigstore/cosign-installer@v2.0.0` (×3), `anchore/sbom-action/download-syft@v0.6.0` (×2), `goreleaser/goreleaser-action@v2`, `philips-labs/slsa-provenance-action@v0.8.1-draft`.

Locations:

- `.github/workflows/ci.yaml:15`
- `.github/workflows/ci.yaml:20`
- `.github/workflows/ci.yaml:23`
- `.github/workflows/ci.yaml:50`
- `.github/workflows/ci.yaml:70`
- `.github/workflows/ci.yaml:73`
- `.github/workflows/ci.yaml:77`
- `.github/workflows/ci.yaml:82`
- `.github/workflows/ci.yaml:107`
- `.github/workflows/ci.yaml:148`
- `.github/workflows/ci.yaml:152`
- `.github/workflows/ci.yaml:163`
- `.github/workflows/ci.yaml:192`
- `.github/workflows/ci.yaml:196`

### unpinned-uses (severity: high)

Multiple uses: references in example-local.yaml are pinned to mutable tags instead of immutable 40-character commit SHAs: `actions/upload-artifact@v2` (×2), `actions/checkout@v2.4.0`, `actions/download-artifact@v2`.

Locations:

- `.github/workflows/example-local.yaml:35`
- `.github/workflows/example-local.yaml:40`
- `.github/workflows/example-local.yaml:43`
- `.github/workflows/example-local.yaml:52`

### unpinned-uses (severity: high)

Multiple uses: references in example-publish.yaml are pinned to mutable tags instead of immutable 40-character commit SHAs: `actions/upload-artifact@v2` (×2), `actions/download-artifact@v2`, `philips-labs/slsa-provenance-action@v0.7.1`.

Locations:

- `.github/workflows/example-publish.yaml:12`
- `.github/workflows/example-publish.yaml:19`
- `.github/workflows/example-publish.yaml:22`
- `.github/workflows/example-publish.yaml:27`

### missing-permissions (severity: medium)

ci.yaml has no top-level `permissions:` key and none of its jobs (build, release, sbom, container-provenance) define a `permissions:` block. This means the workflow runs with the default, overly broad token permissions.

Locations:

- `.github/workflows/ci.yaml:1`

### missing-permissions (severity: medium)

example-local.yaml has no top-level `permissions:` key and neither of its jobs (build, generate-provenance) defines a `permissions:` block. This means the workflow runs with the default, overly broad token permissions.

Locations:

- `.github/workflows/example-local.yaml:1`

### missing-permissions (severity: medium)

example-publish.yaml has no top-level `permissions:` key and neither of its jobs (build, generate-provenance) defines a `permissions:` block. This means the workflow runs with the default, overly broad token permissions.

Locations:

- `.github/workflows/example-publish.yaml:1`

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

**Fixes applied:** script-injection, github-env-injection, unpinned-uses, missing-permissions, static-inline-injection

**Notes:**

Fixed all findings across action.yaml, install-slsa-provenance.sh, ci.yaml, example-local.yaml, and example-publish.yaml:

1. script-injection/static-inline-injection (action.yaml): Moved inputs.command, inputs.subcommand, inputs.arguments, and steps.compose-args.outputs.provenance_args from direct ${{ }} interpolation in run: blocks to env: blocks, referenced as $INPUT_COMMAND, $INPUT_SUBCOMMAND, $INPUT_ARGUMENTS, $PROVENANCE_ARGS.

2. script-injection (ci.yaml): Moved github.actor, github.ref_name, matrix.repo, and needs.release.outputs.container_digest from direct interpolation in run: blocks to env: blocks.

3. script-injection (example-local.yaml): Moved github.event.inputs.ingredient_input and github.event.inputs.car_input from direct interpolation in run: blocks to env: blocks.

4. github-env-injection (install-slsa-provenance.sh): Added sanitization: safe_install_path=$(printf '%s' "$INSTALL_PATH" | tr -d '\n\r') before writing to GITHUB_PATH.

5. unpinned-uses (ci.yaml): Pinned setup-go@v2.2.0→bfdd3570, checkout@v2.4.0→ec3a7ce1, cache@v2.1.7→937d2447, codecov-action@v2.1.0→f32b3a37, cosign-installer@v2.0.0→d572c9c1, sbom-action/download-syft@v0.6.0→3626d7d7, goreleaser-action@v2→b953231f, slsa-provenance-action (v0.8.1-draft not found, pinned to main SHA e74791624f).

6. unpinned-uses (example-local.yaml): Pinned upload-artifact@v2→82c141cc, checkout@v2.4.0→ec3a7ce1, download-artifact@v2→cbed621e.

7. unpinned-uses (example-publish.yaml): Pinned upload-artifact@v2→82c141cc, download-artifact@v2→cbed621e, slsa-provenance-action@v0.7.1→3645ec05.

8. missing-permissions: Added top-level permissions: {contents: read} and appropriate per-job permissions blocks to ci.yaml, example-local.yaml, and example-publish.yaml.

### Iteration 2

**Fixes applied:** script-injection

**Notes:**

Fixed all script injection findings:

1. `.github/workflows/ci.yaml` (5 locations): Replaced all `echo '${{ secrets.COSIGN_PRIVATE_KEY }}'` and `echo '${{ secrets.COSIGN_PUBLIC_KEY }}'` patterns. Each secret was moved into the step's `env:` block (COSIGN_PRIVATE_KEY / COSIGN_PUBLIC_KEY), and the shell command was changed to `printf '%s' "$VAR" > file` to safely write the value without GitHub Actions expanding `${{ }}` expressions inside the shell command string.

2. `action.yaml` (4 locations):
   - Changed `echo ${GITHUB_CONTEXT}` and `echo ${RUNNER_CONTEXT}` to `printf '%s' "${GITHUB_CONTEXT}"` and `printf '%s' "${RUNNER_CONTEXT}"` (properly quoted).
   - Changed unquoted array expansions `args=($INPUT_COMMAND)`, `args+=($INPUT_SUBCOMMAND)`, `args+=($INPUT_ARGUMENTS)` to double-quoted forms `args=("$INPUT_COMMAND")`, `args+=("$INPUT_SUBCOMMAND")`, `args+=("$INPUT_ARGUMENTS")` to prevent word-splitting and glob expansion of user-controlled inputs.
   - Changed the `Generate provenance` step from unquoted `$INSTALL_PATH/slsa-provenance $PROVENANCE_ARGS` to use `read -ra provenance_args <<< "$PROVENANCE_ARGS"` followed by `"$INSTALL_PATH/slsa-provenance" "${provenance_args[@]}"` so the binary path and each argument are properly quoted.

### Iteration 3

**Fixes applied:** script-injection

**Notes:**

Fixed the unquoted variable expansion in the 'Attach SBOM' step of the `sbom` job in `.github/workflows/ci.yaml`. Changed `for t in ${TAGS}; do` to `for t in "${TAGS}"; do`. The `IFS=,` is already set before the loop, so quoting `${TAGS}` still allows comma-based word splitting (the intended behavior) while preventing shell metacharacter injection from attacker-controlled values in `needs.release.outputs.container_tags`.

### Iteration 4

**Fixes applied:** github-env-injection

**Notes:**

Fixed the 'compose arguments' step in action.yaml: replaced `echo "::set-output name=provenance_args::${args[*]}"` with a two-line fix that (1) sanitizes the args string using `printf '%s' "${args[*]}" | tr -d '\n\r'` to strip any newlines or carriage returns that could be injected via untrusted inputs (command, subcommand, arguments, github_context, runner_context), and (2) writes the sanitized value to `$GITHUB_OUTPUT` using the modern file-based approach instead of the deprecated `::set-output` workflow command.

