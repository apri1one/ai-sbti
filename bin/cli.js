#!/usr/bin/env node

const fs = require("fs");
const path = require("path");
const os = require("os");

const SKILL_DIR = path.join(os.homedir(), ".claude", "skills", "ai-sbti");
const SRC_DIR = path.join(__dirname, "..", "skill");

const files = ["SKILL.md", "extract.sh"];

console.log("🧠 正在安装 AI-SBTI 人格分析 skill...\n");

fs.mkdirSync(SKILL_DIR, { recursive: true });

for (const file of files) {
  const src = path.join(SRC_DIR, file);
  const dest = path.join(SKILL_DIR, file);
  fs.copyFileSync(src, dest);
  if (file.endsWith(".sh")) {
    fs.chmodSync(dest, 0o755);
  }
  console.log(`  ✓ ${file}`);
}

console.log(`\n✅ 安装完成！`);
console.log(`📁 安装路径：${SKILL_DIR}`);
console.log(`\n使用方法：在 Claude Code 中输入 /ai-sbti`);
