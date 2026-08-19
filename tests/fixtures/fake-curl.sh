#!/bin/sh
# Fake curl: intercepts slsa-provenance downloads and serves a canned tarball.
# Supports both "curl URL | sh" (stdout) and hardened "curl -o FILE URL" (file).
out=""
prev=""
for arg in "$@"; do
  case "$prev" in
    -o|--output) out="$arg" ;;
    # Handle combined flags like -sLo where the next arg is the output file
    -*o) out="$arg" ;;
  esac
  prev="$arg"
done
case "$*" in
  *slsa-provenance*)
    if [ -n "$out" ]; then
      cp /tmp/fake-slsa-provenance.tar.gz "$out"
    else
      cat /tmp/fake-slsa-provenance.tar.gz
    fi
    exit 0
    ;;
esac
exec /usr/bin/curl "$@"
