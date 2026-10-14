"""Screenshot an SVG in 1300 px tall segments with a headless Chromium browser.

usage: preview.py <file.svg> <output-dir>

Prints one PNG path per segment. Exits 2 when no browser is found; set CHROME_PATH to point at one.
Standard library only.
"""
import os
import re
import shutil
import subprocess
import sys
from pathlib import Path

SEGMENT_H = 1300
STEP = 1250  # segments overlap by 50 px so nothing hides on a seam

BROWSER_CANDIDATES = [
    r"C:\Program Files\Google\Chrome\Application\chrome.exe",
    r"C:\Program Files (x86)\Google\Chrome\Application\chrome.exe",
    r"C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe",
    r"C:\Program Files\Microsoft\Edge\Application\msedge.exe",
    "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome",
    "/Applications/Microsoft Edge.app/Contents/MacOS/Microsoft Edge",
    "/Applications/Chromium.app/Contents/MacOS/Chromium",
    "google-chrome", "google-chrome-stable", "chromium", "chromium-browser", "microsoft-edge", "msedge", "chrome",
]


def find_browser():
    if os.environ.get("CHROME_PATH"):
        return os.environ["CHROME_PATH"]
    for candidate in BROWSER_CANDIDATES:
        if found := shutil.which(candidate):
            return found
    return None


def main():
    if len(sys.argv) != 3:
        sys.exit("usage: preview.py <file.svg> <output-dir>")
    browser = find_browser()
    if browser is None:
        print("no Chrome, Edge or Chromium found; set CHROME_PATH", file=sys.stderr)
        sys.exit(2)
    svg = Path(sys.argv[1]).read_text(encoding="utf-8")
    out_dir = Path(sys.argv[2]).resolve()
    out_dir.mkdir(parents=True, exist_ok=True)
    match = re.search(r'<svg [^>]*width="(\d+)" height="(\d+)"', svg)
    width, height = int(match.group(1)), int(match.group(2))
    for i, top in enumerate(range(0, height - (SEGMENT_H - STEP), STEP)):
        segment = re.sub(r"<svg [^>]*>",
                         f'<svg xmlns="http://www.w3.org/2000/svg" width="{width}" height="{SEGMENT_H}" '
                         f'viewBox="0 {top} {width} {SEGMENT_H}">', svg, count=1)
        segment_svg = out_dir / f"seg-{i}.svg"
        segment_png = out_dir / f"seg-{i}.png"
        segment_svg.write_text(segment, encoding="utf-8")
        subprocess.run([browser, "--headless", "--disable-gpu",
                        f"--window-size={width},{SEGMENT_H}", f"--screenshot={segment_png}", segment_svg.as_uri()],
                       check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, timeout=60)
        print(segment_png)


if __name__ == "__main__":
    main()
