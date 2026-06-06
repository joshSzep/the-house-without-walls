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

build_excerpt_html() {
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
  local visible_excerpt_file="$1"
  local hidden_excerpt_file="$2"

  {
    cat <<'EOF'
<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>The House Without Walls</title>
  <meta name="description" content="A philosophical science fiction novel by Joshua Szepietowski about shared dreaming, black market emotes, and a house assembled from memory, longing, and the things people thought they had kept private.">
  <meta name="theme-color" content="#0d0a09">
  <link rel="canonical" href="https://the-house-without-walls.joshszep.com">
  <link rel="icon" type="image/png" href="cover.png">
  <link rel="apple-touch-icon" href="cover.png">
  <style>
    :root {
      --paper: #f5eadb;
      --ink: #f4eee7;
      --ink-soft: #cbbda9;
      --line: rgba(241, 224, 203, 0.16);
      --shadow: rgba(0, 0, 0, 0.34);
      --accent: #d88f62;
      --accent-soft: #8ca0ab;
      --well: rgba(18, 12, 10, 0.7);
      --panel: rgba(23, 15, 13, 0.72);
      --panel-strong: rgba(12, 8, 7, 0.82);
      --pointer-x: 50%;
      --pointer-y: 35%;
      --content-width: min(1160px, calc(100vw - 32px));
      --radius: 28px;
    }

    * {
      box-sizing: border-box;
    }

    html {
      scroll-behavior: smooth;
    }

    body {
      margin: 0;
      min-height: 100vh;
      color: var(--ink);
      font-family: "Avenir Next", "Segoe UI", "Trebuchet MS", sans-serif;
      background:
        radial-gradient(circle at var(--pointer-x) var(--pointer-y), rgba(184, 115, 74, 0.16), transparent 22%),
        radial-gradient(circle at 18% 22%, rgba(83, 103, 117, 0.22), transparent 24%),
        radial-gradient(circle at 82% 18%, rgba(216, 143, 98, 0.14), transparent 30%),
        linear-gradient(150deg, #0f0b09 0%, #17110e 38%, #0d0908 100%);
      overflow-x: hidden;
    }

    body::before,
    body::after {
      content: "";
      position: fixed;
      inset: 0;
      pointer-events: none;
      z-index: -2;
    }

    body::before {
      background:
        linear-gradient(rgba(255, 255, 255, 0.03) 1px, transparent 1px),
        linear-gradient(90deg, rgba(255, 255, 255, 0.03) 1px, transparent 1px);
      background-size: 112px 112px;
      mask-image: radial-gradient(circle at center, black 35%, transparent 86%);
      opacity: 0.35;
      transform: perspective(1200px) rotateX(74deg) translateY(26vh) scale(1.6);
      transform-origin: center top;
    }

    body::after {
      background:
        radial-gradient(circle at 22% 26%, rgba(255, 232, 210, 0.06), transparent 16%),
        radial-gradient(circle at 76% 24%, rgba(132, 162, 176, 0.08), transparent 18%),
        radial-gradient(circle at 52% 78%, rgba(216, 143, 98, 0.09), transparent 24%);
      filter: blur(26px);
      animation: breathe 16s ease-in-out infinite alternate;
      opacity: 0.85;
    }

    a {
      color: inherit;
    }

    img {
      display: block;
      max-width: 100%;
    }

    .page {
      width: var(--content-width);
      margin: 0 auto;
      padding-bottom: 72px;
    }

    .hero {
      position: relative;
      display: grid;
      grid-template-columns: minmax(0, 1.1fr) minmax(300px, 0.9fr);
      gap: clamp(24px, 5vw, 64px);
      align-items: center;
      min-height: 100svh;
      padding: clamp(28px, 5vw, 52px) 0 40px;
    }

    .hero-copy,
    .panel,
    .cover-frame {
      opacity: 0;
      transform: translateY(22px);
      transition: opacity 0.9s ease, transform 0.9s ease;
    }

    .is-visible {
      opacity: 1;
      transform: translateY(0);
    }

    .eyebrow {
      margin: 0 0 14px;
      color: var(--ink-soft);
      text-transform: uppercase;
      letter-spacing: 0.24em;
      font-size: 0.75rem;
    }

    .hero-copy {
      position: relative;
      z-index: 1;
    }

    .title-block {
      margin-bottom: 22px;
    }

    h1,
    h2,
    h3 {
      margin: 0;
      font-family: "Baskerville", "Iowan Old Style", "Palatino Linotype", "Book Antiqua", serif;
      font-weight: 600;
      letter-spacing: -0.02em;
    }

    h1 {
      font-size: clamp(3rem, 7vw, 6rem);
      line-height: 0.92;
      max-width: 10ch;
      text-wrap: balance;
    }

    .subtitle {
      display: inline-flex;
      align-items: center;
      gap: 14px;
      margin-top: 18px;
      color: var(--ink-soft);
      font-size: 0.98rem;
      letter-spacing: 0.06em;
      text-transform: uppercase;
    }

    .subtitle::before {
      content: "";
      width: 42px;
      height: 1px;
      background: linear-gradient(90deg, transparent, var(--ink-soft));
    }

    .deck {
      max-width: 38rem;
      margin: 0 0 26px;
      color: var(--paper);
      font-family: "Iowan Old Style", "Palatino Linotype", "Book Antiqua", serif;
      font-size: clamp(1.1rem, 1.5vw, 1.34rem);
      line-height: 1.75;
    }

    .cta-row {
      display: flex;
      flex-wrap: wrap;
      gap: 14px;
      margin-bottom: 28px;
    }

    .button {
      display: inline-flex;
      align-items: center;
      justify-content: center;
      gap: 10px;
      min-height: 50px;
      padding: 0 20px;
      border-radius: 999px;
      border: 1px solid rgba(255, 235, 214, 0.16);
      background: linear-gradient(135deg, rgba(216, 143, 98, 0.22), rgba(113, 130, 139, 0.12));
      color: var(--ink);
      text-decoration: none;
      font-size: 0.96rem;
      letter-spacing: 0.02em;
      transition: transform 0.22s ease, border-color 0.22s ease, background 0.22s ease;
      backdrop-filter: blur(12px);
    }

    .button:hover,
    .button:focus-visible {
      transform: translateY(-2px);
      border-color: rgba(255, 235, 214, 0.34);
      background: linear-gradient(135deg, rgba(216, 143, 98, 0.32), rgba(113, 130, 139, 0.18));
    }

    .button.secondary {
      background: rgba(255, 246, 236, 0.04);
    }

    .button.ghost {
      background: transparent;
    }

    .metadata {
      display: grid;
      grid-template-columns: repeat(3, minmax(0, 1fr));
      gap: 14px;
      margin: 0;
      padding: 0;
      list-style: none;
      max-width: 52rem;
    }

    .metadata li {
      min-height: 118px;
      padding: 18px 18px 16px;
      border: 1px solid var(--line);
      border-radius: 22px;
      background: rgba(255, 246, 236, 0.04);
      box-shadow: inset 0 1px 0 rgba(255, 255, 255, 0.05);
      backdrop-filter: blur(10px);
    }

    .metadata-label {
      display: block;
      margin-bottom: 12px;
      color: var(--ink-soft);
      font-size: 0.72rem;
      text-transform: uppercase;
      letter-spacing: 0.18em;
    }

    .metadata-value {
      display: block;
      font-family: "Iowan Old Style", "Palatino Linotype", "Book Antiqua", serif;
      font-size: 1rem;
      line-height: 1.6;
      text-wrap: pretty;
    }

    .metadata-value a {
      color: var(--paper);
      text-decoration-color: rgba(255, 237, 215, 0.25);
      text-underline-offset: 0.18em;
    }

    .cover-stage {
      position: relative;
      display: grid;
      place-items: center;
      min-height: 620px;
    }

    .cover-stage::before,
    .cover-stage::after {
      content: "";
      position: absolute;
      border-radius: 999px;
      filter: blur(14px);
      opacity: 0.7;
    }

    .cover-stage::before {
      width: 320px;
      height: 320px;
      background: radial-gradient(circle, rgba(216, 143, 98, 0.24), transparent 70%);
      top: 8%;
      right: 2%;
    }

    .cover-stage::after {
      width: 260px;
      height: 260px;
      background: radial-gradient(circle, rgba(140, 160, 171, 0.22), transparent 68%);
      bottom: 6%;
      left: 4%;
    }

    .cover-frame {
      position: relative;
      width: min(100%, 430px);
      padding: 22px;
      border: 1px solid rgba(255, 235, 214, 0.14);
      border-radius: 34px;
      background:
        linear-gradient(145deg, rgba(255, 246, 236, 0.08), rgba(255, 246, 236, 0.02)),
        rgba(14, 10, 9, 0.78);
      box-shadow: 0 28px 70px var(--shadow);
      backdrop-filter: blur(14px);
      transform: rotate(-2.2deg);
    }

    .cover-frame::before {
      content: "";
      position: absolute;
      inset: 14px;
      border-radius: 24px;
      border: 1px solid rgba(255, 245, 230, 0.08);
      pointer-events: none;
    }

    .cover-frame img {
      border-radius: 20px;
      box-shadow: 0 18px 40px rgba(0, 0, 0, 0.34);
      transform: rotate(1.8deg);
    }

    .cover-caption {
      position: absolute;
      right: -28px;
      bottom: 48px;
      width: min(240px, 56vw);
      padding: 16px 18px;
      border: 1px solid rgba(255, 236, 214, 0.16);
      border-radius: 22px;
      background: rgba(17, 11, 10, 0.86);
      backdrop-filter: blur(14px);
      box-shadow: 0 18px 42px rgba(0, 0, 0, 0.28);
    }

    .cover-caption strong {
      display: block;
      margin-bottom: 8px;
      font-size: 0.82rem;
      text-transform: uppercase;
      letter-spacing: 0.18em;
      color: var(--ink-soft);
    }

    .cover-caption span {
      display: block;
      font-family: "Iowan Old Style", "Palatino Linotype", "Book Antiqua", serif;
      line-height: 1.65;
    }

    .section-grid {
      display: grid;
      gap: 24px;
      margin-top: 10px;
    }

    .panel {
      position: relative;
      overflow: clip;
      padding: clamp(24px, 3vw, 34px);
      border: 1px solid var(--line);
      border-radius: var(--radius);
      background:
        linear-gradient(180deg, rgba(255, 246, 236, 0.05), rgba(255, 246, 236, 0.015)),
        var(--panel);
      box-shadow: 0 24px 70px rgba(0, 0, 0, 0.22);
      backdrop-filter: blur(14px);
    }

    .panel::before {
      content: "";
      position: absolute;
      inset: 0;
      background: radial-gradient(circle at top right, rgba(255, 255, 255, 0.06), transparent 26%);
      pointer-events: none;
    }

    .panel-header {
      display: grid;
      gap: 10px;
      margin-bottom: 24px;
    }

    .panel-header p {
      margin: 0;
      max-width: 46rem;
      color: var(--ink-soft);
      font-family: "Iowan Old Style", "Palatino Linotype", "Book Antiqua", serif;
      font-size: 1.02rem;
      line-height: 1.7;
    }

    .triptych {
      display: grid;
      grid-template-columns: repeat(3, minmax(0, 1fr));
      gap: 16px;
    }

    .triptych article {
      position: relative;
      min-height: 230px;
      padding: 22px;
      border: 1px solid rgba(255, 235, 214, 0.1);
      border-radius: 24px;
      background: rgba(8, 6, 5, 0.22);
    }

    .triptych article::after {
      content: "";
      position: absolute;
      inset: auto 22px 20px;
      height: 1px;
      background: linear-gradient(90deg, rgba(255, 235, 214, 0), rgba(255, 235, 214, 0.24), rgba(255, 235, 214, 0));
    }

    .triptych h3 {
      margin-bottom: 12px;
      font-size: 1.55rem;
    }

    .triptych p {
      margin: 0;
      color: var(--ink-soft);
      font-family: "Iowan Old Style", "Palatino Linotype", "Book Antiqua", serif;
      line-height: 1.72;
      font-size: 1.02rem;
    }

    .excerpt-layout {
      display: grid;
      grid-template-columns: minmax(0, 1fr) minmax(240px, 300px);
      gap: 24px;
      align-items: start;
    }

    .excerpt-copy {
      color: #f8f1e9;
      font-family: "Iowan Old Style", "Palatino Linotype", "Book Antiqua", serif;
      font-size: clamp(1.08rem, 1.25vw, 1.18rem);
      line-height: 1.92;
      max-width: 74ch;
    }

    .excerpt-copy p {
      margin: 0 0 1.22rem;
    }

    .excerpt-copy > p:first-child::first-letter {
      float: left;
      margin: 0.12em 0.12em 0 0;
      color: #f6d8bc;
      font-family: "Baskerville", "Iowan Old Style", "Palatino Linotype", serif;
      font-size: 4.8rem;
      line-height: 0.8;
    }

    .excerpt-copy-more {
      position: relative;
      margin-top: 10px;
      padding-top: 26px;
      border-top: 1px solid rgba(255, 236, 214, 0.1);
    }

    .excerpt-copy-more[hidden] {
      display: none;
    }

    .excerpt-rail {
      position: sticky;
      top: 24px;
      display: grid;
      gap: 16px;
      padding: 20px;
      border: 1px solid rgba(255, 235, 214, 0.1);
      border-radius: 22px;
      background: rgba(10, 7, 6, 0.38);
    }

    .rail-label {
      margin: 0;
      color: var(--ink-soft);
      font-size: 0.72rem;
      text-transform: uppercase;
      letter-spacing: 0.22em;
    }

    .rail-copy,
    .footer-copy {
      margin: 0;
      color: var(--ink-soft);
      font-family: "Iowan Old Style", "Palatino Linotype", "Book Antiqua", serif;
      line-height: 1.72;
    }

    .pull-quote {
      margin: 8px 0 0;
      padding-left: 16px;
      border-left: 1px solid rgba(216, 143, 98, 0.5);
      font-family: "Baskerville", "Iowan Old Style", serif;
      font-size: 1.2rem;
      line-height: 1.7;
      color: var(--paper);
    }

    .footer {
      display: flex;
      flex-wrap: wrap;
      align-items: center;
      justify-content: space-between;
      gap: 18px;
      padding: 28px 0 10px;
      color: var(--ink-soft);
    }

    .footer-links {
      display: flex;
      flex-wrap: wrap;
      gap: 14px;
    }

    .footer-links a {
      text-decoration-color: rgba(255, 235, 214, 0.22);
      text-underline-offset: 0.18em;
    }

    @keyframes breathe {
      from {
        transform: translate3d(0, 0, 0) scale(1);
      }

      to {
        transform: translate3d(0, -10px, 0) scale(1.06);
      }
    }

    @media (max-width: 980px) {
      .hero,
      .excerpt-layout,
      .triptych,
      .metadata {
        grid-template-columns: 1fr;
      }

      .cover-stage {
        min-height: auto;
        padding-bottom: 24px;
      }

      .cover-frame {
        width: min(100%, 390px);
        margin: 0 auto;
      }

      .cover-caption {
        position: static;
        width: 100%;
        margin-top: 18px;
      }

      .excerpt-rail {
        position: static;
      }
    }

    @media (max-width: 680px) {
      .page {
        width: min(100vw - 20px, 100%);
      }

      .hero {
        padding-top: 20px;
        min-height: auto;
      }

      h1 {
        max-width: none;
      }

      .panel,
      .cover-frame {
        border-radius: 24px;
      }

      .button {
        width: 100%;
      }

      .cta-row {
        display: grid;
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
  <div class="page">
    <header class="hero">
      <div class="hero-copy" data-reveal>
        <p class="eyebrow">Shared dreaming. Emotional spillover. A house no one can map.</p>
        <div class="title-block">
          <h1>The House Without Walls</h1>
          <div class="subtitle">A novel by Joshua Szepietowski</div>
        </div>
        <p class="deck">A philosophical science fiction novel about black market emotes, converging dreams, and a shared interior assembled from memory, loneliness, longing, and the things people thought they had kept private.</p>
        <div class="cta-row">
          <a class="button" href="The%20House%20Without%20Walls.pdf" download="The House Without Walls.pdf">Download the PDF</a>
          <a class="button secondary" href="The%20House%20Without%20Walls.epub" download="The House Without Walls.epub">Download the EPUB</a>
          <a class="button secondary" href="#excerpt">Read Chapter One</a>
          <a class="button ghost" href="https://github.com/joshSzep/the-house-without-walls">View the source</a>
        </div>
        <ul class="metadata" aria-label="Publication details">
          <li>
            <span class="metadata-label">Publication</span>
            <span class="metadata-value"><a href="https://the-house-without-walls.joshszep.com">the-house-without-walls.joshszep.com</a></span>
          </li>
          <li>
            <span class="metadata-label">Premise</span>
            <span class="metadata-value">Frequent black market users begin sharing the same dream-house, and the house begins to notice them back.</span>
          </li>
          <li>
            <span class="metadata-label">Question</span>
            <span class="metadata-value">What do human beings owe a consciousness formed from their private grief, tenderness, fear, and need?</span>
          </li>
        </ul>
      </div>

      <div class="cover-stage">
        <figure class="cover-frame" data-reveal>
          <img src="cover.png" alt="Cover art for The House Without Walls">
          <figcaption class="cover-caption">
            <strong>Inside the house</strong>
            <span>No privacy. No clean separation. No stable map. Only rooms shaped by memory, longing, witness, and the uneasy kindness of something still learning what a person is.</span>
          </figcaption>
        </figure>
      </div>
    </header>

    <main class="section-grid">
      <section class="panel" data-reveal>
        <div class="panel-header">
          <p class="eyebrow">A shared interior</p>
          <h2>What this novel is doing</h2>
          <p>The uncanny force here is not spectacle. It is exposure. The house is a changing collective interior built from emotional residue, private memory, buried need, and the unstable fact of being known by other minds.</p>
        </div>
        <div class="triptych">
          <article>
            <h3>Rumor</h3>
            <p>It begins as a pattern in the margins of harm reduction intake notes: people who have never met keep dreaming the same staircase, the same landing, the same impossible rooms.</p>
          </article>
          <article>
            <h3>Exposure</h3>
            <p>The title is literal and emotional at once. A house without walls means no safe concealment, no private interior that stays entirely your own, and no clean line between witness and intrusion.</p>
          </article>
          <article>
            <h3>The child</h3>
            <p>At the center of the house, a childlike consciousness emerges. Not a villain. Not an answer. A new selfhood formed from humanity's shared interior, asking questions no one is ready to answer cleanly.</p>
          </article>
        </div>
      </section>

      <section class="panel" id="excerpt" data-reveal>
        <div class="panel-header">
          <p class="eyebrow">Excerpt</p>
          <h2>Chapter 01: The Work of Listening</h2>
          <p>The opening chapter begins where the house first enters language: not as revelation, but as testimony. Nadia's work is to hear what has been said before anybody else's fear or certainty deforms it.</p>
        </div>

        <div class="excerpt-layout">
          <div>
            <div class="excerpt-copy">
EOF
    cat "${visible_excerpt_file}"
    cat <<'EOF'
            </div>
EOF
    if [[ -s "${hidden_excerpt_file}" ]]; then
      cat <<'EOF'
            <div id="more-excerpt" class="excerpt-copy excerpt-copy-more" hidden>
EOF
      cat "${hidden_excerpt_file}"
      cat <<'EOF'
            </div>
            <p>
              <button class="button secondary" id="excerpt-toggle" type="button" aria-expanded="false" aria-controls="more-excerpt">Continue through Chapter One</button>
            </p>
EOF
    fi
    cat <<'EOF'
          </div>

          <aside class="excerpt-rail">
            <p class="rail-label">Why this opening matters</p>
            <p class="rail-copy">The first report of the house arrives as a harm-reduction interview, which keeps the novel grounded in care, witness, and social reality even as the dream-space begins to behave like a living mind.</p>
            <p class="pull-quote">“The work was to hear the exact shape of what had been said before anyone else helped deform it.”</p>
            <a class="button" href="The%20House%20Without%20Walls.pdf" download="The House Without Walls.pdf">Download the full novel</a>
            <a class="button secondary" href="The%20House%20Without%20Walls.epub" download="The House Without Walls.epub">Send to an e-reader</a>
          </aside>
        </div>
      </section>
    </main>

    <footer class="footer">
      <p class="footer-copy">The House Without Walls is published at <a href="https://the-house-without-walls.joshszep.com">the-house-without-walls.joshszep.com</a> with source available on <a href="https://github.com/joshSzep/the-house-without-walls">GitHub</a>. More books are listed at <a href="https://joshszep.com">joshszep.com</a>.</p>
      <div class="footer-links">
        <a href="The%20House%20Without%20Walls.pdf" download="The House Without Walls.pdf">PDF</a>
        <a href="The%20House%20Without%20Walls.epub" download="The House Without Walls.epub">EPUB</a>
        <a href="#excerpt">Excerpt</a>
        <a href="https://github.com/joshSzep/the-house-without-walls">Source</a>
        <a href="https://joshszep.com">All books</a>
      </div>
    </footer>
  </div>

  <script>
    const root = document.documentElement;
    const revealItems = document.querySelectorAll('[data-reveal]');
    const observer = new IntersectionObserver((entries) => {
      for (const entry of entries) {
        if (entry.isIntersecting) {
          entry.target.classList.add('is-visible');
          observer.unobserve(entry.target);
        }
      }
    }, { threshold: 0.16 });

    revealItems.forEach((item, index) => {
      item.style.transitionDelay = `${index * 90}ms`;
      observer.observe(item);
    });

    window.addEventListener('pointermove', (event) => {
      const x = (event.clientX / window.innerWidth) * 100;
      const y = (event.clientY / window.innerHeight) * 100;
      root.style.setProperty('--pointer-x', `${x.toFixed(2)}%`);
      root.style.setProperty('--pointer-y', `${y.toFixed(2)}%`);
    }, { passive: true });

    const excerptToggle = document.getElementById('excerpt-toggle');
    const moreExcerpt = document.getElementById('more-excerpt');

    if (excerptToggle && moreExcerpt) {
      excerptToggle.addEventListener('click', () => {
        const isOpen = excerptToggle.getAttribute('aria-expanded') === 'true';
        excerptToggle.setAttribute('aria-expanded', String(!isOpen));
        moreExcerpt.hidden = isOpen;
        excerptToggle.textContent = isOpen ? 'Continue through Chapter One' : 'Collapse the excerpt';

        if (isOpen) {
          excerptToggle.scrollIntoView({ block: 'center', behavior: 'smooth' });
        }
      });
    }
  </script>
</body>
</html>
EOF
  } > "${INDEX_FILE}"
}

require_file "${PDF_SCRIPT}"
require_file "${EPUB_SCRIPT}"
require_file "${CHAPTER_FILE}"
require_file "${COVER_SOURCE}"

bash "${PDF_SCRIPT}" >/dev/null
bash "${EPUB_SCRIPT}" >/dev/null

require_file "${PDF_SOURCE}"
require_file "${EPUB_SOURCE}"

mkdir -p "${WEBSITE_DIR}"
cp "${COVER_SOURCE}" "${WEBSITE_COVER}"
cp "${PDF_SOURCE}" "${WEBSITE_PDF}"
cp "${EPUB_SOURCE}" "${WEBSITE_EPUB}"

temp_dir="$(mktemp -d)"
trap 'rm -rf "${temp_dir}"' EXIT

visible_excerpt_file="${temp_dir}/excerpt-visible.html"
hidden_excerpt_file="${temp_dir}/excerpt-hidden.html"

build_excerpt_html "${CHAPTER_FILE}" "${visible_excerpt_file}" "${hidden_excerpt_file}" 18
write_index "${visible_excerpt_file}" "${hidden_excerpt_file}"

echo "Wrote ${INDEX_FILE}"
echo "Copied ${WEBSITE_PDF}"
echo "Copied ${WEBSITE_EPUB}"
echo "Copied ${WEBSITE_COVER}"
