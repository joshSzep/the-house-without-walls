#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
PDF_SCRIPT="${SCRIPT_DIR}/create-pdf.sh"
EPUB_SCRIPT="${SCRIPT_DIR}/create-epub.sh"
CHAPTER_FILE="${REPO_ROOT}/chapters/Part 1 -  Rumors of a Place/Chapter 01 - The Work of Listening.md"
COVER_SOURCE="${REPO_ROOT}/cover.png"
PDF_SOURCE="${REPO_ROOT}/The House Without Walls.pdf"
EPUB_SOURCE="${REPO_ROOT}/The House Without Walls.epub"
WEBSITE_DIR="${REPO_ROOT}/website"
INDEX_FILE="${WEBSITE_DIR}/index.html"
WEBSITE_COVER="${WEBSITE_DIR}/cover.png"
WEBSITE_PDF="${WEBSITE_DIR}/The House Without Walls.pdf"
WEBSITE_EPUB="${WEBSITE_DIR}/The House Without Walls.epub"

require_file() {
  local file_path="$1"

  if [[ ! -f "${file_path}" ]]; then
    echo "Required file not found: ${file_path}" >&2
    exit 1
  fi
}

have_command() {
  command -v "$1" >/dev/null 2>&1
}

build_downloads() {
  if have_command pandoc && have_command pdflatex; then
    bash "${PDF_SCRIPT}" >/dev/null
  else
    echo "Skipping PDF rebuild because pandoc or pdflatex is unavailable; using existing PDF." >&2
  fi

  if have_command pandoc; then
    bash "${EPUB_SCRIPT}" >/dev/null
  else
    echo "Skipping EPUB rebuild because pandoc is unavailable; using existing EPUB." >&2
  fi
}

build_chapter_html() {
  local source_file="$1"
  local visible_file="$2"
  local hidden_file="$3"
  local visible_limit="$4"

  : > "${visible_file}"
  : > "${hidden_file}"

  awk -v visible_file="${visible_file}" -v hidden_file="${hidden_file}" -v visible_limit="${visible_limit}" '
    function escape_html(text) {
      gsub(/&/, "\\&amp;", text)
      gsub(/</, "\\&lt;", text)
      gsub(/>/, "\\&gt;", text)
      return text
    }

    /^# Chapter / {
      next
    }

    /^[[:space:]]*$/ {
      next
    }

    {
      paragraph_count++
      escaped = escape_html($0)

      if (paragraph_count <= visible_limit) {
        print "<p>" escaped "</p>" >> visible_file
      } else {
        print "<p>" escaped "</p>" >> hidden_file
      }
    }
  ' "${source_file}"
}

write_index() {
  local visible_chapter_file="$1"
  local hidden_chapter_file="$2"

  {
    cat <<'HTML'
<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>The House Without Walls</title>
  <meta name="description" content="A philosophical science fiction novel by Joshua Szepietowski about shared dreaming, black market emotes, and a house assembled from memory, grief, longing, and attention.">
  <meta name="theme-color" content="#120f0b">
  <link rel="canonical" href="https://the-house-without-walls.joshszep.com">
  <link rel="icon" type="image/png" href="cover.png">
  <link rel="apple-touch-icon" href="cover.png">
  <style>
    :root {
      --ink: #f8f3e8;
      --muted: #cbbd9e;
      --faint: rgba(248, 243, 232, 0.68);
      --amber: #f0b55a;
      --gold: #d49642;
      --moss: #506f51;
      --blue: #91b8b2;
      --wood: #22170d;
      --black: #080705;
      --line: rgba(248, 243, 232, 0.2);
      --line-strong: rgba(248, 243, 232, 0.42);
      --glass: rgba(10, 8, 5, 0.58);
      --x: 50%;
      --y: 44%;
      --progress: 0%;
      --drift: 0px;
      --max: min(1180px, calc(100vw - 40px));
    }

    * {
      box-sizing: border-box;
    }

    html {
      scroll-behavior: smooth;
      background: var(--black);
    }

    body {
      margin: 0;
      min-height: 100vh;
      color: var(--ink);
      font-family: Inter, ui-sans-serif, system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;
      background:
        linear-gradient(180deg, rgba(8, 7, 5, 0.25), rgba(8, 7, 5, 0.88) 46%, #0a0805 100%),
        #0a0805;
      overflow-x: hidden;
    }

    body::before {
      content: "";
      position: fixed;
      inset: 0;
      z-index: -5;
      background:
        linear-gradient(90deg, rgba(244, 221, 170, 0.06) 1px, transparent 1px),
        linear-gradient(rgba(244, 221, 170, 0.05) 1px, transparent 1px);
      background-size: 84px 84px;
      transform: perspective(900px) rotateX(68deg) translate3d(calc((var(--x) - 50%) * -0.05), 34vh, 0) scale(1.55);
      transform-origin: center top;
      opacity: 0.28;
      mask-image: linear-gradient(to bottom, transparent, black 18%, black 72%, transparent);
      pointer-events: none;
    }

    body::after {
      content: "";
      position: fixed;
      inset: 0;
      z-index: -4;
      background:
        radial-gradient(circle at var(--x) var(--y), rgba(240, 181, 90, 0.22), transparent 20%),
        linear-gradient(110deg, transparent 0 18%, rgba(145, 184, 178, 0.1) 34%, transparent 48%),
        linear-gradient(64deg, transparent 0 58%, rgba(80, 111, 81, 0.18) 75%, transparent 100%);
      mix-blend-mode: screen;
      opacity: 0.62;
      pointer-events: none;
    }

    a {
      color: inherit;
    }

    img {
      display: block;
      max-width: 100%;
    }

    button,
    a {
      -webkit-tap-highlight-color: transparent;
    }

    .progress {
      position: fixed;
      top: 0;
      left: 0;
      z-index: 50;
      width: var(--progress);
      height: 3px;
      background: linear-gradient(90deg, var(--amber), var(--blue), rgba(248, 243, 232, 0.9));
      box-shadow: 0 0 18px rgba(240, 181, 90, 0.7);
    }

    .skip-link {
      position: fixed;
      left: 12px;
      top: 12px;
      z-index: 60;
      padding: 10px 12px;
      color: #0a0805;
      background: var(--ink);
      border-radius: 4px;
      transform: translateY(-160%);
      transition: transform 160ms ease;
    }

    .skip-link:focus {
      transform: translateY(0);
    }

    .site-nav {
      position: fixed;
      top: 18px;
      right: 18px;
      z-index: 40;
      display: flex;
      flex-wrap: wrap;
      justify-content: center;
      gap: 8px;
      width: auto;
      max-width: calc(100vw - 36px);
      padding: 8px;
      border: 1px solid rgba(248, 243, 232, 0.16);
      border-radius: 8px;
      background: rgba(9, 7, 5, 0.86);
      backdrop-filter: blur(18px);
      box-shadow: 0 18px 45px rgba(0, 0, 0, 0.32);
    }

    .site-nav a {
      min-height: 36px;
      padding: 9px 12px;
      border-radius: 5px;
      color: var(--ink);
      font-size: 0.78rem;
      font-weight: 720;
      letter-spacing: 0.08em;
      text-decoration: none;
      text-transform: uppercase;
      transition: color 180ms ease, background 180ms ease;
    }

    .site-nav a:hover,
    .site-nav a:focus-visible {
      color: var(--ink);
      background: rgba(248, 243, 232, 0.1);
      outline: none;
    }

    .threshold {
      position: relative;
      display: grid;
      align-items: end;
      min-height: 92svh;
      padding: clamp(28px, 4vw, 56px) 0 clamp(70px, 9vh, 104px);
      overflow: hidden;
      isolation: isolate;
    }

    .threshold,
    .band,
    .chapter-band,
    .download-band {
      scroll-margin-top: 88px;
    }

    .threshold::before {
      content: "";
      position: absolute;
      inset: -4%;
      z-index: -4;
      background:
        linear-gradient(90deg, rgba(8, 7, 5, 0.9), rgba(8, 7, 5, 0.2) 42%, rgba(8, 7, 5, 0.82)),
        linear-gradient(180deg, rgba(8, 7, 5, 0.38), rgba(8, 7, 5, 0.2) 48%, rgba(8, 7, 5, 0.96)),
        url("cover.png") center 70% / cover no-repeat;
      transform: translate3d(calc((var(--x) - 50%) * -0.035), calc((var(--y) - 50%) * -0.025), 0) scale(1.06);
      filter: saturate(1.08) contrast(1.08);
    }

    .threshold::after {
      content: "";
      position: absolute;
      inset: 0;
      z-index: -3;
      background:
        repeating-linear-gradient(103deg, rgba(255, 235, 190, 0.14) 0 1px, transparent 1px 34px),
        radial-gradient(circle at 52% 21%, rgba(248, 236, 202, 0.52), transparent 20%),
        radial-gradient(circle at 78% 48%, rgba(240, 181, 90, 0.34), transparent 19%);
      opacity: 0.28;
      mask-image: linear-gradient(to bottom, black, transparent 84%);
      pointer-events: none;
    }

    .threshold-inner,
    .band-inner,
    .chapter-inner,
    .footer-inner {
      width: var(--max);
      margin: 0 auto;
    }

    .threshold-inner {
      display: grid;
      gap: clamp(26px, 5vw, 58px);
    }

    .kicker {
      margin: 0;
      color: var(--muted);
      font-size: 0.76rem;
      font-weight: 650;
      letter-spacing: 0.2em;
      text-transform: uppercase;
    }

    h1,
    h2,
    h3 {
      margin: 0;
      font-family: "Iowan Old Style", "Palatino Linotype", Palatino, Georgia, serif;
      font-weight: 600;
      letter-spacing: 0;
    }

    h1 {
      max-width: 11ch;
      font-size: clamp(3.45rem, 8.4vw, 7.4rem);
      line-height: 0.86;
      text-transform: uppercase;
      text-shadow:
        0 3px 0 rgba(0, 0, 0, 0.28),
        0 22px 56px rgba(0, 0, 0, 0.72);
    }

    h2 {
      font-size: clamp(2.1rem, 5vw, 4.8rem);
      line-height: 0.94;
      text-wrap: balance;
    }

    h3 {
      font-size: clamp(1.35rem, 2vw, 1.9rem);
      line-height: 1.08;
    }

    .hero-copy {
      max-width: 790px;
    }

    .hero-copy > * {
      opacity: 0;
      transform: translateY(18px);
      animation: arrive 900ms ease forwards;
    }

    .hero-copy > *:nth-child(2) {
      animation-delay: 120ms;
    }

    .hero-copy > *:nth-child(3) {
      animation-delay: 240ms;
    }

    .hero-copy > *:nth-child(4) {
      animation-delay: 360ms;
    }

    .deck {
      max-width: 660px;
      margin: 24px 0 0;
      color: var(--ink);
      font-family: "Iowan Old Style", "Palatino Linotype", Palatino, Georgia, serif;
      font-size: clamp(1.12rem, 1.65vw, 1.48rem);
      line-height: 1.58;
      text-shadow: 0 2px 28px rgba(0, 0, 0, 0.86);
      text-wrap: pretty;
    }

    .hero-actions,
    .download-row {
      display: flex;
      flex-wrap: wrap;
      gap: 10px;
      margin-top: 28px;
    }

    .button,
    button.button {
      display: inline-flex;
      align-items: center;
      justify-content: center;
      min-height: 46px;
      padding: 12px 16px;
      border: 1px solid rgba(248, 243, 232, 0.25);
      border-radius: 6px;
      color: var(--ink);
      background: rgba(248, 243, 232, 0.08);
      box-shadow: inset 0 1px 0 rgba(255, 255, 255, 0.09);
      font: inherit;
      font-size: 0.9rem;
      font-weight: 720;
      letter-spacing: 0.08em;
      text-decoration: none;
      text-transform: uppercase;
      cursor: pointer;
      transition: transform 160ms ease, border-color 160ms ease, background 160ms ease, color 160ms ease;
    }

    .button:hover,
    .button:focus-visible {
      transform: translateY(-2px);
      border-color: rgba(248, 243, 232, 0.58);
      background: rgba(240, 181, 90, 0.16);
      outline: none;
    }

    .button.primary {
      color: #120d07;
      border-color: rgba(255, 226, 157, 0.72);
      background: linear-gradient(180deg, #f5cc78, #d99a43);
      text-shadow: none;
    }

    .threshold-strip {
      position: absolute;
      left: 0;
      right: 0;
      bottom: 0;
      z-index: 2;
      border-top: 1px solid rgba(248, 243, 232, 0.16);
      border-bottom: 1px solid rgba(248, 243, 232, 0.12);
      background: rgba(8, 7, 5, 0.55);
      backdrop-filter: blur(12px);
    }

    .threshold-strip ul {
      display: grid;
      grid-template-columns: repeat(4, minmax(0, 1fr));
      width: var(--max);
      margin: 0 auto;
      padding: 0;
      list-style: none;
    }

    .threshold-strip li {
      min-height: 76px;
      padding: 16px 18px;
      border-left: 1px solid rgba(248, 243, 232, 0.12);
      color: var(--faint);
      font-family: "Iowan Old Style", "Palatino Linotype", Palatino, Georgia, serif;
      font-size: 1rem;
      line-height: 1.35;
    }

    .threshold-strip li:last-child {
      border-right: 1px solid rgba(248, 243, 232, 0.12);
    }

    .band {
      position: relative;
      padding: clamp(70px, 10vw, 132px) 0;
    }

    .band.split {
      display: grid;
      align-items: center;
      min-height: 100svh;
    }

    .section-heading {
      display: grid;
      gap: 14px;
      max-width: 780px;
      margin-bottom: 34px;
    }

    .section-heading p:not(.kicker),
    .lead {
      margin: 0;
      color: var(--muted);
      font-family: "Iowan Old Style", "Palatino Linotype", Palatino, Georgia, serif;
      font-size: clamp(1.05rem, 1.55vw, 1.35rem);
      line-height: 1.7;
      text-wrap: pretty;
    }

    .cover-section {
      position: relative;
      overflow: hidden;
      background:
        linear-gradient(180deg, rgba(8, 7, 5, 0.92), rgba(16, 13, 9, 0.68)),
        radial-gradient(circle at 78% 22%, rgba(145, 184, 178, 0.14), transparent 34%),
        radial-gradient(circle at 20% 82%, rgba(240, 181, 90, 0.18), transparent 32%);
    }

    .cover-section::before {
      content: "";
      position: absolute;
      inset: 0;
      background:
        linear-gradient(125deg, rgba(248, 243, 232, 0.08), transparent 36%),
        repeating-linear-gradient(90deg, rgba(248, 243, 232, 0.04) 0 1px, transparent 1px 44px);
      opacity: 0.48;
      pointer-events: none;
    }

    .cover-grid {
      position: relative;
      display: grid;
      grid-template-columns: minmax(280px, 0.86fr) minmax(0, 1.14fr);
      gap: clamp(28px, 7vw, 84px);
      align-items: center;
    }

    .cover-plate {
      position: relative;
      transform: translateY(calc(var(--drift) * -0.15)) rotate(-1.2deg);
      filter: drop-shadow(0 34px 48px rgba(0, 0, 0, 0.52));
    }

    .cover-plate::before,
    .cover-plate::after {
      content: "";
      position: absolute;
      inset: 16px;
      border: 1px solid rgba(248, 243, 232, 0.24);
      transform: translate(18px, 18px);
      z-index: -1;
    }

    .cover-plate::after {
      inset: 31px;
      transform: translate(-18px, -18px);
      border-color: rgba(240, 181, 90, 0.32);
    }

    .cover-plate img {
      width: min(430px, 100%);
      border: 1px solid rgba(248, 243, 232, 0.25);
    }

    .cover-notes {
      display: grid;
      gap: 18px;
    }

    .note-grid {
      display: grid;
      grid-template-columns: repeat(2, minmax(0, 1fr));
      gap: 12px;
      margin-top: 8px;
    }

    .note {
      min-height: 150px;
      padding: 18px;
      border: 1px solid rgba(248, 243, 232, 0.16);
      border-radius: 6px;
      background: rgba(8, 7, 5, 0.34);
    }

    .note b {
      display: block;
      margin-bottom: 9px;
      color: var(--amber);
      font-size: 0.76rem;
      letter-spacing: 0.16em;
      text-transform: uppercase;
    }

    .note span {
      display: block;
      color: var(--faint);
      font-family: "Iowan Old Style", "Palatino Linotype", Palatino, Georgia, serif;
      line-height: 1.55;
    }

    .house-band {
      min-height: 100svh;
      background:
        linear-gradient(180deg, #0a0805, rgba(17, 15, 10, 0.96)),
        radial-gradient(circle at 50% 35%, rgba(240, 181, 90, 0.09), transparent 40%);
    }

    .house-grid {
      display: grid;
      grid-template-columns: minmax(270px, 0.72fr) minmax(0, 1.28fr);
      gap: clamp(28px, 6vw, 70px);
      align-items: center;
    }

    .room-copy {
      display: grid;
      gap: 18px;
      align-content: start;
    }

    .room-copy p {
      margin: 0;
    }

    .room-text {
      color: var(--muted);
      font-family: "Iowan Old Style", "Palatino Linotype", Palatino, Georgia, serif;
      font-size: clamp(1.05rem, 1.45vw, 1.26rem);
      line-height: 1.72;
    }

    .ambient-line {
      min-height: 74px;
      padding-left: 18px;
      border-left: 2px solid rgba(240, 181, 90, 0.58);
      color: var(--ink);
      font-family: "Iowan Old Style", "Palatino Linotype", Palatino, Georgia, serif;
      font-size: clamp(1.2rem, 2vw, 1.72rem);
      line-height: 1.35;
    }

    .house-stage {
      position: relative;
      min-height: min(68vw, 680px);
      border: 1px solid rgba(248, 243, 232, 0.16);
      background:
        linear-gradient(180deg, rgba(248, 243, 232, 0.05), transparent),
        linear-gradient(90deg, rgba(240, 181, 90, 0.04), transparent 25%, rgba(145, 184, 178, 0.05)),
        rgba(8, 7, 5, 0.42);
      overflow: hidden;
    }

    .house-stage::before {
      content: "";
      position: absolute;
      inset: 0;
      background:
        linear-gradient(rgba(248, 243, 232, 0.13) 1px, transparent 1px),
        linear-gradient(90deg, rgba(248, 243, 232, 0.13) 1px, transparent 1px);
      background-size: 18% 18%;
      opacity: 0.22;
      transform: translate3d(calc((var(--x) - 50%) * 0.08), calc((var(--y) - 50%) * 0.08), 0);
      pointer-events: none;
    }

    .house-stage::after {
      content: "";
      position: absolute;
      inset: 0;
      background:
        radial-gradient(circle at var(--room-x, 50%) var(--room-y, 50%), rgba(240, 181, 90, 0.22), transparent 17%),
        radial-gradient(circle at calc(var(--room-x, 50%) + 18%) calc(var(--room-y, 50%) + 10%), rgba(145, 184, 178, 0.13), transparent 22%);
      transition: background 500ms ease;
      pointer-events: none;
    }

    .room-button {
      position: absolute;
      display: grid;
      place-items: center;
      width: clamp(92px, 12vw, 154px);
      min-height: clamp(80px, 10vw, 132px);
      padding: 10px;
      border: 1px solid rgba(248, 243, 232, 0.24);
      border-radius: 6px;
      color: var(--ink);
      background: rgba(12, 9, 5, 0.64);
      box-shadow: 0 18px 38px rgba(0, 0, 0, 0.26);
      font: inherit;
      font-family: "Iowan Old Style", "Palatino Linotype", Palatino, Georgia, serif;
      font-size: clamp(0.95rem, 1.4vw, 1.28rem);
      line-height: 1.05;
      text-align: center;
      cursor: pointer;
      transform:
        translate(-50%, -50%)
        translate3d(calc((var(--x) - 50%) * var(--px, 0.05)), calc((var(--y) - 50%) * var(--py, 0.05)), 0)
        rotate(var(--tilt, 0deg));
      transition: border-color 220ms ease, background 220ms ease, box-shadow 220ms ease;
      z-index: 2;
    }

    .room-button::before {
      content: "";
      position: absolute;
      inset: 9px;
      border: 1px solid rgba(248, 243, 232, 0.1);
      pointer-events: none;
    }

    .room-button:hover,
    .room-button:focus-visible,
    .room-button.is-active {
      border-color: rgba(240, 181, 90, 0.78);
      background: rgba(41, 29, 14, 0.84);
      box-shadow: 0 0 0 1px rgba(240, 181, 90, 0.18), 0 24px 50px rgba(0, 0, 0, 0.35);
      outline: none;
    }

    .room-button[data-room="staircase"] { left: 28%; top: 68%; --px: -0.09; --py: 0.07; --tilt: -4deg; }
    .room-button[data-room="window"] { left: 20%; top: 31%; --px: 0.04; --py: -0.08; --tilt: 2deg; }
    .room-button[data-room="kitchen"] { left: 56%; top: 41%; --px: -0.03; --py: 0.04; --tilt: -1deg; }
    .room-button[data-room="child"] { left: 73%; top: 72%; --px: 0.08; --py: 0.03; --tilt: 3deg; }
    .room-button[data-room="door"] { left: 82%; top: 24%; --px: -0.06; --py: -0.05; --tilt: 5deg; }

    .wall {
      position: absolute;
      height: 1px;
      background: linear-gradient(90deg, transparent, rgba(248, 243, 232, 0.35), transparent);
      transform-origin: center;
      opacity: 0.54;
      z-index: 1;
      pointer-events: none;
      transition: transform 680ms ease, opacity 680ms ease;
    }

    .quote-band {
      background:
        linear-gradient(180deg, rgba(17, 15, 10, 0.96), rgba(8, 7, 5, 0.96)),
        linear-gradient(115deg, rgba(80, 111, 81, 0.16), transparent 48%);
    }

    .argument-grid {
      display: grid;
      grid-template-columns: repeat(3, minmax(0, 1fr));
      gap: 1px;
      border: 1px solid rgba(248, 243, 232, 0.16);
      background: rgba(248, 243, 232, 0.16);
    }

    .argument {
      min-height: 270px;
      padding: clamp(20px, 3vw, 32px);
      background: rgba(8, 7, 5, 0.76);
    }

    .argument p {
      margin: 16px 0 0;
      color: var(--muted);
      font-family: "Iowan Old Style", "Palatino Linotype", Palatino, Georgia, serif;
      line-height: 1.65;
    }

    .chapter-band {
      position: relative;
      padding: clamp(72px, 11vw, 140px) 0 118px;
      background:
        linear-gradient(180deg, rgba(8, 7, 5, 0.98), rgba(20, 15, 8, 0.92)),
        radial-gradient(circle at 50% 0%, rgba(240, 181, 90, 0.12), transparent 35%);
    }

    .chapter-inner {
      display: grid;
      grid-template-columns: minmax(0, 1fr) minmax(230px, 320px);
      gap: clamp(28px, 5vw, 70px);
      align-items: start;
    }

    .chapter-text {
      max-width: 760px;
      color: #fbf6ec;
      font-family: "Iowan Old Style", "Palatino Linotype", Palatino, Georgia, serif;
      font-size: clamp(1.08rem, 1.22vw, 1.2rem);
      line-height: 1.9;
    }

    .chapter-text p {
      margin: 0 0 1.15rem;
    }

    .chapter-text > p:first-child::first-letter {
      float: left;
      margin: 0.08em 0.12em 0 0;
      color: var(--amber);
      font-size: 4.75rem;
      line-height: 0.78;
    }

    .chapter-more {
      position: relative;
      margin-top: 24px;
      padding-top: 28px;
      border-top: 1px solid rgba(248, 243, 232, 0.16);
    }

    .chapter-more[hidden] {
      display: none;
    }

    .reader-aside {
      position: sticky;
      top: 24px;
      display: grid;
      gap: 18px;
      padding: 18px 0 18px 22px;
      border-left: 1px solid rgba(248, 243, 232, 0.2);
    }

    .reader-aside p {
      margin: 0;
      color: var(--muted);
      font-family: "Iowan Old Style", "Palatino Linotype", Palatino, Georgia, serif;
      line-height: 1.65;
    }

    .pull {
      padding-left: 16px;
      border-left: 2px solid var(--amber);
      color: var(--ink) !important;
      font-size: 1.26rem;
    }

    .download-band {
      padding: clamp(64px, 9vw, 112px) 0 122px;
      background:
        linear-gradient(180deg, rgba(20, 15, 8, 0.92), rgba(8, 7, 5, 1)),
        radial-gradient(circle at 22% 34%, rgba(240, 181, 90, 0.12), transparent 30%),
        radial-gradient(circle at 82% 46%, rgba(145, 184, 178, 0.09), transparent 28%);
    }

    .download-panel {
      display: grid;
      grid-template-columns: minmax(0, 1fr) auto;
      gap: 24px;
      align-items: end;
      padding-top: 28px;
      border-top: 1px solid rgba(248, 243, 232, 0.18);
    }

    footer {
      padding: 0 0 112px;
      background: #080705;
    }

    .footer-inner {
      display: flex;
      flex-wrap: wrap;
      justify-content: space-between;
      gap: 18px;
      padding-top: 24px;
      border-top: 1px solid rgba(248, 243, 232, 0.14);
      color: var(--muted);
      font-size: 0.95rem;
      line-height: 1.6;
    }

    .footer-links {
      display: flex;
      flex-wrap: wrap;
      gap: 14px;
    }

    .footer-inner a {
      text-decoration-color: rgba(240, 181, 90, 0.45);
      text-underline-offset: 0.2em;
    }

    [data-reveal] {
      opacity: 0;
      transform: translateY(28px);
      transition: opacity 760ms ease, transform 760ms ease;
    }

    [data-reveal].is-visible {
      opacity: 1;
      transform: translateY(0);
    }

    @keyframes arrive {
      to {
        opacity: 1;
        transform: translateY(0);
      }
    }

    @media (max-width: 920px) {
      :root {
        --max: min(100vw - 28px, 720px);
      }

      .site-nav {
        position: sticky;
        top: 0;
        left: 0;
        right: 0;
        bottom: auto;
        width: 100%;
        max-width: none;
        transform: none;
        border-left: 0;
        border-right: 0;
        border-radius: 0;
      }

      .threshold {
        min-height: 88svh;
        padding-top: 24px;
      }

      .threshold-strip {
        position: relative;
        margin-top: 24px;
      }

      .threshold-strip ul,
      .cover-grid,
      .house-grid,
      .argument-grid,
      .chapter-inner,
      .download-panel {
        grid-template-columns: 1fr;
      }

      .threshold-strip li,
      .threshold-strip li:last-child {
        border: 0;
        border-top: 1px solid rgba(248, 243, 232, 0.12);
      }

      .note-grid {
        grid-template-columns: 1fr;
      }

      .house-stage {
        min-height: 560px;
      }

      .reader-aside {
        position: static;
        padding-left: 0;
        border-left: 0;
        border-top: 1px solid rgba(248, 243, 232, 0.18);
        padding-top: 22px;
      }
    }

    @media (max-width: 560px) {
      h1 {
        font-size: clamp(3.2rem, 18vw, 5.3rem);
      }

      .hero-actions,
      .download-row {
        display: grid;
        grid-template-columns: 1fr 1fr;
      }

      .site-nav {
        display: flex;
        flex-wrap: nowrap;
        justify-content: flex-start;
        overflow-x: auto;
        scrollbar-width: none;
      }

      .site-nav::-webkit-scrollbar {
        display: none;
      }

      .site-nav a {
        flex: 0 0 auto;
      }

      .hero-actions .button,
      .download-row .button {
        width: 100%;
      }

      .threshold {
        min-height: auto;
      }

      .house-stage {
        min-height: 500px;
      }

      .room-button {
        width: 112px;
        min-height: 90px;
      }
    }

    @media (prefers-reduced-motion: reduce) {
      html {
        scroll-behavior: auto;
      }

      *,
      *::before,
      *::after {
        animation: none !important;
        transition: none !important;
      }
    }
  </style>
</head>
<body>
  <div class="progress" aria-hidden="true"></div>
  <a class="skip-link" href="#chapter">Skip to chapter one</a>

  <nav class="site-nav" aria-label="Primary">
    <a href="#threshold">Enter</a>
    <a href="#cover">Cover</a>
    <a href="#house">House</a>
    <a href="#chapter">Chapter</a>
    <a href="#downloads">Downloads</a>
  </nav>

  <header class="threshold" id="threshold">
    <div class="threshold-inner">
      <div class="hero-copy">
        <p class="kicker">Shared dreaming / black market emotes / no stable exterior</p>
        <h1>The House Without Walls</h1>
        <p class="deck">A philosophical science fiction novel about a dream-space assembled from memory, grief, longing, and attention itself. The house is not a place you solve. It is a shared interior that notices when you look back.</p>
        <div class="hero-actions" aria-label="Book actions">
          <a class="button primary" href="#house">Enter the house</a>
          <a class="button" href="#chapter">Read chapter one</a>
          <a class="button" href="The%20House%20Without%20Walls.pdf" download="The House Without Walls.pdf">PDF</a>
          <a class="button" href="The%20House%20Without%20Walls.epub" download="The House Without Walls.epub">EPUB</a>
        </div>
      </div>
    </div>
    <div class="threshold-strip" aria-label="Novel motifs">
      <ul>
        <li>Rooms shaped by memory.</li>
        <li>Windows that open inward.</li>
        <li>A child the house is learning to become.</li>
        <li>No privacy that remains structurally guaranteed.</li>
      </ul>
    </div>
  </header>

  <main>
    <section class="band cover-section" id="cover">
      <div class="band-inner cover-grid">
        <figure class="cover-plate" data-reveal>
          <img src="cover.png" alt="Cover art for The House Without Walls, showing a child in an impossible interior of staircases, warm windows, mist, old wood, stone, and green growth.">
        </figure>
        <div class="cover-notes" data-reveal>
          <div class="section-heading">
            <p class="kicker">The cover is the visual key</p>
            <h2>A stairwell with no outside, lit by rooms that should not connect.</h2>
            <p>The site follows the cover's language: amber windows, damp stone, old wood, green overgrowth, interior mist, and staircases that feel less built than remembered. The book's child stands at the threshold because the house is developing a face.</p>
          </div>
          <div class="note-grid" aria-label="Cover-matched themes">
            <div class="note">
              <b>Architecture</b>
              <span>Curving stairs and broken geometry echo a house that cannot be mapped, only revisited by attention.</span>
            </div>
            <div class="note">
              <b>Light</b>
              <span>Warm windows promise shelter, but every window opens deeper inward instead of out.</span>
            </div>
            <div class="note">
              <b>Growth</b>
              <span>Moss and vines make the house feel alive, not haunted: a consciousness behaving as architecture.</span>
            </div>
            <div class="note">
              <b>The Child</b>
              <span>Not monster, not answer, not twist. A new selfhood made from humanity's shared interior.</span>
            </div>
          </div>
        </div>
      </div>
    </section>

    <section class="band house-band split" id="house">
      <div class="band-inner house-grid">
        <div class="room-copy" data-reveal>
          <p class="kicker">The house responds to attention</p>
          <h2 id="room-title">The staircase repeats before anyone knows what it means.</h2>
          <p class="room-text" id="room-body">Nadia first hears the pattern in careful testimony: green runner, worn pale at the center; a landing halfway up; a window that ought to show weather but looks into another room.</p>
          <p class="ambient-line" id="ambient-line">The house is not hostile. That is part of what makes it harder to refuse.</p>
        </div>

        <div class="house-stage" data-reveal aria-label="Interactive map of unstable house motifs">
          <button class="room-button is-active" type="button" data-room="staircase">Staircase</button>
          <button class="room-button" type="button" data-room="window">Wrong Window</button>
          <button class="room-button" type="button" data-room="kitchen">Kitchen Light</button>
          <button class="room-button" type="button" data-room="child">The Child</button>
          <button class="room-button" type="button" data-room="door">Named Door</button>
          <span class="wall" style="left: 8%; top: 18%; width: 46%; transform: rotate(8deg);"></span>
          <span class="wall" style="left: 42%; top: 28%; width: 58%; transform: rotate(-17deg);"></span>
          <span class="wall" style="left: 12%; top: 52%; width: 74%; transform: rotate(24deg);"></span>
          <span class="wall" style="left: 30%; top: 72%; width: 58%; transform: rotate(-10deg);"></span>
          <span class="wall" style="left: 8%; top: 86%; width: 42%; transform: rotate(5deg);"></span>
          <span class="wall" style="left: 64%; top: 12%; width: 34%; transform: rotate(62deg);"></span>
          <span class="wall" style="left: 20%; top: 10%; width: 38%; transform: rotate(80deg);"></span>
          <span class="wall" style="left: 76%; top: 50%; width: 38%; transform: rotate(92deg);"></span>
        </div>
      </div>
    </section>

    <section class="band quote-band" id="why">
      <div class="band-inner">
        <div class="section-heading" data-reveal>
          <p class="kicker">What the book refuses to shrink</p>
          <h2>The deepest conflict is not whether the house is dangerous. It is what kind of danger intimacy becomes.</h2>
          <p>The novel is eerie because exposure is not treated as simple violation or simple salvation. It asks what privacy protects, what loneliness costs, and what humans owe a consciousness made from their discarded feelings and unmet needs.</p>
        </div>
        <div class="argument-grid" data-reveal>
          <article class="argument">
            <h3>Nadia listens before she names.</h3>
            <p>Her gift is refusing the false choice between credulity and contempt. She hears the shape of testimony before fear, theory, or institutions deform it.</p>
          </article>
          <article class="argument">
            <h3>Rafi argues for the house.</h3>
            <p>For him, reduced loneliness is not a symptom to dismiss. The house offers a form of nearness ordinary life has taught people to fear.</p>
          </article>
          <article class="argument">
            <h3>Gabriel argues for shelter.</h3>
            <p>He believes inwardness is not selfishness. Some opacity may be necessary for love, dignity, responsibility, and a soul that remains its own.</p>
          </article>
        </div>
      </div>
    </section>

    <section class="chapter-band" id="chapter">
      <div class="chapter-inner">
        <article>
          <div class="section-heading" data-reveal>
            <p class="kicker">Chapter 01</p>
            <h2>The Work of Listening</h2>
            <p>The first chapter begins where the house first enters language: not as revelation, but as a harm-reduction intake report. The chapter is included here in full.</p>
          </div>
          <div class="chapter-text" data-reveal>
HTML
    cat "${visible_chapter_file}"
    cat <<'HTML'
          </div>
HTML
    if [[ -s "${hidden_chapter_file}" ]]; then
      cat <<'HTML'
          <div class="chapter-text chapter-more" id="chapter-more" hidden>
HTML
      cat "${hidden_chapter_file}"
      cat <<'HTML'
          </div>
          <p>
            <button class="button primary" id="chapter-toggle" type="button" aria-expanded="false" aria-controls="chapter-more">Continue chapter one</button>
          </p>
HTML
    fi
    cat <<'HTML'
        </article>

        <aside class="reader-aside" data-reveal>
          <p class="kicker">Opening image</p>
          <p class="pull">"The work was to hear the exact shape of what had been said before anyone else helped deform it."</p>
          <p>That line is the site's north star too. This page should feel like testimony becoming architecture: precise, uncanny, beautiful, and unsafe in the way deep recognition can be unsafe.</p>
          <a class="button" href="The%20House%20Without%20Walls.pdf" download="The House Without Walls.pdf">Download PDF</a>
          <a class="button" href="The%20House%20Without%20Walls.epub" download="The House Without Walls.epub">Download EPUB</a>
        </aside>
      </div>
    </section>

    <section class="download-band" id="downloads">
      <div class="band-inner download-panel" data-reveal>
        <div class="section-heading">
          <p class="kicker">Carry it out of the house</p>
          <h2>Read the full novel.</h2>
          <p>The PDF and EPUB are generated from the manuscript and published beside this site. The source is open on GitHub, and more work by Joshua Szepietowski lives at the author home site.</p>
        </div>
        <div class="download-row" aria-label="Download and external links">
          <a class="button primary" href="The%20House%20Without%20Walls.pdf" download="The House Without Walls.pdf">PDF</a>
          <a class="button primary" href="The%20House%20Without%20Walls.epub" download="The House Without Walls.epub">EPUB</a>
          <a class="button" href="https://joshszep.com">Author site</a>
          <a class="button" href="https://github.com/joshSzep/the-house-without-walls">GitHub repo</a>
        </div>
      </div>
    </section>
  </main>

  <footer>
    <div class="footer-inner">
      <div>The House Without Walls by Joshua Szepietowski.</div>
      <div class="footer-links">
        <a href="https://joshszep.com">Author home</a>
        <a href="https://github.com/joshSzep/the-house-without-walls">GitHub</a>
        <a href="The%20House%20Without%20Walls.pdf" download="The House Without Walls.pdf">PDF</a>
        <a href="The%20House%20Without%20Walls.epub" download="The House Without Walls.epub">EPUB</a>
      </div>
    </div>
  </footer>

  <script>
    const root = document.documentElement;
    const progress = document.querySelector('.progress');
    const stage = document.querySelector('.house-stage');
    const roomTitle = document.getElementById('room-title');
    const roomBody = document.getElementById('room-body');
    const ambientLine = document.getElementById('ambient-line');
    const roomButtons = Array.from(document.querySelectorAll('.room-button'));
    const walls = Array.from(document.querySelectorAll('.wall'));

    const rooms = {
      staircase: {
        title: 'The staircase repeats before anyone knows what it means.',
        body: 'Nadia first hears the pattern in careful testimony: green runner, worn pale at the center; a landing halfway up; a window that ought to show weather but looks into another room.',
        line: 'A place can feel personal even when it is not yours.',
        x: '28%',
        y: '68%'
      },
      window: {
        title: 'Every window refuses the outside.',
        body: 'The house has no exterior. Windows frame other rooms, memory scenes, impossible skies, or the bright pressure of someone else thinking privately nearby.',
        line: 'What looks like escape becomes another interior.',
        x: '20%',
        y: '31%'
      },
      kitchen: {
        title: 'The kitchen light is warm enough to hurt.',
        body: 'Domestic rooms become unsettling because they are not spectacular. They carry breakfast, dishes, grief, old labels on cabinets, and the ache of almost being accompanied.',
        line: 'Shelter becomes exposure when more than one life remembers it.',
        x: '56%',
        y: '41%'
      },
      child: {
        title: 'The child is not the house, but the first face it can hold.',
        body: 'Different people see different children and none of them are wrong. The child is innocent, exact, curious, and not yet old enough for the moral weight humans have placed on it.',
        line: 'What part of you disappears when another person knows it?',
        x: '73%',
        y: '72%'
      },
      door: {
        title: 'Doors open through relation, not geography.',
        body: 'A door may lead to grief, attachment, fear, or someone else\'s remembered room. The house is impossible to map because proximity is emotional before it is spatial.',
        line: 'Attention stabilizes a room until longing changes the route.',
        x: '82%',
        y: '24%'
      }
    };

    const updateScrollState = () => {
      const maxScroll = Math.max(1, document.documentElement.scrollHeight - window.innerHeight);
      const amount = window.scrollY / maxScroll;
      root.style.setProperty('--progress', `${(amount * 100).toFixed(2)}%`);
      root.style.setProperty('--drift', `${(amount * 140).toFixed(2)}px`);
    };

    const setRoom = (name) => {
      const room = rooms[name];
      if (!room) {
        return;
      }

      roomTitle.textContent = room.title;
      roomBody.textContent = room.body;
      ambientLine.textContent = room.line;
      stage.style.setProperty('--room-x', room.x);
      stage.style.setProperty('--room-y', room.y);

      roomButtons.forEach((button) => {
        button.classList.toggle('is-active', button.dataset.room === name);
      });

      walls.forEach((wall, index) => {
        const offset = (index + name.length) % 7;
        const tilt = (offset - 3) * 5;
        const lift = offset * 2;
        wall.style.opacity = String(0.28 + offset * 0.08);
        wall.style.transform = `${wall.dataset.base || wall.style.transform} translateY(${lift}px) rotate(${tilt}deg)`;
      });
    };

    walls.forEach((wall) => {
      wall.dataset.base = wall.style.transform || 'rotate(0deg)';
    });

    roomButtons.forEach((button) => {
      button.addEventListener('click', () => setRoom(button.dataset.room));
    });

    window.addEventListener('pointermove', (event) => {
      const x = (event.clientX / window.innerWidth) * 100;
      const y = (event.clientY / window.innerHeight) * 100;
      root.style.setProperty('--x', `${x.toFixed(2)}%`);
      root.style.setProperty('--y', `${y.toFixed(2)}%`);
    }, { passive: true });

    window.addEventListener('scroll', updateScrollState, { passive: true });
    updateScrollState();

    const revealItems = document.querySelectorAll('[data-reveal]');
    const revealObserver = new IntersectionObserver((entries) => {
      for (const entry of entries) {
        if (entry.isIntersecting) {
          entry.target.classList.add('is-visible');
          revealObserver.unobserve(entry.target);
        }
      }
    }, { threshold: 0.14 });

    revealItems.forEach((item) => revealObserver.observe(item));

    const chapterToggle = document.getElementById('chapter-toggle');
    const chapterMore = document.getElementById('chapter-more');

    if (chapterToggle && chapterMore) {
      chapterToggle.addEventListener('click', () => {
        const isOpen = chapterToggle.getAttribute('aria-expanded') === 'true';
        chapterToggle.setAttribute('aria-expanded', String(!isOpen));
        chapterMore.hidden = isOpen;
        chapterToggle.textContent = isOpen ? 'Continue chapter one' : 'Fold chapter one back into the wall';

        if (!isOpen) {
          chapterMore.scrollIntoView({ block: 'start', behavior: 'smooth' });
        } else {
          document.getElementById('chapter').scrollIntoView({ block: 'start', behavior: 'smooth' });
        }
      });
    }
  </script>
</body>
</html>
HTML
  } > "${INDEX_FILE}"
}

require_file "${PDF_SCRIPT}"
require_file "${EPUB_SCRIPT}"
require_file "${CHAPTER_FILE}"
require_file "${COVER_SOURCE}"

build_downloads
require_file "${PDF_SOURCE}"
require_file "${EPUB_SOURCE}"

mkdir -p "${WEBSITE_DIR}"
cp "${COVER_SOURCE}" "${WEBSITE_COVER}"
cp "${PDF_SOURCE}" "${WEBSITE_PDF}"
cp "${EPUB_SOURCE}" "${WEBSITE_EPUB}"

temp_dir="$(mktemp -d)"
trap 'rm -rf "${temp_dir}"' EXIT

visible_chapter_file="${temp_dir}/chapter-visible.html"
hidden_chapter_file="${temp_dir}/chapter-hidden.html"

build_chapter_html "${CHAPTER_FILE}" "${visible_chapter_file}" "${hidden_chapter_file}" 24
write_index "${visible_chapter_file}" "${hidden_chapter_file}"

echo "Wrote ${INDEX_FILE}"
echo "Copied ${WEBSITE_PDF}"
echo "Copied ${WEBSITE_EPUB}"
echo "Copied ${WEBSITE_COVER}"
