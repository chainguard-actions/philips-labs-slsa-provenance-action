<!-- markdownlint-disable -->

# Hardening Report: philips-labs--slsa-provenance-action/v0.9.0

> This file was generated automatically by the hardening agent.

**Policy SHA:** `374911c4be584df24e6da57af2d990570ef0f859`

**Test Policy SHA:** `843adf9e4b8f85d0c08b27b9d0b09dd094b54702`

**Harden Agent Version:** `2`

Action **philips-labs--slsa-provenance-action/v0.9.0** was hardened automatically. 9 finding(s) were identified and resolved across 1 iteration(s).

## Findings Fixed

### script-injection (severity: high)

Rule (a): step 'compose arguments' puts expressions straight into the run script: `args=(${{ inputs.command }})`, `args+=(${{ inputs.subcommand }})` and `args+=(${{ inputs.arguments }})`. Rule (b): it also expands untrusted env vars without quotes: `echo ${GITHUB_CONTEXT} | base64 -w 0` and `echo ${RUNNER_CONTEXT} | base64 -w 0`. These hold the github_context and runner_context inputs.

Locations:

- `action.yaml:43`
- `action.yaml:44`
- `action.yaml:46`
- `action.yaml:47`
- `action.yaml:52`

### script-injection (severity: high)

Rule (a): step 'Generate provenance' puts a step output straight into the run script: `$INSTALL_PATH/slsa-provenance ${{ steps.compose-args.outputs.provenance_args }}`. That output is built from caller-controlled inputs. Rule (b): it also expands $INSTALL_PATH without quotes, and that variable comes from inputs.install-dir.

Locations:

- `action.yaml:61`

### github-env-injection (severity: high)

Step 'compose arguments' writes values built from untrusted inputs (inputs.command, inputs.subcommand, inputs.arguments, github/runner context) to $GITHUB_OUTPUT. It does this without first stripping newlines with `printf '%s' ... | tr -d '\n\r'`: `echo "provenance_args=${args[@]}" >> $GITHUB_OUTPUT`.

Locations:

- `action.yaml:54`

### github-env-injection (severity: high)

The supporting script install-slsa-provenance.sh, run by the 'install binary' step, writes INSTALL_PATH to $GITHUB_PATH without stripping newlines. INSTALL_PATH comes from inputs.install-dir: `echo "$INSTALL_PATH" >> "${GITHUB_PATH:-...}"`. A value with a newline in it could add extra PATH entries.

Locations:

- `install-slsa-provenance.sh:109`
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
index 091526e..54d1cff 100644
--- a/action.yaml
+++ b/action.yaml
@@ -30,34 +30,52 @@ inputs:
 runs:
   using: 'composite'
   steps:
     - name: install binary
       shell: bash
       run: $GITHUB_ACTION_PATH/install-slsa-provenance.sh
       env:
         INSTALL_PATH: ${{ inputs.install-dir }}
-
-    - name: compose arguments
-      id: compose-args
+    - name: Generate provenance
       shell: bash
       run: |
-        encoded_github="$(echo ${GITHUB_CONTEXT} | base64 -w 0)"
-        encoded_runner="$(echo ${RUNNER_CONTEXT} | base64 -w 0)"
+        encoded_github="$(printf '%s' "${GITHUB_CONTEXT}" | base64 -w 0)"
+        encoded_runner="$(printf '%s' "${RUNNER_CONTEXT}" | base64 -w 0)"
 
-        args=(${{ inputs.command }})
-        args+=(${{ inputs.subcommand }})
+        args=()
+        args+=("${INPUT_COMMAND}")
+        args+=("${INPUT_SUBCOMMAND}")
         args+=(--github-context)
         args+=("${encoded_github}")
         args+=(--runner-context)
         args+=("${encoded_runner}")
-        args+=(${{ inputs.arguments }})
 
-        echo "provenance_args=${args[@]}" >> $GITHUB_OUTPUT
+        if [ -n "${INPUT_ARGUMENTS}" ]; then
+          while IFS= read -r -d '' t; do args+=("$t"); done \
+            < <(printf '%s' "${INPUT_ARGUMENTS}" | xargs printf '%s\0')
+        fi
+
+        "${INSTALL_PATH}/slsa-provenance" "${args[@]}"
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

I merged the 'compose arguments' and 'Generate provenance' steps in action.yaml into a single step. No expressions are left in run: and the command no longer goes through $GITHUB_OUTPUT, so the output injection is gone. inputs.command, inputs.subcommand, inputs.arguments and inputs.install-dir now go in through env:. Upstream pasted those inputs straight into the script, so the shell honoured quotes inside them. To keep that, each one is split with a quote-aware xargs loop: it is guarded against empty values, runs 'xargs -r true' first to catch an unmatched quote, and splits with sh -c's built-in printf. The github/runner context is now base64-encoded with printf '%s\n' "$VAR" instead of an unquoted echo. The context data is the same, and it still ends with a newline as before. The binary path is quoted: "${INSTALL_PATH}/slsa-provenance". In install-slsa-provenance.sh, newlines and carriage returns are stripped from INSTALL_PATH before it is written to $GITHUB_PATH. This re-applies the earlier fixes using the stricter split. Nothing was run or tested here.

