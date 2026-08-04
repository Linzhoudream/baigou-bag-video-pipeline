#!/usr/bin/env bash
# 一键推送脚本（在能连 GitHub 的本地终端运行）
#
# 用法：
#   1) 设置环境变量（不要硬编码 token 到脚本里）：
#        export GH_TOKEN=ghp_xxx          # 你的 Personal Access Token（需 repo 权限）
#        export GH_USER=你的GitHub用户名
#   2) （可选）自定义：
#        export GH_REPO=仓库名            默认 baigou-bag-video-pipeline
#        export GH_BRANCH=分支名          默认 main
#   3) bash push.sh
#
# 说明：token 仅用于本次 push 的 remote URL，push 成功后立即把 remote 重置为
#       不含 token 的安全地址。若远程仓库尚未创建，取消下方 gh repo create 注释。

set -euo pipefail

: "${GH_TOKEN:?未设置 GH_TOKEN，请先 export GH_TOKEN=你的token}"
: "${GH_USER:?未设置 GH_USER，请先 export GH_USER=你的GitHub用户名}"

REPO="${GH_REPO:-baigou-bag-video-pipeline}"
BRANCH="${GH_BRANCH:-main}"

# 如需自动创建公开仓库，取消下一行注释并确保已 `gh auth login`：
# gh repo create "$REPO" --public --description "白沟箱包短视频 AI 内容流水线（开源技能包+方法论）" || true

git remote remove origin 2>/dev/null || true
git remote add origin "https://${GH_TOKEN}@github.com/${GH_USER}/${REPO}.git"
git branch -M "$BRANCH"
git push -u origin "$BRANCH"

# push 完成后清除 remote URL 中的 token
git remote set-url origin "https://github.com/${GH_USER}/${REPO}.git"
echo "✅ 已推送至 https://github.com/${GH_USER}/${REPO} （remote 中的 token 已清除）"
