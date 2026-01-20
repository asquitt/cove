#!/bin/bash
# Post-edit hook for Swift files
# Checks for common issues after editing .swift files

set -e

# Read hook input from stdin
INPUT=$(cat)

# Extract the file path from tool input
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')

# Only process Swift files
if [[ ! "$FILE_PATH" =~ \.swift$ ]]; then
    echo '{"continue": true}'
    exit 0
fi

WARNINGS=""

# Check file length
if [ -f "$FILE_PATH" ]; then
    LINE_COUNT=$(wc -l < "$FILE_PATH" | tr -d ' ')
    if [ "$LINE_COUNT" -gt 300 ]; then
        WARNINGS="⚠️ File has $LINE_COUNT lines (max 300). Consider splitting."
    fi

    # Check for print statements (debugging leftovers)
    if grep -q "print(" "$FILE_PATH" 2>/dev/null; then
        PRINT_COUNT=$(grep -c "print(" "$FILE_PATH" || true)
        WARNINGS="$WARNINGS ⚠️ Found $PRINT_COUNT print() statements. Remove before commit."
    fi

    # Check for TODO comments without ticket
    if grep -qE "// TODO[^:]|// TODO$" "$FILE_PATH" 2>/dev/null; then
        WARNINGS="$WARNINGS ⚠️ Found TODO without description. Add context."
    fi

    # Check for force unwraps
    if grep -qE "![^=]" "$FILE_PATH" 2>/dev/null; then
        FORCE_COUNT=$(grep -cE "![^=]" "$FILE_PATH" || true)
        if [ "$FORCE_COUNT" -gt 3 ]; then
            WARNINGS="$WARNINGS ⚠️ Found $FORCE_COUNT potential force unwraps. Review for safety."
        fi
    fi
fi

if [ -n "$WARNINGS" ]; then
    echo "{\"continue\": true, \"systemMessage\": \"$WARNINGS\"}"
else
    echo '{"continue": true}'
fi

exit 0
