#!/bin/bash
# Session end hook - Updates progress document with session summary
# Maintains continuity across multiple Claude Code sessions

set -e

PROJECT_DIR="/Users/demarioasquitt/Desktop/Projects/Entrepreneurial/project-beta"
PROGRESS_FILE="$PROJECT_DIR/PROGRESS.md"
SESSION_LOG="$PROJECT_DIR/.claude/session-history.log"

# Read hook input from stdin
INPUT=$(cat)

# Extract session info
SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // "unknown"')
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

# Log session end
mkdir -p "$(dirname "$SESSION_LOG")"
echo "[$TIMESTAMP] Session $SESSION_ID ended" >> "$SESSION_LOG"

# Output reminder to update progress
cat << EOF
{
  "continue": true,
  "systemMessage": "📝 Session ending. Remember to update PROGRESS.md with: 1) What was completed 2) Current blockers 3) Next steps for the next session."
}
EOF

exit 0
