#!/usr/bin/env bash
# Regenerate index.html from the releases of PillarTree/Pillarius.
set -euo pipefail

cd "$(dirname "$0")"

REPO="PillarTree/Pillarius"
OUT="index.html"

RELEASES=$(gh release list --repo "$REPO" --limit 10 --json tagName,name,publishedAt,isLatest \
    --jq '.[] | "\(.tagName)|\(.name)|\(.publishedAt)|\(.isLatest)"')

BODY=""
while IFS='|' read -r tag name published is_latest; do
    [ -n "$tag" ] || continue
    DATE=$(date -u -d "$published" +"%Y-%m-%d" 2>/dev/null || echo "$published")
    BADGE=""
    [ "$is_latest" = "true" ] && BADGE=' <span class="badge">latest</span>'

    ASSETS=$(gh release view "$tag" --repo "$REPO" --json assets \
        --jq '.assets[] | "\(.name)|\(.size)"')
    LINKS=""
    while IFS='|' read -r aname asize; do
        [ -n "$aname" ] || continue
        MB=$(( asize / 1048576 ))
        URL="https://github.com/${REPO}/releases/download/${tag}/${aname}"
        if [[ "$aname" == *.sha256 ]]; then
            LINKS+=$"          <a class=\"asset sha\" href=\"${URL}\">checksum</a>"$'\n'
        else
            LINKS+=$"          <a class=\"asset\" href=\"${URL}\">${aname} (${MB} MB)</a>"$'\n'
        fi
    done <<< "$ASSETS"

    BODY+=$'    <div class="release">\n      <h2>'"${name}${BADGE}"$'</h2>\n      <p class="date">'"${DATE}"$'</p>\n      <div class="assets">\n'"${LINKS}"$'      </div>\n    </div>\n'
done <<< "$RELEASES"

cat > "$OUT" << EOF
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Pillarius Downloads</title>
<style>
  body { margin: 0; padding: 40px 20px; background: #1e1e2e; color: #cdd6f4;
         font-family: "DejaVu Sans", sans-serif; }
  main { max-width: 760px; margin: 0 auto; }
  h1 { color: #89b4fa; }
  .release { border: 1px solid #313244; border-radius: 8px; padding: 16px 20px; margin: 16px 0;
             background: #181825; }
  .release h2 { margin: 0 0 4px; font-size: 18px; }
  .date { color: #6c7086; font-size: 13px; margin: 0 0 12px; }
  .badge { background: #a6e3a1; color: #1e1e2e; font-size: 11px; border-radius: 10px;
           padding: 2px 8px; vertical-align: middle; }
  .assets { display: flex; flex-direction: column; gap: 6px; }
  a.asset { color: #89b4fa; text-decoration: none; font-size: 14px; }
  a.asset:hover { text-decoration: underline; }
  a.sha { color: #6c7086; font-size: 12px; }
  footer { margin-top: 40px; color: #6c7086; font-size: 12px; }
</style>
</head>
<body>
<main>
  <h1>Pillarius Downloads</h1>
  <p>Live ISO images of the Pillarius desktop environment.
     Variants: <strong>full</strong> (desktop apps, audio, bluetooth) and
     <strong>minimal</strong> (core Pillarius desktop).</p>
${BODY}
  <footer>Source: <a style="color:#89b4fa" href="https://github.com/PillarTree/Pillarius">PillarTree/Pillarius</a> &middot; Apt repo: <a style="color:#89b4fa" href="https://spacey32.github.io/pt-apt-repo/">pt-apt-repo</a></footer>
</main>
</body>
</html>
EOF

echo "wrote $OUT"