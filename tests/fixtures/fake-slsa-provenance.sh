#!/bin/sh
# Fake slsa-provenance binary for testing
output_path=""
prev=""
for arg in "$@"; do
  case "$prev" in
    --output-path) output_path="$arg" ;;
  esac
  prev="$arg"
done
if [ -z "$output_path" ]; then
  echo "ERROR: --output-path not specified" >&2
  exit 1
fi
cat > "$output_path" << 'PROVEOF'
{
  "_type": "https://in-toto.io/Statement/v0.1",
  "predicateType": "https://slsa.dev/provenance/v0.2",
  "subject": [
    {
      "name": "test-artifact.txt",
      "digest": {
        "sha256": "a948904f2f0f479b8f936065052a5b8e4b5b5b5b5b5b5b5b5b5b5b5b5b5b5b5"
      }
    }
  ],
  "predicate": {
    "builder": {
      "id": "https://github.com/philips-labs/slsa-provenance-action"
    },
    "buildType": "https://github.com/philips-labs/slsa-provenance-action/generate/files@v0.7.2",
    "invocation": {},
    "materials": [
      {
        "uri": "pkg:deb/debian/stunnel4@5.50-3?arch=amd64",
        "digest": {
          "sha256": "e1731ae217fcbc64d4c00d707dcead45c828c5f762bcf8cc56d87de511e096fa"
        }
      }
    ]
  }
}
PROVEOF
echo "Provenance written to $output_path"
