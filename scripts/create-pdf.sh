#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
MANUSCRIPT_SCRIPT="${SCRIPT_DIR}/create-manuscript.sh"
MANUSCRIPT_FILE="${REPO_ROOT}/OUTLINE.md"
COVER_FILE="${REPO_ROOT}/cover.png"
OUTPUT_FILE="${REPO_ROOT}/The House Without Walls.pdf"

require_command() {
  local command_name="$1"

  if ! command -v "${command_name}" >/dev/null 2>&1; then
    echo "Required command not found: ${command_name}" >&2
    exit 1
  fi
}

render_pdf_markdown() {
  local source_file="$1"
  local output_file="$2"

  awk '
    function latex_escape(text) {
      gsub(/&/, "\\\\&", text)
      gsub(/%/, "\\\\%", text)
      gsub(/\$/, "\\\\$", text)
      gsub(/#/, "\\\\#", text)
      gsub(/_/, "\\\\_", text)
      gsub(/\{/, "\\\\{", text)
      gsub(/\}/, "\\\\}", text)
      return text
    }

    BEGIN {
      in_body = 0
      just_rendered_part = 0
    }

    /^## Part / {
      in_body = 1
      title = latex_escape(substr($0, 4))

      print ""
      print "\\clearpage"
      print "\\thispagestyle{empty}"
      print "\\vspace*{0.28\\textheight}"
      print "\\begin{center}"
      print "{\\fontsize{24}{30}\\selectfont\\bfseries " title "\\par}"
      print "\\vspace{1.1em}"
      print "{\\color{paperline}\\rule{0.24\\textwidth}{0.6pt}\\par}"
      print "\\end{center}"
      print "\\vspace*{0.28\\textheight}"
      print "\\clearpage"
      print ""

      just_rendered_part = 1
      next
    }

    /^### Chapter / {
      if (!in_body) {
        next
      }

      title = latex_escape(substr($0, 5))

      print ""
      if (!just_rendered_part) {
        print "\\clearpage"
      }
      print "\\chapter*{" title "}"
      print "\\markboth{" title "}{" title "}"
      print ""

      just_rendered_part = 0
      next
    }

    {
      if (!in_body) {
        next
      }

      print
      just_rendered_part = 0
    }
  ' "${source_file}" > "${output_file}"
}

write_preamble() {
  local preamble_file="$1"

  cat > "${preamble_file}" <<'EOF'
\usepackage[T1]{fontenc}
\usepackage[utf8]{inputenc}
\usepackage[paperwidth=6in,paperheight=9in,inner=0.9in,outer=0.75in,top=0.9in,bottom=1in,headheight=14pt,headsep=18pt,footskip=28pt]{geometry}
\usepackage{graphicx}
\usepackage{xcolor}
\usepackage{mathpazo}
\usepackage{setspace}
\usepackage{titlesec}
\usepackage{fancyhdr}
\usepackage{emptypage}
\usepackage{needspace}

\definecolor{ink}{HTML}{1D1916}
\definecolor{softgray}{HTML}{6E645B}
\definecolor{paperline}{HTML}{B8AB99}

\AtBeginDocument{\color{ink}}
\AtBeginDocument{\hypersetup{pdftitle={The House Without Walls},pdfauthor={Joshua Szepietowski}}}

\setstretch{1.08}
\setlength{\parindent}{1.2em}
\setlength{\parskip}{0pt}
\widowpenalty=10000
\clubpenalty=10000
\displaywidowpenalty=10000
\brokenpenalty=7000
\emergencystretch=2em
\raggedbottom

\pagestyle{fancy}
\fancyhf{}
\fancyhead[L]{\small\scshape The House Without Walls}
\fancyhead[R]{\small\nouppercase{\rightmark}}
\fancyfoot[C]{\thepage}
\renewcommand{\headrulewidth}{0pt}
\renewcommand{\footrulewidth}{0pt}

\fancypagestyle{plain}{
  \fancyhf{}
  \fancyfoot[C]{\thepage}
  \renewcommand{\headrulewidth}{0pt}
  \renewcommand{\footrulewidth}{0pt}
}

\titleformat{name=\chapter,numberless}[display]
  {\normalfont\centering}
  {}
  {0pt}
  {\needspace{8\baselineskip}\vspace*{1.5em}{\fontsize{21}{26}\selectfont\bfseries}}
  [\vspace{0.9em}{\color{paperline}\rule{0.22\textwidth}{0.6pt}}\vspace{1.3em}]

\titlespacing*{\chapter}{0pt}{0pt}{0pt}

\titleformat{\section}
  {\normalfont\large\bfseries\itshape}
  {}
  {0pt}
  {}

\titlespacing*{\section}{0pt}{1.75em}{0.6em}
EOF
}

write_frontmatter() {
  local frontmatter_file="$1"

  cat > "${frontmatter_file}" <<EOF
\begin{titlepage}
\newgeometry{margin=0in}
\thispagestyle{empty}
\noindent\includegraphics[width=\paperwidth,height=\paperheight]{${COVER_FILE}}
\restoregeometry
\end{titlepage}

\clearpage
\pagenumbering{arabic}
\setcounter{page}{1}
EOF
}

require_command pandoc
require_command pdflatex

if [[ ! -f "${MANUSCRIPT_SCRIPT}" ]]; then
  echo "Manuscript generator not found: ${MANUSCRIPT_SCRIPT}" >&2
  exit 1
fi

if [[ ! -f "${COVER_FILE}" ]]; then
  echo "Cover file not found: ${COVER_FILE}" >&2
  exit 1
fi

bash "${MANUSCRIPT_SCRIPT}" >/dev/null

temp_dir="$(mktemp -d)"
trap 'rm -rf "${temp_dir}"' EXIT

pdf_markdown="${temp_dir}/manuscript-for-pdf.md"
preamble_file="${temp_dir}/preamble.tex"
frontmatter_file="${temp_dir}/frontmatter.tex"

write_preamble "${preamble_file}"
write_frontmatter "${frontmatter_file}"
render_pdf_markdown "${MANUSCRIPT_FILE}" "${pdf_markdown}"

pandoc "${pdf_markdown}" \
  --from=markdown+raw_tex \
  --standalone \
  --pdf-engine=pdflatex \
  --include-in-header="${preamble_file}" \
  --include-before-body="${frontmatter_file}" \
  --variable=documentclass:book \
  --variable=classoption:oneside \
  --variable=classoption:openany \
  --variable=fontsize:11pt \
  --output "${OUTPUT_FILE}"

echo "Wrote ${OUTPUT_FILE}"