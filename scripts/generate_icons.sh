#!/bin/bash
# Сгенерировать PNG-иконки из SVG для всех плотностей.
# Запускать один раз после flutter create.
set -e

cd "$(dirname "$0")/.."

RES_DIR="android/app/src/main/res"

# Создаём SVG-шаблон
cat > /tmp/qs_icon.svg << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 108 108" width="108" height="108">
  <rect width="108" height="108" fill="#6750A4" rx="20"/>
  <rect x="30" y="28" width="48" height="52" rx="6" fill="#FFFFFF"/>
  <path d="M54,40 L54,68 M40,55 L54,68 L68,55" stroke="#6750A4" stroke-width="4" fill="none" stroke-linecap="round" stroke-linejoin="round"/>
</svg>
EOF

for ENTRY in "mipmap-mdpi:48" "mipmap-hdpi:72" "mipmap-xhdpi:96" "mipmap-xxhdpi:144" "mipmap-xxxhdpi:192"; do
    DIR="${ENTRY%%:*}"
    SIZE="${ENTRY##*:}"
    mkdir -p "$RES_DIR/$DIR"
    convert -background none -density 384 -resize ${SIZE}x${SIZE} /tmp/qs_icon.svg "$RES_DIR/$DIR/ic_launcher.png"
    convert -background none -density 384 -resize ${SIZE}x${SIZE} /tmp/qs_icon.svg "$RES_DIR/$DIR/ic_launcher_round.png"
    echo "Generated $RES_DIR/$DIR/ic_launcher.png (${SIZE}x${SIZE})"
done

rm /tmp/qs_icon.svg
echo "Done."
