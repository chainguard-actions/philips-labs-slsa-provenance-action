<!-- markdownlint-disable -->

# Hardening Report: philips-labs--slsa-provenance-action/v0.7.2

> This file was generated automatically by the hardening agent.

**Policy SHA:** `374911c4be584df24e6da57af2d990570ef0f859`

**Test Policy SHA:** `843adf9e4b8f85d0c08b27b9d0b09dd094b54702`

**Harden Agent Version:** `2`

Action **philips-labs--slsa-provenance-action/v0.7.2** was hardened automatically. 8 finding(s) were identified and resolved across 1 iteration(s).

## Findings Fixed

### script-injection (severity: high)

Step 'compose arguments' violates rule (a): GitHub expressions are inserted straight into the run script: `args=(${{ inputs.command }})`, `args+=(${{ inputs.subcommand }})` and `args+=(${{ inputs.arguments }})`. A caller-supplied input containing `$(...)`, backticks or `)` followed by commands would run in the shell. It also violates rule (b): `encoded_github="$(echo ${GITHUB_CONTEXT} | base64 -w 0)"` and `encoded_runner="$(echo ${RUNNER_CONTEXT} | base64 -w 0)"` expand workflow-controlled env vars without quotes inside a command substitution.

Locations:

- `action.yaml:46`
- `action.yaml:47`
- `action.yaml:52`
- `action.yaml:43`
- `action.yaml:44`

### script-injection (severity: high)

Step 'Generate provenance' violates rule (a): `run: $INSTALL_PATH/slsa-provenance ${{ steps.compose-args.outputs.provenance_args }}` puts a step output built from untrusted inputs straight into the shell command. It also violates rule (b): $INSTALL_PATH (from inputs.install-dir) is expanded without quotes.

Locations:

- `action.yaml:61`

### github-env-injection (severity: high)

The 'install binary' step runs install-slsa-provenance.sh, which writes INSTALL_PATH (taken from inputs.install-dir) to $GITHUB_PATH with `echo "$INSTALL_PATH" >> "${GITHUB_PATH:-...}"`. Newlines are not stripped first with printf '%s' | tr -d '\n\r', so a multi-line input can add arbitrary PATH entries.

Locations:

- `install-slsa-provenance.sh:108`
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

### prior-fix (severity: high)

Carried forward from this version's previous harden, which fixed it; fix it again unless the code no longer has the problem. The previous harden changed action.yaml without recording a finding for it, and this analysis reported nothing there. Re-apply its security changes unless the code no longer needs them. The previous patch:
```diff
diff --git a/action.yaml b/action.yaml
index 246ecd1..85ffd46 100644
--- a/action.yaml
+++ b/action.yaml
@@ -30,34 +30,59 @@ inputs:
 runs:
   using: 'composite'
   steps:
     - name: install binary
       shell: bash
-      run: $GITHUB_ACTION_PATH/install-slsa-provenance.sh
+      run: '"$GITHUB_ACTION_PATH/install-slsa-provenance.sh"'
       env:
         INSTALL_PATH: ${{ inputs.install-dir }}
 
-    - name: compose arguments
+    - name: Generate provenance
       id: compose-args
       shell: bash
       run: |
-        encoded_github="$(echo ${GITHUB_CONTEXT} | base64 -w 0)"
-        encoded_runner="$(echo ${RUNNER_CONTEXT} | base64 -w 0)"
+        encoded_github="$(printf '%s\n' "${GITHUB_CONTEXT}" | base64 -w 0)"
+        encoded_runner="$(printf '%s\n' "${RUNNER_CONTEXT}" | base64 -w 0)"
+
+        # quote-aware split, matching how the inlined expressions were parsed upstream
+        split_into_args() {
+          if [ -n "$1" ]; then
+            printf '%s' "$1" | xargs -r true >/dev/null
+            while IFS= read -r -d '' t; do args+=("$t"); done \
+              < <(printf '%s' "$1" | xargs -r sh -c 'printf "%s\0" "$@"' sh)
+          fi
+        }
 
-        args=(${{ inputs.command }})
-        args+=(${{ inputs.subcommand }})
+        args=()
+        split_into_args "$INPUT_COMMAND"
+        split_into_args "$INPUT_SUBCOMMAND"
         args+=(--github-context)
         args+=("${encoded_github}")
         args+=(--runner-context)
         args+=("${encoded_runner}")
-        args+=(${{ inputs.arguments }})
+        split_into_args "$INPUT_ARGUMENTS"
 
-        echo "::set-output name=provenance_args::${args[@]}"
+        "$INSTALL_PATH/slsa-provenance" "${args[@]}"
       env:
         GITHUB_CONTEXT: ${{ inputs.github_context }}
         RUNNER_CONTEXT: ${{ inputs.runner_context }}
-
-    - name: Generate provenance
-      shell: bash
-      run: $INSTALL_PATH/slsa-provenance ${{ steps.compose-args.outputs.provenance_args }}
-      env:
+        INPUT_COMMAND: ${{ inputs.command }}
+        INPUT_SUBCOMMAND: ${{ inputs.subcommand }}
+        INPUT_ARGUMENTS: ${{ inputs.arguments }}
         INSTALL_PATH: ${{ inputs.install-dir }}

```

Locations:

- `action.yaml`

### prior-fix (severity: high)

Carried forward from this version's previous harden, which fixed it; fix it again unless the code no longer has the problem. The previous harden changed install-slsa-provenance.sh without recording a finding for it, and this analysis reported nothing there. Re-apply its security changes unless the code no longer needs them. The previous patch:
```diff
diff --git a/install-slsa-provenance.sh b/install-slsa-provenance.sh
index 6db18c7..278c0a9 100755
--- a/install-slsa-provenance.sh
+++ b/install-slsa-provenance.sh
@@ -106,4 +106,5 @@ tar -xzf "${ARCHIVE}" "${BINARY}"
 rm "${ARCHIVE}"
 
 # for testing purposes fall back to "$INSTALL_PATH/GITHUB_PATH"
-echo "$INSTALL_PATH" >> "${GITHUB_PATH:-"$INSTALL_PATH/GITHUB_PATH"}"
+SAFE_INSTALL_PATH="$(printf '%s' "$INSTALL_PATH" | tr -d '\n\r')"
+echo "$SAFE_INSTALL_PATH" >> "${GITHUB_PATH:-"$INSTALL_PATH/GITHUB_PATH"}"

```

Locations:

- `install-slsa-provenance.sh`

## Iteration Notes

### Iteration 1

**Fixes applied:** script-injection, github-env-injection, static-inline-injection, prior-fix

**Notes:**

I fixed all the findings in action.yaml and install-slsa-provenance.sh by re-applying the previous harden's changes. Nothing was run or tested.

action.yaml:
- The install script path is now quoted.
- The 'compose arguments' and 'Generate provenance' steps are merged into one step. It keeps id compose-args and is named 'Generate provenance'. This removes the deprecated ::set-output step output, which used to be pasted back into the shell command.
- The command, subcommand and arguments inputs now come in through env: variables instead of ${{ }} expressions inside the script.
- Those three inputs are split into an argument list the same way the shell split them before, respecting quotes. The split runs only when the value is non-empty, and an unmatched quote makes the step fail instead of silently dropping arguments.
- The github and runner context values are now quoted when base64-encoded.
- The binary is run as "$INSTALL_PATH/slsa-provenance" with the arguments passed as an array.

install-slsa-provenance.sh: newlines and carriage returns are removed from INSTALL_PATH before it is written to $GITHUB_PATH.

