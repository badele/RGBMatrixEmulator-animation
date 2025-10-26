#!/usr/bin/env python3
"""
Extract Giphy datas from a Giphy HTML page
Usage:
  ./giphy_extract.py <fichier.html>                    # Show all informations
  ./giphy_extract.py <fichier.html> username           # Show Username
  ./giphy_extract.py <fichier.html> images.gif         # SHow GIF URL
"""

import sys
import re
import json


def extract_giphy_data(content):
    """Extract Giphy data from HTML content"""

    # remove backslashes before quotes and backslashes
    content = content.replace(r"\"", '"').replace(r"\\", "\\")

    data = {}

    # Regex pattern for extracting values
    simple_fields = {
        "id": r'"id":"([a-zA-Z0-9]{10,})"',
        "username": r'"username":"([^"]+)"',
        "title": r'"title":"([^"]+)"',
        "url": r'"url":"(https://giphy\.com/gifs/[^"]+)"',
        "slug": r'"slug":"([^"]+)"',
        "rating": r'"rating":"([^"]+)"',
        "source": r'"source":"([^"]+)"',
    }

    for key, pattern in simple_fields.items():
        match = re.search(pattern, content)
        if match:
            value = match.group(1)
            # Filtrer les faux IDs (GTM, etc.)
            if key == "id" and ("GTM" in value or len(value) < 10):
                continue
            data[key] = value

    # Tags
    tags_match = re.search(r'"tags":\[([^\]]+)\]', content)
    if tags_match:
        data["tags"] = re.findall(r'"([^"]+)"', tags_match.group(1))

    # Get GIF, WEBP, MP4 images format
    images = {}
    for ext in ["gif", "webp", "mp4"]:
        urls = set(
            re.findall(
                f'(https://(?:media\\d*|i)\\.giphy\\.com/[^"]+\\.{ext})', content
            )
        )
        if urls:
            images[ext] = min(urls, key=len)

    data["images"] = images

    return data


def get_nested_value(data, path):
    """Extract a nested value using a dot-separated path"""
    keys = path.split(".")
    value = data

    for key in keys:
        if isinstance(value, dict) and key in value:
            value = value[key]
        else:
            return None

    return value


def main():
    if len(sys.argv) < 2:
        print("Usage: ./giphy_extract.py <fichier.html> [champ]", file=sys.stderr)
        print("\nExamples:", file=sys.stderr)
        print("  ./giphy_extract.py page.html", file=sys.stderr)
        print("  ./giphy_extract.py page.html username", file=sys.stderr)
        print("  ./giphy_extract.py page.html images.gif", file=sys.stderr)
        print("  ./giphy_extract.py page.html tags", file=sys.stderr)
        sys.exit(1)

    # Read the HTML file
    with open(sys.argv[1], "r", encoding="utf-8") as f:
        content = f.read()

    # Extract datas
    data = extract_giphy_data(content)

    # Optional field extraction
    if len(sys.argv) > 2:
        field = sys.argv[2]
        value = get_nested_value(data, field)

        if value is None:
            print(f"Erreur: champ '{field}' introuvable", file=sys.stderr)
            print(f"Champs disponibles: {', '.join(data.keys())}", file=sys.stderr)
            sys.exit(1)

        if isinstance(value, list):
            for item in value:
                print(item)
        elif isinstance(value, dict):
            print(json.dumps(value, indent=2, ensure_ascii=False))
        else:
            print(value)
    else:
        print(json.dumps(data, indent=2, ensure_ascii=False))


if __name__ == "__main__":
    main()
