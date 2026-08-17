#!/bin/bash

cat << 'EOF'
<user-prompt-submit-hook>
Before completing: preserve unrelated work. Run the focused XCTest and relevant build gates; exercise the real Simulator flow for UI, persistence, permissions, or accessibility changes; verify SwiftData, Keychain, error, and recovery behavior; require exact-commit review for material changes; label every unavailable gate or unverified claim.
At an authorized shipping boundary, commit the coherent checkpoint, push once, and report the exact PR state: absent, draft, ready, merged, or closed. Never call an unmerged candidate shipped.
</user-prompt-submit-hook>
EOF

exit 0
