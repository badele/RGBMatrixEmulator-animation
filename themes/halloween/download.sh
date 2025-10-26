#!/usr/bin/env bash

DSTDIR=$(dirname -- "$(readlink -f -- "$0")")
CACHE_DIR="${DSTDIR}/../../.cache"
mkdir -p "${CACHE_DIR}"

COLS=${1:-160}
ROWS=${2:-120}

function download_gif() {
  GIF_URL=$1

  # Check cache first
  URL_SLUG=$(echo "${GIF_URL}" | sed 's|https\?://||g' | sed 's|[^a-zA-Z0-9]|-|g' | sed 's|-\+|-|g' | sed 's|^-||' | sed 's|-$||')
  CACHE_FILE="${CACHE_DIR}/${URL_SLUG}.gif"

  if [ ! -f "${CACHE_FILE}" ]; then
    echo "Downloading GIF from ${GIF_URL}..."
    curl -o "${CACHE_FILE}" "${GIF_URL}"
  fi

  if [ ! -f "${DSTDIR}/halloween-${URL_SLUG}.gif" ]; then
    echo "Resizing GIF ${GIF_URL}..."
    magick "${CACHE_FILE}" -coalesce -resize ${COLS}x${ROWS} -background black -gravity center -extent ${COLS}x${ROWS} +repage "${DSTDIR}/halloween-${URL_SLUG}-tmp.gif"
    gifsicle -O3 --lossy=80 --colors 256 "${DSTDIR}/halloween-${URL_SLUG}-tmp.gif" -o "${DSTDIR}/halloween-${URL_SLUG}.gif"
    rm -f "${DSTDIR}/halloween-${URL_SLUG}-tmp.gif"
  fi
}

function download_giphy() {
  IMAGE_ID=$1

  GIF_URL="https://media.giphy.com/media/${IMAGE_ID}/giphy.gif"
  URL_SLUG=$(echo "${GIF_URL}" | sed 's|https\?://||g' | sed 's|[^a-zA-Z0-9]|-|g' | sed 's|-\+|-|g' | sed 's|^-||' | sed 's|-$||')
  HTML_FILE="${CACHE_DIR}/${URL_SLUG}.html"

  if [ ! -f "${HTML_FILE}" ]; then
    echo "Downloading Giphy page for ${IMAGE_ID}..."
    curl -H "Accept: text/html" -L -o "${HTML_FILE}" "${GIF_URL}"
  fi

  # Extract information using Python script
  SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
  EXTRACT_SCRIPT="${SCRIPT_DIR}/scripts/extract_giphy_informations.py"

  TITLE=$(python3 "${EXTRACT_SCRIPT}" "${HTML_FILE}" title 2>/dev/null || echo "")
  USERNAME=$(python3 "${EXTRACT_SCRIPT}" "${HTML_FILE}" username 2>/dev/null || echo "")

  # Add to README.md
  echo "| [${TITLE:-$IMAGE_ID}](${GIF_URL})<br/>by @${USERNAME:-unknown} |  <img src="${GIF_URL}" width="256" > |" >>"${DSTDIR}/README.md"

  # Download the actual GIF
  download_gif "${GIF_URL}" "${IMAGE_ID}"
}

# Create README.md file
echo "# Halloween GIFs" >"${DSTDIR}/README.md"
echo "| GIF | Preview |" >>"${DSTDIR}/README.md"
echo "|-----|---------|" >>"${DSTDIR}/README.md"

# List of Giphy IDs to download
GIPHY_IDS=(
  "l3V0yA9zHe5m29sxW"
  "ec5iuhc2aM9o3uK64q"
  "iB9mAlgB12asM"
  "fyRfSdh84CKlcFc8J1"
  "3o7aDdSjGlUbmwFCQo"
  "h8pvAj9NzjWpu3k8gK"
  "ZE7HIGOs2d8m1XQTRh"
  "29Nnabr845KOFr7AIZ"
  "2Ioc8K6yZ5CICPFX2S"
  "jq5GzfuEKpV3uoSYOW"
  "0eOdRVoYVZRqw0A5Y2"
  "ciDGKyxPaPPfLY5Jpg"
  "P5YYEOW5AEeCC4TjHT"
  "CIQsyqt21ezmCa1F4u"
  "qN6Jr7USZEVZirM1i6"
  "MTvzkXaWznrQziM8RP"
  "f1Dxf0tdrXz77YOXq0"
  "pcgb1XcgTBBZgN4Nld"
  "zTFHLbmURJJLzKRluu"
  "LgGmre0SPLXeuZWDEV"
  "483Hg16QyWJkukMzF2"
  "5jT0pFUpLQkFREzNPt"
  "KW7M4i7laXJ1S6O2Wv"
  "LmgHHxtKgDsYrVsEOw"
  "hkqefnFjn2MWVl6xvq"
  "xTiTnDlUp3XAus5opW"
  "dt14CFyASRyb7fUKKh"
  "c4hEaXz05adQBA3xYU"
  "eTJoE8HCl4DcSP4wIF"
  "beX8YptPBFiEpsDGAr"
  "Q2hbO1Fka5QkPMfOMt"
  "msOjHcmLMkhBcSjnbp"
  "hvR6lRHuVTN8f1ZE5D"
  "UgVPj6fIiaLxWSghrK"
  "mFtPZMFQR1YRgPz36I"
  "gFhZjOtzoutSvckWPM"
  "l1J9L9V6KqrXknZpm"
  "zoqblNFJYl65DwhYhQ"
  "ghIEpEoOGzbtNnNOCS"
  "go3pCPP4899Jd3xb4p"
  "twgFM3rYM4UEwzDkcB"
  "unmf0ONMrP0ouY6Scu"
  "Jn5UpZDRsMu13XFc3A"
  "DbrzP4AgZMhMnragMZ"
  "thkBLONWa2V73QUCmt"
  "XGTgbXuLaecxYQi6Jr"
  "dwCVui85FpTJdp0HSj"
  "I0IuJNBo7IaaZnrWqn"
  "xT77XMusMwn5z6LCO4"
)

# Download all GIFs
for giphy_id in "${GIPHY_IDS[@]}"; do
  download_giphy "$giphy_id"
done
