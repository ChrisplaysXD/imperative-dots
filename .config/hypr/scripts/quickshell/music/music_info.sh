#!/usr/bin/env bash

TMP_DIR="/tmp/eww_covers"
mkdir -p "$TMP_DIR"
PLACEHOLDER="$TMP_DIR/placeholder_blank.png"
STATE_FILE="$TMP_DIR/last_state.json"

# --- 1. ENSURE PLACEHOLDER EXISTS ---
if [ ! -f "$PLACEHOLDER" ]; then
    magick -size 500x500 xc:"#313244" "$PLACEHOLDER"
fi

run_matugen_on_art() {
    local art="$1"
    local hash="$2"
    local isPlaceholder=$(convert "$art" -format "%[hex:u.p{0,0}]" info: 2>/dev/null | cut -c1-6)
    if [[ "$isPlaceholder" != "313244" ]] && [[ -n "$isPlaceholder" ]]; then
        matugen -c /home/chrisplaysxd/.config/hypr/scripts/quickshell/music/matugen_music.toml image "$art" --source-color-index 0 >/dev/null 2>&1
        echo "$hash" > "$TMP_DIR/last_matugen_hash"
    else
        rm -f "/tmp/eww_covers/music_colors.json"
        echo "$hash" > "$TMP_DIR/last_matugen_hash"
    fi
}

# --- 2. ONE playerctl CALL for everything ---
raw=$(playerctl metadata --format \
    '{{status}}|{{xesam:title}}|{{xesam:artist}}|{{mpris:artUrl}}|{{mpris:length}}|{{position}}|{{playerName}}' \
    2>/dev/null)

if [ -z "$raw" ]; then
    STATUS="Stopped"
else
    IFS='|' read -r STATUS TITLE ARTIST rawUrl len_micro pos_micro player_raw <<< "$raw"
fi

if [ "$STATUS" = "Playing" ] || [ "$STATUS" = "Paused" ]; then

    # --- 3. ART CACHE LOGIC ---
    idStr="${TITLE:-unknown}-${ARTIST:-unknown}"
    trackHash=$(echo "$idStr" | md5sum | cut -d" " -f1)

    finalArt="$TMP_DIR/${trackHash}_art.jpg"
    blurPath="$TMP_DIR/${trackHash}_blur.png"
    lockFile="$TMP_DIR/${trackHash}.lock"

    displayArt="$PLACEHOLDER"
    displayBlur="$PLACEHOLDER"

    if [ -f "$finalArt" ] && [ -s "$finalArt" ]; then
        displayArt="$finalArt"
        if [ -f "$blurPath" ]; then displayBlur="$blurPath"; fi
        
        # Ensure simple dominant color exists
        if [ ! -f "$TMP_DIR/${trackHash}.color" ]; then
            accent=$(magick "$finalArt" -colors 8 -format "%c" histogram:info: | sort -nr | head -n 1 | awk '{for(i=1;i<=NF;i++) if($i ~ /^#/) {print $i; exit}}' | head -c 7)
            # Minimal brightness floor (35%) so it doesn't disappear if black
            accent=$(magick xc:"${accent:-#cba6f7}" -colorspace HSL -channel Lightness -evaluate Max 35% +channel -colorspace sRGB -format "%[hex:u]" info: 2>/dev/null | head -c 6)
            echo "#${accent}" > "$TMP_DIR/${trackHash}.color"
        fi

        last_gen=$(cat "$TMP_DIR/last_matugen_hash" 2>/dev/null)
        if [ "$last_gen" != "$trackHash" ]; then
            run_matugen_on_art "$finalArt" "$trackHash"
        fi
    else
        if [ ! -f "$lockFile" ] && [ -n "$rawUrl" ]; then
            touch "$lockFile"
            (
                trap "rm -f '$lockFile'" EXIT
                if [[ "$rawUrl" == http* ]]; then
                    curl -s -L --max-time 10 -o "$finalArt" "$rawUrl"
                else
                    cleanPath=$(echo "$rawUrl" | sed 's/file:\/\///g')
                    if [ -f "$cleanPath" ]; then
                        cp "$cleanPath" "$finalArt"
                    else
                        cp "$PLACEHOLDER" "$finalArt"
                    fi
                fi

                [ ! -s "$finalArt" ] && cp "$PLACEHOLDER" "$finalArt"

                isPlaceholder=$(convert "$finalArt" -format "%[hex:u.p{0,0}]" info: 2>/dev/null | cut -c1-6)
                if [[ "$isPlaceholder" == "313244" ]] || [[ -z "$isPlaceholder" ]]; then
                    cp "$finalArt" "$blurPath"
                    echo "#cba6f7" > "$TMP_DIR/${trackHash}.color"
                    rm -f "/tmp/eww_covers/music_colors.json"
                    echo "$trackHash" > "$TMP_DIR/last_matugen_hash"
                else
                    convert "$finalArt" -blur 0x20 -brightness-contrast -30x-10 "$blurPath" 2>/dev/null
                    accent=$(magick "$finalArt" -colors 8 -format "%c" histogram:info: | sort -nr | head -n 1 | awk '{for(i=1;i<=NF;i++) if($i ~ /^#/) {print $i; exit}}' | head -c 7)
                    accent=$(magick xc:"${accent:-#cba6f7}" -colorspace HSL -channel Lightness -evaluate Max 35% +channel -colorspace sRGB -format "%[hex:u]" info: 2>/dev/null | head -c 6)
                    echo "#${accent}" > "$TMP_DIR/${trackHash}.color"
                    matugen -c /home/chrisplaysxd/.config/hypr/scripts/quickshell/music/matugen_music.toml image "$finalArt" --source-color-index 0 >/dev/null 2>&1
                    echo "$trackHash" > "$TMP_DIR/last_matugen_hash"
                fi

                rm -f "$lockFile"
                (cd "$TMP_DIR" && ls -1t | tail -n +21 | xargs -r rm 2>/dev/null)
            ) &
        fi
    fi

    # --- 4. TIMING ---
    [ -z "$len_micro" ] || [ "$len_micro" -eq 0 ] 2>/dev/null && len_micro=1000000
    len_sec=$(( ${len_micro:-1000000} / 1000000 ))
    [ "$len_sec" -le 0 ] && len_sec=1

    if [ "$STATUS" = "Playing" ]; then
        pos_sec=$(( ${pos_micro:-0} / 1000000 ))
        jq -n -c --argjson pos "$pos_sec" --argjson len "$len_sec" \
            '{pos_sec: $pos, len_sec: $len}' > "$STATE_FILE"
    else
        pos_sec=0
        if [ -f "$STATE_FILE" ]; then
            saved_pos=$(jq -r '.pos_sec' "$STATE_FILE" 2>/dev/null)
            saved_len=$(jq -r '.len_sec' "$STATE_FILE" 2>/dev/null)
            if [ "$saved_len" = "$len_sec" ] && [ -n "$saved_pos" ] && [ "$saved_pos" != "null" ]; then
                pos_sec=$saved_pos
            fi
        fi
    fi

    [ "$pos_sec" -gt "$len_sec" ] && pos_sec=$len_sec
    percent=$(( pos_sec * 100 / len_sec ))
    pos_str=$(printf "%02d:%02d" $((pos_sec/60)) $((pos_sec%60)))
    len_str=$(printf "%02d:%02d" $((len_sec/60)) $((len_sec%60)))

    # --- 5. OUTPUT ---
    player_nice="${player_raw^}"
    accentColor=$(cat "$TMP_DIR/${trackHash}.color" 2>/dev/null || echo "#cba6f7")

    jq -n -c \
        --arg title   "${TITLE:-}" \
        --arg artist  "${ARTIST:-}" \
        --arg status  "$STATUS" \
        --arg len     "$len_sec" \
        --arg pos     "$pos_sec" \
        --arg len_str "$len_str" \
        --arg pos_str "$pos_str" \
        --arg percent "$percent" \
        --arg pname   "$player_raw" \
        --arg pnice   "$player_nice" \
        --arg blur    "file://$displayBlur" \
        --arg art     "file://$displayArt" \
        --arg accent  "$accentColor" \
        '{
            title:       $title,
            artist:      $artist,
            status:      $status,
            length:      ($len | tonumber),
            position:    ($pos | tonumber),
            lengthStr:   $len_str,
            positionStr: $pos_str,
            timeStr:     ($pos_str + " / " + $len_str),
            percent:     ($percent | tonumber),
            playerName:  $pname,
            source:      $pnice,
            blur:        $blur,
            artUrl:      $art,
            accent:      $accent,
            accent2:     $accent
        }'

else
    # --- FALLBACK (Stopped) ---
    rm -f "/tmp/eww_covers/music_colors.json"
    rm -f "$TMP_DIR/last_matugen_hash"

    if [ -f "$STATE_FILE" ]; then
        last_pos=$(jq -r '.pos_sec' "$STATE_FILE" 2>/dev/null)
        last_len=$(jq -r '.len_sec' "$STATE_FILE" 2>/dev/null)
    fi
    last_pos=${last_pos:-0}; last_len=${last_len:-1}
    [ "$last_len" -le 0 ] 2>/dev/null && last_len=1
    last_percent=$(( last_pos * 100 / last_len ))
    last_pos_str=$(printf "%02d:%02d" $((last_pos/60)) $((last_pos%60)))
    last_len_str=$(printf "%02d:%02d" $((last_len/60)) $((last_len%60)))

    jq -n -c \
        --arg placeholder "file://$PLACEHOLDER" \
        --arg pos_str "$last_pos_str" \
        --arg len_str "$last_len_str" \
        --arg percent "$last_percent" \
        '{
            title:       "Not Playing",
            artist:      "",
            status:      "Stopped",
            percent:     ($percent | tonumber),
            lengthStr:   $len_str,
            positionStr: $pos_str,
            timeStr:     ($pos_str + " / " + $len_str),
            source:      "Offline",
            playerName:  "",
            blur:        $placeholder,
            artUrl:      $placeholder,
            accent:      "#cba6f7",
            accent2:     "#cba6f7"
        }'
fi
