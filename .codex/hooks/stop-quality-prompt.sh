#!/bin/bash

cat << 'EOF'
<user-prompt-submit-hook>
Before completing: preserve unrelated work. Run the focused XCTest and relevant build gates; exercise the real Simulator flow for UI, persistence, permissions, or accessibility changes; verify SwiftData, Keychain, error, and recovery behavior; require exact-commit review for material changes; label every unavailable gate or unverified claim.
</user-prompt-submit-hook>
EOF

exit 0
