#!/usr/bin/env bash
# init-privacy.sh — 幂等地将 .project/ 排除出 Git 追踪
# 使用 info/exclude（本地私有配置），不修改 .gitignore（项目公共配置）
#
# 用法：在项目根目录运行
#   bash .project/scripts/init-privacy.sh
# 或由 Agent 在初始化时调用

set -euo pipefail

EXCLUDE_PATTERN='.project/'

# 1. 确认是 Git 仓库
if ! git_dir=$(git rev-parse --git-dir 2>/dev/null); then
  echo "ERROR: not a Git repository" >&2
  exit 1
fi

# 2. 检查 .project/ 内是否有已追踪文件
tracked=$(git ls-files -- .project/ 2>/dev/null || true)
if [[ -n "$tracked" ]]; then
  echo "WARNING: .project/ contains tracked files:" >&2
  echo "$tracked" >&2
  echo "" >&2
  echo "These must be handled before exclusion will take effect." >&2
  echo "Options:" >&2
  echo "  git rm --cached <file>   # untrack but keep on disk" >&2
  echo "  (requires user decision — this script will not modify tracked files)" >&2
  echo "" >&2
  # 继续执行 exclude 设置，但提醒用户已追踪文件不会被自动处理
fi

# 3. 检查是否已被忽略
if git check-ignore -q .project/ 2>/dev/null; then
  echo "OK: .project/ is already ignored"
  exit 0
fi

# 4. 解析 exclude 文件路径（普通仓库 = .git/info/exclude，worktree 可能不同）
exclude_file=$(git rev-parse --git-path info/exclude)

# 确保目录存在
mkdir -p "$(dirname "$exclude_file")"

# 确保文件存在
touch "$exclude_file"

# 5. 幂等追加
if grep -qxF "$EXCLUDE_PATTERN" "$exclude_file" 2>/dev/null; then
  echo "OK: $EXCLUDE_PATTERN already in $exclude_file"
else
  echo "$EXCLUDE_PATTERN" >> "$exclude_file"
  echo "ADDED: $EXCLUDE_PATTERN -> $exclude_file"
fi

# 6. 验证
if git check-ignore -q .project/ 2>/dev/null; then
  echo "VERIFIED: .project/ is now ignored by Git"
else
  echo "WARNING: .project/ is still not ignored — check $exclude_file" >&2
  exit 1
fi
