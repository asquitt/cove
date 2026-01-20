#!/bin/bash
# Pre-commit verification hook for Cove iOS project
# Ensures code compiles and tests pass before allowing commits

set -e

PROJECT_DIR="/Users/demarioasquitt/Desktop/Projects/Entrepreneurial/project-beta"
XCODE_PROJECT="$PROJECT_DIR/Cove/Cove.xcodeproj"
LOG_FILE="$PROJECT_DIR/.claude/hooks/build.log"

# Check if Xcode project exists
if [ ! -d "$XCODE_PROJECT" ]; then
    echo '{"continue": true, "systemMessage": "⚠️ Xcode project not found yet. Skipping build verification."}'
    exit 0
fi

echo "🔨 Running pre-commit verification..." >&2

# Build check
echo "Building project..." >&2
if ! xcodebuild -project "$XCODE_PROJECT" \
    -scheme Cove \
    -destination 'platform=iOS Simulator,name=iPhone 15' \
    -quiet \
    build 2>"$LOG_FILE"; then

    ERROR_MSG=$(tail -20 "$LOG_FILE" | tr '\n' ' ' | cut -c1-200)
    echo "{\"continue\": false, \"stopReason\": \"❌ Build failed. Fix errors before committing: $ERROR_MSG\"}"
    exit 2
fi

# Test check
echo "Running tests..." >&2
if ! xcodebuild test -project "$XCODE_PROJECT" \
    -scheme Cove \
    -destination 'platform=iOS Simulator,name=iPhone 15' \
    -quiet 2>>"$LOG_FILE"; then

    ERROR_MSG=$(tail -20 "$LOG_FILE" | tr '\n' ' ' | cut -c1-200)
    echo "{\"continue\": false, \"stopReason\": \"❌ Tests failed. Fix tests before committing: $ERROR_MSG\"}"
    exit 2
fi

echo '{"continue": true, "systemMessage": "✅ Build and tests passed. Commit allowed."}'
exit 0
