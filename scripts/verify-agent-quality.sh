#!/usr/bin/env bash
set -euo pipefail

root="$(git rev-parse --show-toplevel)"
cd "$root"

jq empty .codex/hooks.json .github/ai-review/review.schema.json

for hook in .codex/hooks/*.sh; do
    bash -n "$hook"
done

for skill in independent-review pr-lifecycle project-quality ship; do
    cmp ".agents/skills/$skill/SKILL.md" ".claude/skills/$skill/SKILL.md"
done

commands="$(jq -r '.. | objects | .command? // empty' .codex/hooks.json)"
test "$(printf '%s\n' "$commands" | sed '/^$/d' | wc -l | tr -d ' ')" = "2"
grep -Fqx 'bash "$(git rev-parse --show-toplevel)/.codex/hooks/arch-review-inject.sh"' <<<"$commands"
grep -Fqx 'bash "$(git rev-parse --show-toplevel)/.codex/hooks/stop-quality-prompt.sh"' <<<"$commands"

if grep -Eq '/Users/|Desktop/Projects' .codex/hooks.json; then
    echo "Codex hook commands must not contain a machine-specific checkout path" >&2
    exit 1
fi

test -z "$(printf '{}' | bash .codex/hooks/arch-review-inject.sh)"
prompt_output="$(printf '%s' '{"user_prompt":"implement a feature module"}' | bash .codex/hooks/arch-review-inject.sh)"
jq -e '.additionalContext | contains("COVE ARCHITECTURE")' <<<"$prompt_output" >/dev/null

stop_output="$(bash .codex/hooks/stop-quality-prompt.sh)"
grep -Fq 'Never call an unmerged candidate shipped.' <<<"$stop_output"

echo "Cove agent quality contract verified at $root"
