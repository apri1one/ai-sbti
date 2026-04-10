# AI-SBTI 人格分析

通过分析你本地的 AI 聊天记录，判定你的 AI 使用人格类型（16 种之一）。

灵感来源于 [SBTI 赛博人格测试](https://sbti.unun.dev/)，但这是 AI 版——不用做题，直接扫你的聊天记录，用数据说话。

## 一键安装

```bash
curl -fsSL https://raw.githubusercontent.com/apri1one/ai-sbti/main/install.sh | bash
```

## 使用

在 Claude Code 中输入：

```
/ai-sbti
```

## 16 种人格

| 代号 | 名字 | 四轴 |
|------|------|------|
| YYDS | 压榨永动机 | 🔧👑🏊🔥 |
| sudo | 人形终端 | 🔧👑🏊🧊 |
| ASAP | 电子催命符 | 🔧👑🏄🔥 |
| K. | 标点绝育者 | 🔧👑🏄🧊 |
| WIKI | 貔貅 | 🔧🐑🏊🔥 |
| VOID | 单向透视镜 | 🔧🐑🏊🧊 |
| 3Q | 谢谢战士 | 🔧🐑🏄🔥 |
| 404 | 性缩力者 | 🔧🐑🏄🧊 |
| CP | 单机恋人 | 🫂👑🏊🔥 |
| HACK | 精神PUA师 | 🫂👑🏊🧊 |
| LOL | 调戏鬼才 | 🫂👑🏄🔥 |
| DAN | 越狱犯 | 🫂👑🏄🧊 |
| QAQ | 巨婴 | 🫂🐑🏊🔥 |
| NPC | 人肉复读机 | 🫂🐑🏊🧊 |
| zzZ | 午夜投喂员 | 🫂🐑🏄🔥 |
| AFK | 人间蒸发者 | 🫂🐑🏄🧊 |

### 四轴解读

| 维度 | 正极 | 反极 |
|------|------|------|
| 关系定位 | 🫂 搭子 | 🔧 工具 |
| 控制权 | 👑 甲方 | 🐑 乙方 |
| 使用深度 | 🏊 深水 | 🏄 浅水 |
| 情感温度 | 🔥 热的 | 🧊 冷的 |

## 工作原理

1. `extract.sh` 扫描 `~/.claude/projects/` 下所有 JSONL 对话文件
2. 提取用户消息，计算量化指标（礼貌词、祈使词、迭代词、闲聊词、情感词、角色设定词、语气符号等）
3. Claude 根据量化信号（60%）+ 样本定性分析（40%）对四轴评分
4. 匹配人格类型，输出锐评报告

## 要求

- [Claude Code](https://docs.anthropic.com/en/docs/claude-code) CLI
- macOS 或 Linux
- `jq` 已安装（`brew install jq` / `apt install jq`）

## License

MIT
