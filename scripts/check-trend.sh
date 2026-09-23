#!/usr/bin/env bash
# check-trend.sh — 输出最近 N 个 session 的代码 vs 文档变更趋势
# 供 supervisor 或人类快速判断是否存在进度停滞
#
# 用法：在项目根目录运行
#   bash .project/scripts/check-trend.sh [session 数量，默认 5]
#
# 工作原理：
#   - 从 git log 中统计每个 session 区间的代码文件 vs 控制面文件的变更行数
#   - session 区间由 .project/sessions/ 下的日志文件推断
#   - 如果没有 session 日志，退回到最近 N 个 commit 的统计
#
# 输出：表格 + 简单的趋势判断

set -euo pipefail

N="${1:-5}"
PROJECT_DIR=".project"
SESSION_DIR="$PROJECT_DIR/sessions"

# 控制面文件的路径模式（这些变更算"文档"而非"代码"）
DOC_PATTERNS=(
  '.project/*'
  '*.md'
  'docs/*'
  'CLAUDE.md'
  'AGENTS.md'
  'AGENTS-INSTRUCTION.md'
)

# 构建 git diff 的排除参数
doc_exclude_args=()
doc_include_args=()
for p in "${DOC_PATTERNS[@]}"; do
  doc_exclude_args+=(":(exclude)$p")
  doc_include_args+=("$p")
done

echo "=== 最近 ${N} 个 commit 的变更趋势 ==="
echo ""
printf "%-12s  %10s  %10s  %s\n" "Commit" "Code Δ" "Doc Δ" "Message"
printf "%-12s  %10s  %10s  %s\n" "------" "------" "-----" "-------"

code_deltas=()
doc_deltas=()

while IFS='|' read -r hash msg; do
  hash=$(echo "$hash" | xargs)
  msg=$(echo "$msg" | xargs)

  # 代码变更：所有文件减去文档模式
  code_stat=$(git diff --shortstat "$hash^" "$hash" -- . "${doc_exclude_args[@]}" 2>/dev/null || echo "")
  code_ins=$(echo "$code_stat" | grep -oP '\d+(?= insertion)' || echo "0")
  code_del=$(echo "$code_stat" | grep -oP '\d+(?= deletion)' || echo "0")
  code_delta=$((code_ins + code_del))

  # 文档变更：只看文档模式
  doc_stat=$(git diff --shortstat "$hash^" "$hash" -- "${doc_include_args[@]}" 2>/dev/null || echo "")
  doc_ins=$(echo "$doc_stat" | grep -oP '\d+(?= insertion)' || echo "0")
  doc_del=$(echo "$doc_stat" | grep -oP '\d+(?= deletion)' || echo "0")
  doc_delta=$((doc_ins + doc_del))

  code_deltas+=("$code_delta")
  doc_deltas+=("$doc_delta")

  printf "%-12s  %10s  %10s  %s\n" "${hash:0:10}" "+/-${code_delta}" "+/-${doc_delta}" "${msg:0:50}"
done < <(git log --format="%H|%s" -n "$N" 2>/dev/null)

echo ""

# 简单趋势检测
if [[ ${#code_deltas[@]} -ge 3 ]]; then
  last3_code=("${code_deltas[@]: -3}")
  declining=true
  for ((i=1; i<${#last3_code[@]}; i++)); do
    if [[ ${last3_code[$i]} -ge ${last3_code[$((i-1))]} ]]; then
      declining=false
      break
    fi
  done

  if $declining; then
    echo "⚠️  代码变更连续 3 轮递减 (${last3_code[*]})"
  fi

  # 检查文档是否在膨胀
  last3_doc=("${doc_deltas[@]: -3}")
  inflating=true
  for ((i=1; i<${#last3_doc[@]}; i++)); do
    if [[ ${last3_doc[$i]} -le ${last3_doc[$((i-1))]} ]]; then
      inflating=false
      break
    fi
  done

  if $declining && $inflating; then
    echo "⚠️  代码变更递减的同时文档变更在增长——可能在磨洋工"
  fi
fi

# 检查最近两个 commit 的 message 是否高度相似（粗略检测"下一步重复"）
if [[ ${#code_deltas[@]} -ge 2 ]]; then
  msg1=$(git log --format="%s" -n 1 --skip 0 2>/dev/null)
  msg2=$(git log --format="%s" -n 1 --skip 1 2>/dev/null)
  if [[ "$msg1" == "$msg2" ]]; then
    echo "⚠️  最近两个 commit 的消息完全相同：'$msg1'"
  fi
fi

echo ""
echo "（以上为自动检测的粗略信号，具体判断请结合 SUPERVISOR.md 和 session 日志）"
