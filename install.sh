#!/bin/bash
# AI-SBTI 一键安装脚本
# 用法: curl -fsSL https://raw.githubusercontent.com/apri1one/ai-sbti/main/install.sh | bash

set -e

SKILL_DIR="$HOME/.claude/skills/ai-sbti"
REPO_RAW="https://raw.githubusercontent.com/apri1one/ai-sbti/main"

echo "🧠 正在安装 AI-SBTI 人格分析 skill..."

mkdir -p "$SKILL_DIR"

curl -fsSL "$REPO_RAW/SKILL.md" -o "$SKILL_DIR/SKILL.md"
curl -fsSL "$REPO_RAW/extract.sh" -o "$SKILL_DIR/extract.sh"
chmod +x "$SKILL_DIR/extract.sh"

echo "✅ 安装完成！"
echo ""
echo "使用方法：在 Claude Code 中输入 /ai-sbti"
echo "安装路径：$SKILL_DIR"
