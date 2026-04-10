#!/bin/bash
# AI-SBTI 数据提取脚本
# 扫描 ~/.claude/projects/ 下所有 JSONL 对话文件
# 提取用户消息的量化指标 + 样本消息
# 兼容 macOS (BSD grep/sed) 和 Linux

PROJECTS_DIR="$HOME/.claude/projects"

# 找到所有 JSONL 文件，按修改时间倒序
JSONL_FILES=$(find "$PROJECTS_DIR" -maxdepth 2 -name "*.jsonl" -type f 2>/dev/null | xargs ls -t 2>/dev/null)

if [ -z "$JSONL_FILES" ]; then
  echo '{"error": "no_jsonl_files_found"}'
  exit 1
fi

TOTAL_FILES=$(echo "$JSONL_FILES" | wc -l | tr -d ' ')

TMP_ALL=$(mktemp)
TMP_SAMPLES=$(mktemp)
TMP_TURNS=$(mktemp)
TMP_TEXT=$(mktemp)

# 用 jq 提取用户纯文本消息，过滤系统/命令消息，输出 JSON Lines 格式
for f in $JSONL_FILES; do
  jq -c 'select(
    .type=="user" and
    (.message.content | type) == "string" and
    (.message.content | length) > 0 and
    (.message.content | startswith("<") | not) and
    (.message.content | startswith("Implement the following plan") | not) and
    (.message.content | test("^(SES |Caveat:|Claude Code has)") | not) and
    (.userType // "" | test("^(internal)$") | not)
  ) | {sid: .sessionId, ts: .timestamp, text: .message.content}' "$f" 2>/dev/null
done > "$TMP_ALL"

TOTAL_MESSAGES=$(wc -l < "$TMP_ALL" | tr -d ' ')

if [ "$TOTAL_MESSAGES" -eq 0 ]; then
  echo '{"error": "no_user_messages_found"}'
  rm -f "$TMP_ALL" "$TMP_SAMPLES" "$TMP_TURNS" "$TMP_TEXT"
  exit 1
fi

# 日期范围
DATE_MIN=$(jq -r '.ts' "$TMP_ALL" | grep -E '^[0-9]{4}-' | sort | head -1 | cut -dT -f1)
DATE_MAX=$(jq -r '.ts' "$TMP_ALL" | grep -E '^[0-9]{4}-' | sort | tail -1 | cut -dT -f1)

# 提取纯文本到文件
jq -r '.text' "$TMP_ALL" > "$TMP_TEXT"

# 总字数 & 平均长度
TOTAL_CHARS=$(awk '{s+=length($0)}END{print s+0}' "$TMP_TEXT")
AVG_LENGTH=$(echo "scale=1; $TOTAL_CHARS / $TOTAL_MESSAGES" | bc 2>/dev/null || echo "0")

# 唯一会话数 & 平均轮数
UNIQUE_SESSIONS=$(jq -r '.sid' "$TMP_ALL" | sort -u | wc -l | tr -d ' ')
jq -r '.sid' "$TMP_ALL" | sort | uniq -c | awk '{print $1}' > "$TMP_TURNS"
AVG_TURNS=$(awk '{s+=$1; n++}END{if(n>0) printf "%.1f", s/n; else print 0}' "$TMP_TURNS")

# 感叹号密度
EXCL_COUNT=$(grep -o '[！!]' "$TMP_TEXT" | wc -l | tr -d ' ')
EXCL_DENSITY=$(echo "scale=3; $EXCL_COUNT / $TOTAL_MESSAGES" | bc 2>/dev/null || echo "0")

# 问号密度
QUES_COUNT=$(grep -o '[？?]' "$TMP_TEXT" | wc -l | tr -d ' ')
QUES_DENSITY=$(echo "scale=3; $QUES_COUNT / $TOTAL_MESSAGES" | bc 2>/dev/null || echo "0")

# emoji 密度（用 LC_ALL=C + grep -c 匹配高位 UTF-8 字节序列，兼容 macOS）
EMOJI_COUNT=$(LC_ALL=C grep -o $'\xf0\x9f[\x80-\xbf][\x80-\xbf]' "$TMP_TEXT" 2>/dev/null | wc -l | tr -d ' ')
if [ "$TOTAL_CHARS" -gt 0 ]; then
  EMOJI_DENSITY=$(echo "scale=4; $EMOJI_COUNT / $TOTAL_CHARS" | bc 2>/dev/null || echo "0")
else
  EMOJI_DENSITY="0"
fi

# 关键词计数函数（使用 grep -oiE 兼容 macOS）
count_keywords() {
  local pattern="$1"
  grep -oiE "$pattern" "$TMP_TEXT" | wc -l | tr -d ' '
}

# ═══════════════════════════════════════
# 关键词表 v2（扩充版）
# ═══════════════════════════════════════

# 礼貌词（中文 + 英文混用 + 网络变体）
POLITE_COUNT=$(count_keywords '谢谢|感谢|谢啦|谢了|多谢|3Q|蟹蟹|辛苦了|辛苦啦|麻烦你|麻烦了|请问|请帮|劳驾|拜托|太棒了|太好了|好棒|真棒|厉害|好厉害|太厉害|牛|真牛|优秀|完美|不错|很好|可以的|漂亮|精彩|感恩|nice|thanks|thank you|thx|please|pls|awesome|great|perfect|amazing|good job|well done')
POLITE_RATIO=$(echo "scale=3; $POLITE_COUNT / $TOTAL_MESSAGES" | bc 2>/dev/null || echo "0")

# 祈使词（命令/请求/指令）
IMPER_COUNT=$(count_keywords '帮我|给我|帮忙|告诉我|说说|讲讲|看看|试试|改成|换成|列出|写一个|做一个|弄一个|整一个|生成|翻译|重写|创建|搜索|查找|查看|检查|分析|解释|总结|优化|改进|升级|删除|去掉|移除|添加|加上|加入|画|设计|实现|部署|运行|启动|能不能|可不可以|可以帮|你来|你去|你把|help me|fix|change|update|modify|create|build|make|write|add|remove|delete|show me|tell me|find|search|run|deploy|implement')
IMPER_RATIO=$(echo "scale=3; $IMPER_COUNT / $TOTAL_MESSAGES" | bc 2>/dev/null || echo "0")

# 迭代词（修改/否定/反复）
ITER_COUNT=$(count_keywords '再改|不对|重新|换个|不是这样|再来|调整一下|改一下|重构|再试|修改|不太对|还是不|再想想|改回去|撤销|回退|有问题|有bug|还不够|不满意|差一点|上面的|之前的|刚才的|换一种|另一个|其他方案|再优化|再完善|再详细|不太行|这个不好|算了还是|wait|actually|never ?mind|no not|wrong|undo|revert|go back|try again|not right|not what I')
ITER_RATIO=$(echo "scale=3; $ITER_COUNT / $TOTAL_MESSAGES" | bc 2>/dev/null || echo "0")

# 闲聊词（情绪表达/网络用语/感叹）
CASUAL_COUNT=$(count_keywords '哈哈|hh|233|卧槽|我靠|我擦|我天|好累|累死|崩溃|开心|难过|无聊|emo|牛逼|nb|666|tql|yyds|我去|天哪|妈呀|我的天|天啊|我滴妈|绝了|离谱|抽象|笑死|服了|裂开|破防|好家伙|真的假的|草|蚌埠住|绷不住|太秀了|无敌|碉堡|什么鬼|搞笑|逆天|寄|麻了|顶|赞|秀|awsl|lol|lmao|omg|wtf|wow|bruh|damn|haha')
CASUAL_RATIO=$(echo "scale=3; $CASUAL_COUNT / $TOTAL_MESSAGES" | bc 2>/dev/null || echo "0")

# 情感倾诉词（自我表达/内心独白/人生话题）
EMOTION_COUNT=$(count_keywords '我觉得|我感觉|我好像|我不知道|我该不该|我是不是|好烦|好难|怎么办|受不了|想哭|压力好大|不开心|迷茫|焦虑|纠结|犹豫|害怕|郁闷|烦躁|无语|头疼|心累|丧|烦死|想死|活着|人生|意义|未来|分手|离职|跳槽|孤独|寂寞|委屈|失落|后悔|内耗|自卑|社恐|emo了|不想干|想放弃|太难了|撑不住|心情|情绪|感到|觉得自己|对自己')
EMOTION_RATIO=$(echo "scale=3; $EMOTION_COUNT / $TOTAL_MESSAGES" | bc 2>/dev/null || echo "0")

# 角色设定词（关系轴强信号：把 AI 当搭子/赋予人格）
ROLE_COUNT=$(count_keywords '你是一个|你扮演|假装你是|你现在是|角色扮演|你的角色|你来当|你就是|persona|role ?play|act as|you are a|pretend|imagine you')
ROLE_RATIO=$(echo "scale=3; $ROLE_COUNT / $TOTAL_MESSAGES" | bc 2>/dev/null || echo "0")

# 语气符号统计
TILDE_COUNT=$(grep -o '[~～]' "$TMP_TEXT" | wc -l | tr -d ' ')
ELLIPSIS_COUNT=$(grep -oE '\.{3,}|…|。{2,}' "$TMP_TEXT" | wc -l | tr -d ' ')
MULTI_EXCL=$(grep -oE '[!！]{2,}' "$TMP_TEXT" | wc -l | tr -d ' ')
MULTI_QUES=$(grep -oE '[?？]{2,}' "$TMP_TEXT" | wc -l | tr -d ' ')

# 小时分布
HOUR_DIST=$(jq -r '.ts' "$TMP_ALL" | grep -oE 'T[0-9]{2}' | sed 's/T//' | sort | uniq -c | sort -k2 -n | awk '{printf "\"%s\":%s,", $2, $1}' | sed 's/,$//')

# 采样：最近 20 个会话，每会话前 3 条用户消息
jq -r '.sid' "$TMP_ALL" | awk '!seen[$0]++' | tail -20 > "$TMP_SAMPLES.sids"
SAMPLES_JSON=""
while IFS= read -r sid; do
  BATCH=$(jq -c "select(.sid==\"$sid\")" "$TMP_ALL" | head -3 | jq -c '{ts: .ts, text: (.text | if length > 200 then .[:200] + "..." else . end)}')
  if [ -n "$BATCH" ]; then
    if [ -n "$SAMPLES_JSON" ]; then
      SAMPLES_JSON="$SAMPLES_JSON
$BATCH"
    else
      SAMPLES_JSON="$BATCH"
    fi
  fi
done < "$TMP_SAMPLES.sids"

# 转为 JSON 数组
SAMPLES_ARRAY=$(echo "$SAMPLES_JSON" | jq -sc '.[0:60]')

# 输出最终 JSON
cat <<ENDJSON
{
  "meta": {
    "total_sessions": $UNIQUE_SESSIONS,
    "total_messages": $TOTAL_MESSAGES,
    "total_files": $TOTAL_FILES,
    "date_range": ["$DATE_MIN", "$DATE_MAX"]
  },
  "metrics": {
    "avg_message_length": $AVG_LENGTH,
    "avg_turns_per_session": $AVG_TURNS,
    "exclamation_density": $EXCL_DENSITY,
    "question_density": $QUES_DENSITY,
    "emoji_density": $EMOJI_DENSITY,
    "polite_words": {"count": $POLITE_COUNT, "ratio": $POLITE_RATIO},
    "imperative_words": {"count": $IMPER_COUNT, "ratio": $IMPER_RATIO},
    "iteration_words": {"count": $ITER_COUNT, "ratio": $ITER_RATIO},
    "casual_words": {"count": $CASUAL_COUNT, "ratio": $CASUAL_RATIO},
    "emotion_words": {"count": $EMOTION_COUNT, "ratio": $EMOTION_RATIO},
    "role_setting_words": {"count": $ROLE_COUNT, "ratio": $ROLE_RATIO},
    "tone_markers": {"tilde": $TILDE_COUNT, "ellipsis": $ELLIPSIS_COUNT, "multi_excl": $MULTI_EXCL, "multi_ques": $MULTI_QUES},
    "hour_distribution": {$HOUR_DIST}
  },
  "samples": $SAMPLES_ARRAY
}
ENDJSON

# 清理
rm -f "$TMP_ALL" "$TMP_SAMPLES" "$TMP_TURNS" "$TMP_TEXT" "$TMP_SAMPLES.sids"
