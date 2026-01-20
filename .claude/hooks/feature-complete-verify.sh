#!/bin/bash
# Feature completion verification hook for Cove iOS project
# Runs after Stop event to verify completed features work

set -e

PROJECT_DIR="/Users/demarioasquitt/Desktop/Projects/Entrepreneurial/project-beta"
PROGRESS_FILE="$PROJECT_DIR/PROGRESS.md"

# Read hook input from stdin
INPUT=$(cat)

# Extract session info
SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // empty')

# Check if this is a feature completion (look for completion indicators in transcript)
# This is a lightweight check - the main verification happens via prompts

# Output context for Claude to consider
cat << EOF
{
  "continue": true,
  "systemMessage": "🔍 Feature verification reminder: If you just completed a feature, verify it works before marking complete in PROGRESS.md. Use simulator screenshots or test output as evidence."
}
EOF

exit 0
