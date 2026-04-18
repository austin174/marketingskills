#!/bin/bash
set -euo pipefail

# Skills skipped because superior versions exist in claude-seo.
# Decision rationale: Rephlex Digital/internal/rephlex-skills-ecosystem/.planning/skill-overlap-analysis.md
#   seo-audit        → claude-seo:seo-audit (subagent orchestration, crawling, scoring, PDF)
#   schema-markup    → claude-seo:seo-schema (current deprecation status, deeper validation)
#   programmatic-seo → claude-seo:seo-programmatic (compliance gates, enforcement dates, scoring)
#   ai-seo           → claude-seo:seo-geo (technical depth, DataForSEO, RSL 1.0, crawler mgmt)
SKIP_SKILLS="seo-audit schema-markup programmatic-seo ai-seo"

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
CLAUDE_DIR="$HOME/.claude"

echo "Installing marketingskills from $REPO_DIR"
echo ""

symlink_item() {
    local source="$1"
    local target="$2"
    local name="$3"

    if [ -e "$target" ] && [ ! -L "$target" ]; then
        echo "  Backing up existing $name -> ${name}.bak"
        mv "$target" "${target}.bak"
    fi
    ln -sfn "$source" "$target"
    echo "  + $name"
}

is_skipped() {
    local name="$1"
    for skip in $SKIP_SKILLS; do
        if [ "$name" = "$skip" ]; then
            return 0
        fi
    done
    return 1
}

# Skills
echo "Skills:"
mkdir -p "$CLAUDE_DIR/skills"
installed=0
skipped=0
skipped_names=""
for skill_dir in "$REPO_DIR/skills"/*/; do
    [ -d "$skill_dir" ] || continue
    skill_name="$(basename "$skill_dir")"
    if is_skipped "$skill_name"; then
        skipped=$((skipped + 1))
        skipped_names="${skipped_names}  ${skill_name}\n"
        continue
    fi
    symlink_item "$skill_dir" "$CLAUDE_DIR/skills/$skill_name" "$skill_name"
    installed=$((installed + 1))
done

echo ""
if [ "$skipped" -gt 0 ]; then
    echo "Skipped ($skipped skills — better version in claude-seo):"
    echo -e "$skipped_names"
fi
echo "Done. ${installed} skill(s) installed, ${skipped} skipped."
echo "INSTALLED:${installed} SKIPPED:${skipped}"
