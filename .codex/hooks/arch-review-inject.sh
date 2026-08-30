#!/bin/bash

INPUT=$(cat)
PROMPT=$(echo "$INPUT" | jq -r '.user_prompt // .message // empty' 2>/dev/null)

if [ -z "$PROMPT" ]; then
    exit 0
fi

if echo "$PROMPT" | grep -qiE '(implement|add|create|build|fix|refactor|modify|update|review).*(feature|service|agent|task|handler|model|component|module|endpoint|workflow|architecture|codebase)'; then
    cat << 'EOF'
{"additionalContext":"COVE ARCHITECTURE: Read AGENTS.md, CLAUDE.md, and .github/ai-review/senior-review.md. Search SwiftUI views, view models, services, SwiftData models, design tokens, and Keychain helpers. Preserve Daily Contract limits, Meltdown accessibility, MainActor and cancellation behavior, offline recovery, and Keychain-only secrets."}
EOF
fi

exit 0
