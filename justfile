#!/usr/bin/env just -f

set export

# This help
@help:
    just -l -u

# Get screen resolution
@get-resolution:
    magick import -window root -format "%wx%h" info:

# Download all Giphy GIFs for themes
download THEME WIDTH="640" HEIGHT="480" PIXEL_SIZE="4":
    #!/usr/bin/env bash
    COLS=$(({{ WIDTH }} / {{ PIXEL_SIZE }}))
    ROWS=$(({{ HEIGHT }} / {{ PIXEL_SIZE }}))
    
    themes/{{ THEME }}/download.sh $COLS $ROWS {{ PIXEL_SIZE }}
# Animate theme
animate THEME WIDTH="640" HEIGHT="480" PIXEL_SIZE="4":
    #!/usr/bin/env bash
    COLS=$(({{ WIDTH }} / {{ PIXEL_SIZE }}))
    ROWS=$(({{ HEIGHT }} / {{ PIXEL_SIZE }}))
    echo "▶️ Animating theme '{{ THEME }}' with ${COLS}x${ROWS} LEDs ({{ WIDTH }}x{{ HEIGHT }} pixel (pixel led size {{ PIXEL_SIZE }})"

    python rgb-animation.py --led-cols $COLS --led-rows $ROWS --pixel-size {{ PIXEL_SIZE }} --shuffle themes/{{ THEME }}/{{ THEME }}-*

# Serve Markdown pages
[group('debug')]
@markdown-serve:
   godown 
