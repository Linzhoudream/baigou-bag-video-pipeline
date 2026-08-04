#!/usr/bin/env bash
# =============================================================
# 白沟箱包视频流水线 · 调度入口（dispatch）
# 用法：dispatch.sh <produce|test> <phase>
#   phase 支持逗号分隔，如 produce 1,2  /  produce 5,6  /  test 3
#
# 说明（重要）：
#   本环境没有 headless 执行器。此脚本是"定时触发入口"的落档骨架：
#   它把触发意图写入 state 文件并做人工收口点校验，真正的技能执行
#   由编排智能体（baigou-video-pipeline）接管。当平台具备"定时运行
#   技能"能力时，把本脚本接到编排智能体即可让定时任务真正生效。
#
#   人工收口点（不会自动跳过）：
#     - produce 3 之前需 gate:data_supplement（08:30 补数据）
#     - produce 5,6 之前需 gate:review_4_5（10:30 质量门通过）
#     - test 4 之前需 gate:verdict_1（裁决①）
#     - test 5 之前需 gate:verdict_2（裁决②）
# =============================================================
set -euo pipefail

MODE="${1:-produce}"
PHASE="${2:-}"
STATE_DIR="/workspace/skills/baigou-video-pipeline/.state"
STATE_FILE="$STATE_DIR/last_run.json"
GATE_FILE="$STATE_DIR/gate_passed.txt"
mkdir -p "$STATE_DIR"

# 需要人工收口门放行的 phase 映射
requires_gate() {
  case "$1" in
    produce:3)   echo "data_supplement" ;;   # 08:30 补数据
    produce:5|produce:6) echo "review_4_5" ;; # 10:30 质量门
    test:4)      echo "verdict_1" ;;          # 裁决①
    test:5)      echo "verdict_2" ;;          # 裁决②
    *)           echo "" ;;
  esac
}

ts=$(date '+%Y-%m-%d %H:%M:%S')
echo "{\"ts\":\"$ts\",\"mode\":\"$MODE\",\"phase\":\"$PHASE\",\"status\":\"triggered\"}" > "$STATE_FILE"

IFS=',' read -ra PHASES <<< "$PHASE"
for p in "${PHASES[@]}"; do
  gate=$(requires_gate "$MODE:$p")
  if [ -n "$gate" ]; then
    if ! grep -qx "$gate" "$GATE_FILE" 2>/dev/null; then
      echo "[HALT] phase=$MODE:$p 需要人工收口门 '$gate' 已通过才能运行。"
      echo "       请在人工完成对应动作后执行： echo $gate >> $GATE_FILE"
      echo "       然后再触发： dispatch.sh $MODE $p"
      exit 0
    fi
  fi
  echo "[RUN] 触发 $MODE:$p —— 交由编排智能体 baigou-video-pipeline 执行"
done
echo "[OK] 触发完成，等待编排智能体产出并写入对应腾讯文档库。"
