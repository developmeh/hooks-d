#!/usr/bin/env bash
# Simple ask flow test - run manually and check results

set -e

CAPTURE_DIR=".test/captures"
rm -rf "$CAPTURE_DIR"
mkdir -p "$CAPTURE_DIR"

echo "Starting Claude with ask hook..."
echo ""
echo "Instructions:"
echo "1. Ask Claude to run: echo TESTME"
echo "2. When prompted, approve (select Yes)"
echo "3. Exit Claude (/exit)"
echo "4. This script will show the results"
echo ""
echo "Press Enter to start..."
read

HOOKS_CAPTURE_DIR="$CAPTURE_DIR" claude --settings .test/fixtures/pretooluse-ask-hooks.json

echo ""
echo "=== Results ==="
echo ""
echo "Hook invocation count:"
cat "$CAPTURE_DIR/ask_count" 2>/dev/null || echo "0"
echo ""
echo "Invocation files:"
ls -la "$CAPTURE_DIR"/ask_invocation_*.json 2>/dev/null || echo "None"
echo ""

COUNT=$(cat "$CAPTURE_DIR/ask_count" 2>/dev/null || echo "0")
if [ "$COUNT" -gt 1 ]; then
    echo "*** HOOK WAS CALLED $COUNT TIMES ***"
    echo "Claude re-invokes hooks after approval!"
else
    echo "Hook called once. No re-invocation after approval."
fi
