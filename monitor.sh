#!/bin/bash
# chihugame.cn 拨测：只看域名可达性（访客视角）
# up=域名 200  down=其他（超时/5xx/403 都算挂）
# 只在状态变化时通过 Server酱 推送微信
KEY="${SERVERCHAN_KEY}"
UA="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 Chrome/120 Safari/537.36"

check() { curl -s -o /dev/null -m 25 -w "%{http_code}" -A "$UA" "$1"; }
c_site=$(check "https://chihugame.cn/")

if [ "$c_site" = "200" ]; then now="up"; else now="down"; fi

prev=$(cat state.txt 2>/dev/null || echo "unknown")
echo "$now" > state.txt

echo "$(date -u '+%F %T') UTC prev=$prev now=$now site=$c_site"

[ "$prev" = "unknown" ] && exit 0
[ "$prev" = "$now" ] && exit 0

if [ "$now" = "down" ]; then
  title="🔴 网站打不开！去 Cloudflare 点橙云"
  desp="状态码 $c_site

**操作**：Cloudflare 后台 → DNS → 两条 A 记录 → 云朵点橙
点完几分钟内会收到「已恢复访问」的确认推送。$(date -u '+%F %T') UTC"
else
  title="🟢 网站已恢复"
  desp="状态码 $c_site，域名可访问。
若橙云还开着，可把 Cloudflare 两条记录点回灰云提速。$(date -u '+%F %T') UTC"
fi

curl -s -m 15 "https://sctapi.ftqq.com/${KEY}.send" \
  --data-urlencode "title=${title}" \
  --data-urlencode "desp=${desp}" >/dev/null
echo "pushed: $title"
