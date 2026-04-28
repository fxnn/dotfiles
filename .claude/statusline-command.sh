#!/bin/sh
# Claude Code status line - inspired by gruvbox-fxnn zsh theme

input=$(cat)

# Current working directory (used for git only, not displayed)
cwd=$(echo "$input" | jq -r '.workspace.current_dir // .cwd')

# Git branch and dirty status (no powerline icon)
git_info=""
if git -C "$cwd" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  branch=$(git -C "$cwd" symbolic-ref --short HEAD 2>/dev/null || git -C "$cwd" rev-parse --short HEAD 2>/dev/null)
  dirty=$(git -C "$cwd" status --porcelain 2>/dev/null)
  if [ -n "$dirty" ]; then
    git_info=" ${branch} ●"
  else
    git_info=" ${branch}"
  fi
fi

# Context window
context_info=""
used=$(echo "$input" | jq -r '.context_window.used_percentage // empty')
if [ -n "$used" ]; then
  context_info=" ctx:$(printf '%.0f' "$used")%"
fi

# Session cost (approximate, based on cumulative token usage)
# Rates: $3/M input tokens, $15/M output tokens (Claude Sonnet)
cost_info=""
total_in=$(echo "$input" | jq -r '.context_window.total_input_tokens // empty')
total_out=$(echo "$input" | jq -r '.context_window.total_output_tokens // empty')
if [ -n "$total_in" ] && [ -n "$total_out" ]; then
  cost=$(awk "BEGIN { printf \"%.4f\", ($total_in / 1000000 * 3) + ($total_out / 1000000 * 15) }")
  cost_info=" \$${cost}"
fi

# Model
model=$(echo "$input" | jq -r '.model.display_name // empty')

dot=" · "

printf "\033[32m%s\033[36m%s\033[33m%s\033[0m%s\033[0m" \
  "${model:+$model}" \
  "${context_info:+$dot${context_info# }}" \
  "${cost_info:+$dot${cost_info# }}" \
  "${git_info:+$dot${git_info# }}"
