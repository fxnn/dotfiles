#!/bin/sh
# Claude Code status line - inspired by gruvbox-fxnn zsh theme

input=$(cat)

# Current working directory (used for git only, not displayed)
cwd=$(echo "$input" | jq -r '.workspace.current_dir // .cwd')

# Git branch and dirty status (no powerline icon)
git_info=""
if git -C "$cwd" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  branch=$(git -C "$cwd" symbolic-ref --short HEAD 2>/dev/null || git -C "$cwd" rev-parse --short HEAD 2>/dev/null)
  dirty=$(git -C "$cwd" --no-optional-locks status --porcelain 2>/dev/null)
  if [ -n "$dirty" ]; then
    git_info=" ${branch} ●"
  else
    git_info=" ${branch}"
  fi
fi

# Context window percentage + progress bar
ctx_segment=""
used=$(echo "$input" | jq -r '.context_window.used_percentage // empty')
if [ -n "$used" ]; then
  pct=$(printf '%.0f' "$used")

  bar_width=10
  filled=$(( pct * bar_width / 80 ))
  [ "$filled" -gt "$bar_width" ] && filled=$bar_width
  empty=$(( bar_width - filled ))

  bar=""
  i=0; while [ "$i" -lt "$filled" ]; do bar="${bar}█"; i=$(( i + 1 )); done
  i=0; while [ "$i" -lt "$empty" ]; do bar="${bar}░"; i=$(( i + 1 )); done

  # 64% context = 80% of the ~80% compaction threshold → switch to bright yellow
  if [ "$pct" -ge 64 ]; then
    bar_esc="\033[93m"
  else
    bar_esc="\033[36m"
  fi

  ctx_segment="ctx:${pct}% ${bar_esc}${bar}"
fi

# Session cost (approximate, based on cumulative token usage)
# Rates: $3/M input tokens, $15/M output tokens (Claude Sonnet)
cost_segment=""
total_in=$(echo "$input" | jq -r '.context_window.total_input_tokens // empty')
total_out=$(echo "$input" | jq -r '.context_window.total_output_tokens // empty')
if [ -n "$total_in" ] && [ -n "$total_out" ]; then
  cost=$(awk "BEGIN { printf \"%.4f\", ($total_in / 1000000 * 3) + ($total_out / 1000000 * 15) }")
  cost_segment="\$${cost}"
fi

# Model + effort
model=$(echo "$input" | jq -r '.model.display_name // empty')
effort=$(echo "$input" | jq -r '.effort.level // empty')

dot=" · "

out="\033[32m${model}${effort:+ $effort}"
[ -n "$ctx_segment" ]  && out="${out}\033[36m${dot}${ctx_segment}"
[ -n "$cost_segment" ] && out="${out}\033[33m${dot}${cost_segment}"
[ -n "$git_info" ]     && out="${out}\033[0m${dot}${git_info}"
out="${out}\033[0m"

printf "%b" "$out"
