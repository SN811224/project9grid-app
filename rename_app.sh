#!/usr/bin/env bash
set -e

APP_NAME="推薦互動程式"

echo "Updating app display name to: $APP_NAME"

# Android
if [ -f android/app/src/main/AndroidManifest.xml ]; then
  python3 - <<'PY'
from pathlib import Path
p = Path("android/app/src/main/AndroidManifest.xml")
s = p.read_text(encoding="utf-8")
import re
s = re.sub(r'android:label="[^"]*"', 'android:label="推薦互動程式"', s, count=1)
p.write_text(s, encoding="utf-8")
PY
fi

# iOS
if [ -f ios/Runner/Info.plist ]; then
  python3 - <<'PY'
from pathlib import Path
p = Path("ios/Runner/Info.plist")
s = p.read_text(encoding="utf-8")
import re
# Replace CFBundleDisplayName if present.
s = re.sub(
    r'(<key>CFBundleDisplayName</key>\s*<string>)(.*?)(</string>)',
    r'\1推薦互動程式\3',
    s,
    flags=re.S
)
# If no CFBundleDisplayName exists, inject before CFBundleExecutable.
if "CFBundleDisplayName" not in s:
    marker = "<key>CFBundleExecutable</key>"
    s = s.replace(marker, "<key>CFBundleDisplayName</key>\n\t<string>推薦互動程式</string>\n\t" + marker)
p.write_text(s, encoding="utf-8")
PY
fi

# Web title
if [ -f web/index.html ]; then
  python3 - <<'PY'
from pathlib import Path
import re
p = Path("web/index.html")
s = p.read_text(encoding="utf-8")
s = re.sub(r"<title>.*?</title>", "<title>推薦互動程式</title>", s, flags=re.S)
p.write_text(s, encoding="utf-8")
PY
fi

# Web manifest
if [ -f web/manifest.json ]; then
  python3 - <<'PY'
from pathlib import Path
import json
p = Path("web/manifest.json")
data = json.loads(p.read_text(encoding="utf-8"))
data["name"] = "推薦互動程式"
data["short_name"] = "推薦互動程式"
p.write_text(json.dumps(data, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
PY
fi

echo "Done."
