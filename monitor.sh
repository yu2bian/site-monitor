#!/bin/bash
# chihugame.cn 拨测：域名(经Cloudflare) + 源站直连 双探针
# 状态: up=全部正常  cf=Cloudflare接管中(源站不通)  down=全断
# 只在状态变化时通过 Server酱 推送微信
KEY="${SERVERCHAN_KEY}"
UA="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 Chrome/120 Safari/537.36"

check() { curl -s -o /dev/null -m 25 -w "%{http_code}" -A "$UA" "$1"; }
c_site=$(check "https://chihugame.cn/")
c_org=$(check "http://186.241.74.191/")

site_ok=$([ "$c_site" = "200" ] && echo 1 || echo 0)
org_ok=$([ "$c_org" = "200" ] && echo 1 || echo 0)

if [ "$site_ok" = "1" ] && [ "$org_ok" = "1" ]; then now="up"
elif [ "$site_ok" = "1" ]; then now="cf"
else now="down"; fi

prev=$(cat state.txt 2>/dev/null || echo "unknown")
echo "$now" > state.txt

echo "prev=$prev now=$now site=$c_site origin=$c_org"

# 首次运行只记状态不推送
[ "$prev" = "unknown" ] && exit 0
[ "$prev" = "$now" ] && exit 0

title=""; desp=""
case "$now" in
  down)
    title="🔴 网站打不开！去 Cloudflare 点橙云"
    desp="域名状态码 $c_site / 源站直连 $c_org

**操作**：Cloudflare 后台 → DNS → 两条 A 记录 → 云朵点橙
点完几分钟内会收到「接管中」的确认推送。$(date -u '+%F %T') UTC"
    ;;
  cf)
    if [ "$prev" = "down" ]; then
      title="🟠 Cloudflare 已接管，网站恢复访问"
      desp="源站直连 $c_org（线路仍被堵），经 Cloudflare 可访问 $c_site
保持橙云，等「线路恢复」推送后再点回灰。"
    else
      title="🟠 线路被堵，Cloudflare 接管中"
      desp="源站直连 $c_org / 域名 $c_site
若还没点橙云，现在去 Cloudflare 后台点。"
    fi
    ;;
  up)
    if [ "$prev" = "cf" ]; then
      title="🟢 线路恢复，可点回灰云"
      desp="源站直连已恢复（$c_org）。
过几分钟后把 Cloudflare 两条 A 记录点回「仅 DNS」，速度回到最快。
点回灰后若再收到🔴推送，说明又被打，再点回橙即可。"
    else
      title="🟢 网站已恢复"
      desp="源站 $c_org / 域名 $c_site，一切正常。"
    fi
    ;;
esac

curl -s -m 15 "https://sctapi.ftqq.com/${KEY}.send" \
  --data-urlencode "title=${title}" \
  --data-urlencode "desp=${desp}" >/dev/null
echo "pushed: $title"
