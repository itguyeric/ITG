#!/usr/bin/env bash
set -euo pipefail

OUTDIR="tuxcare_sources_$(date +%Y%m%d)"
HTMLDIR="$OUTDIR/html"
MDDIR="$OUTDIR/md"
MANIFEST="$OUTDIR/manifest.csv"
mkdir -p "$HTMLDIR" "$MDDIR"

echo "title,url,local_html,local_md" > "$MANIFEST"

convert_and_record () {
  local url="$1"
  local html_path="$2"

  local base="$(echo "$url" | sed 's#https\?://##; s#[^A-Za-z0-9._-]#_#g')"
  local md_path="$MDDIR/${base%.html}.md"

  local title="$(pup 'title text{}' < "$html_path" 2>/dev/null || true)"
  [[ -z "$title" ]] && title="$base"

  pandoc --from html --to gfm --wrap=none \
         --metadata=source:"$url" \
         -o "$md_path" "$html_path"

  echo "\"$title\",\"$url\",\"$html_path\",\"$md_path\"" >> "$MANIFEST"
}

while IFS= read -r url; do
  [[ -z "$url" || "$url" =~ ^# ]] && continue
  echo "[*] Fetching: $url"

  # Download page(s)
  wget --recursive --level=2 --timestamping --adjust-extension --page-requisites \
       --convert-links --no-parent --directory-prefix "$HTMLDIR" "$url"

  # Convert each HTML page grabbed for this URL
  while IFS= read -r -d '' f; do
    rel="${f#"$HTMLDIR"/}"
    if [[ "$rel" == tuxcare.com/* ]]; then
      page_url="https://${rel#tuxcare.com/}"
    elif [[ "$rel" == docs.tuxcare.com/* ]]; then
      page_url="https://${rel}"
    else
      page_url="$url"
    fi
    page_url="${page_url%/index.html}"
    convert_and_record "$page_url" "$f"
  done < <(find "$HTMLDIR" -type f \( -name "index.html" -o -name "*.html" \) -print0)
done < sources.txt

echo "Done! Output in: $OUTDIR"

