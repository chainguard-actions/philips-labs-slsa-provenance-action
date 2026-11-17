<!-- markdownlint-disable -->

# Hardening Report: philips-labs--slsa-provenance-action/v0.8.0

> This file was generated automatically by the hardening agent.

**Policy SHA:** `374911c4be584df24e6da57af2d990570ef0f859`

**Test Policy SHA:** `843adf9e4b8f85d0c08b27b9d0b09dd094b54702`

**Harden Agent Version:** `2`

Action **philips-labs--slsa-provenance-action/v0.8.0** was hardened automatically. 8 finding(s) were identified and resolved across 1 iteration(s).

## Findings Fixed

### script-injection (severity: high)

Step 'compose arguments' (rule a): workflow expressions are placed straight into the run script, so the shell parses whatever they contain: `args=(${{ inputs.command }})`, `args+=(${{ inputs.subcommand }})`, `args+=(${{ inputs.arguments }})`. Rule (b) also fails: the env vars holding workflow-controlled input are expanded without quotes in `encoded_github="$(echo ${GITHUB_CONTEXT} | base64 -w 0)"` and `encoded_runner="$(echo ${RUNNER_CONTEXT} | base64 -w 0)"`. Fix: pass the inputs through env: variables and quote every expansion.

Locations:

- `action.yaml:43`
- `action.yaml:44`
- `action.yaml:46`
- `action.yaml:47`
- `action.yaml:52`

### script-injection (severity: high)

Step 'Generate provenance' (rule a): `run: $INSTALL_PATH/slsa-provenance ${{ steps.compose-args.outputs.provenance_args }}` puts a step output, built from inputs.arguments and other inputs, straight into the shell command. Rule (b) also fails: `$INSTALL_PATH`, which comes from inputs.install-dir, is expanded without quotes.

Locations:

- `action.yaml:61`

### github-env-injection (severity: high)

install-slsa-provenance.sh (run by the 'install binary' step, where INSTALL_PATH comes from inputs.install-dir) writes `echo "$INSTALL_PATH" >> "${GITHUB_PATH:-...}"` without first removing newlines (`printf '%s' ... | tr -d '\n\r'`). A value with newlines in it can add arbitrary entries to PATH.

Locations:

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

### prior-fix (severity: high)

Carried forward from this version's previous harden, which fixed it; fix it again unless the code no longer has the problem. The previous harden changed action.yaml without recording a finding for it, and this analysis reported nothing there. Re-apply its security changes unless the code no longer needs them. The previous patch:
```diff
diff --git a/action.yaml b/action.yaml
index 246ecd1..af18530 100644
--- a/action.yaml
+++ b/action.yaml
@@ -30,34 +30,69 @@ inputs:
 runs:
   using: 'composite'
   steps:
     - name: install binary
       shell: bash
       run: $GITHUB_ACTION_PATH/install-slsa-provenance.sh
       env:
         INSTALL_PATH: ${{ inputs.install-dir }}
-
     - name: compose arguments
       id: compose-args
       shell: bash
       run: |
-        encoded_github="$(echo ${GITHUB_CONTEXT} | base64 -w 0)"
-        encoded_runner="$(echo ${RUNNER_CONTEXT} | base64 -w 0)"
+        encoded_github="$(echo "${GITHUB_CONTEXT}" | base64 -w 0)"
+        encoded_runner="$(echo "${RUNNER_CONTEXT}" | base64 -w 0)"
 
-        args=(${{ inputs.command }})
-        args+=(${{ inputs.subcommand }})
+        args=()
+        if [ -n "$INPUT_COMMAND" ]; then
+          while IFS= read -r -d '' t; do args+=("$t"); done \
+            < <(printf '%s' "$INPUT_COMMAND" | xargs printf '%s\0')
+        fi
+        if [ -n "$INPUT_SUBCOMMAND" ]; then
+          while IFS= read -r -d '' t; do args+=("$t"); done \
+            < <(printf '%s' "$INPUT_SUBCOMMAND" | xargs printf '%s\0')
+        fi
         args+=(--github-context)
         args+=("${encoded_github}")
         args+=(--runner-context)
         args+=("${encoded_runner}")
-        args+=(${{ inputs.arguments }})
+        if [ -n "$INPUT_ARGUMENTS" ]; then
+          while IFS= read -r -d '' t; do args+=("$t"); done \
+            < <(printf '%s' "$INPUT_ARGUMENTS" | xargs printf '%s\0')
+        fi
 
         echo "::set-output name=provenance_args::${args[@]}"
       env:
         GITHUB_CONTEXT: ${{ inputs.github_context }}
         RUNNER_CONTEXT: ${{ inputs.runner_context }}
-
+        INPUT_COMMAND: ${{ inputs.command }}
+        INPUT_SUBCOMMAND: ${{ inputs.subcommand }}
+        INPUT_ARGUMENTS: ${{ inputs.arguments }}
     - name: Generate provenance
       shell: bash
-      run: $INSTALL_PATH/slsa-provenance ${{ steps.compose-args.outputs.provenance_args }}
+      run: |
+        args=()
+        if [ -n "$PROVENANCE_ARGS" ]; then
+          while IFS= read -r -d '' t; do args+=("$t"); done \
+            < <(printf '%s' "$PROVENANCE_ARGS" | xargs printf '%s\0')
+        fi
+        "$INSTALL_PATH/slsa-provenance" "${args[@]}"
       env:
         INSTALL_PATH: ${{ inputs.install-dir }}
+        PROVENANCE_ARGS: ${{ steps.compose-args.outputs.provenance_args }}

```

Locations:

- `action.yaml`

### prior-fix (severity: high)

Carried forward from this version's previous harden, which fixed it; fix it again unless the code no longer has the problem. The previous harden changed install-slsa-provenance.sh without recording a finding for it, and this analysis reported nothing there. Re-apply its security changes unless the code no longer needs them. The previous patch:
```diff
diff --git a/install-slsa-provenance.sh b/install-slsa-provenance.sh
index 6db18c7..90c556e 100755
--- a/install-slsa-provenance.sh
+++ b/install-slsa-provenance.sh
@@ -106,4 +106,5 @@ tar -xzf "${ARCHIVE}" "${BINARY}"
 rm "${ARCHIVE}"
 
 # for testing purposes fall back to "$INSTALL_PATH/GITHUB_PATH"
-echo "$INSTALL_PATH" >> "${GITHUB_PATH:-"$INSTALL_PATH/GITHUB_PATH"}"
+safe_install_path="$(printf '%s' "$INSTALL_PATH" | tr -d '\n\r')"
+echo "$safe_install_path" >> "${GITHUB_PATH:-"$INSTALL_PATH/GITHUB_PATH"}"

```

Locations:

- `install-slsa-provenance.sh`

## Iteration Notes

### Iteration 1

**Fixes applied:** script-injection, github-env-injection, static-inline-injection, prior-fix

**Notes:**

action.yaml: I moved inputs.command, inputs.subcommand and inputs.arguments into env: in the 'compose arguments' step. Upstream pasted these values straight into the script, so the shell honoured any quotes in them. To keep that splitting, each value is now split with the quote-aware xargs pattern: a guard against empty values, an 'xargs -r true' check that fails on an unmatched quote, and the shell's built-in printf run through sh -c. I also quoted the GITHUB_CONTEXT and RUNNER_CONTEXT expansions before base64. In 'Generate provenance', the step output now comes in through the PROVENANCE_ARGS env var and is split the same way, and "$INSTALL_PATH/slsa-provenance" is quoted. The literal '$HOME' default still behaves as it did upstream, because an unquoted expansion never expanded it either. install-slsa-provenance.sh: newlines and carriage returns are now stripped from INSTALL_PATH before it is written to GITHUB_PATH. This re-applies the previous harden's changes, with the xargs split made sturdier than in that patch.

