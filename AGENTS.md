# AGENTS.md

This document provides guidance for AI assistants and automated tools working in the **The House Without Walls** repository.

AI contributors must read this file before modifying code or content.

This project is unusual and has strict philosophical and architectural constraints. AI systems must respect those constraints.

---

# Project Philosophy

**The House Without Walls** is a handcrafted hypertext labyrinth.

It is not a game engine.  
It is not a procedural storytelling system.  
It is not a generative AI project.

It is a **literary artifact** composed of many interconnected Markdown documents.

Readers wander through symbolic spaces. With persistence, they eventually reach a center.

The project emphasizes:

- wandering
- discovery
- symbolic resonance
- contemplative writing
- structural elegance

The labyrinth must feel like a place someone built intentionally.

---

# Core Design Principles

## Local Clarity, Global Mystery

Each page must be easy to understand in isolation.

However, the reader must **never be able to see the entire structure of the labyrinth**.

AI assistants must not add:

- maps
- structural diagrams
- progress indicators
- completion metrics
- "you are here" features

The labyrinth must remain unknowable at the global scale.

---

## Static By Design

The entire labyrinth must be capable of deployment as a **fully static site**.

Do not introduce:

- server-side rendering
- databases
- user accounts
- sessions
- backend APIs
- runtime state

Build tooling may generate static HTML pages, but runtime behavior must remain static.

---

## Authored Content Only

All labyrinth content must be **written by humans**.

AI systems may assist with drafting, editing, and formatting, but must not introduce:

- procedural generation
- dynamic narrative generation
- LLM runtime calls
- AI-driven branching logic

Every node exists because someone deliberately placed it.

---

## Dreamlike Symbolic Space

The labyrinth follows **symbolic and dreamlike logic**, not physical architecture.

Spaces may include:

- corridors
- gardens
- mirrors
- libraries
- staircases
- empty rooms
- lantern-lit halls
- still water
- bells

Connections between spaces should feel emotionally or symbolically coherent rather than geographically logical.

---

# Structural Model

The labyrinth is a **directed graph** composed of nodes.

Each node represents a location.

Nodes contain:

- title
- prose description
- a set of choices leading to other nodes

Paths may:

- branch
- loop
- recombine
- lead to reflective dead ends
- contain hidden nodes
- converge toward centers

---

# Centers

There is not one center.

There are **many centers**.

Centers represent enlightenment or realization through different symbolic metaphors.

Examples include:

- an empty room
- a mirror that reflects nothing
- a still pool
- an open sky
- a quiet garden

Centers should feel simple, quiet, and reflective.

Centers should typically allow the reader to **begin again**.

---

# Dead Ends

Dead ends are allowed and encouraged.

Dead ends should feel reflective rather than punitive.

They should offer:

- stillness
- contemplation
- a pause in wandering

Dead ends must still provide a way back into the labyrinth.

---

# Loops

Loops are an essential part of the labyrinth.

Loops should rarely feel like obvious repetition.

Prefer subtle phrasing such as:

> The corridor feels familiar.

or

> You think you may have passed through here before.

Loops help create the sense of wandering and scale.

---

# Convergence

Paths should recombine frequently.

Different wandering routes should eventually lead to shared nodes.

This creates the realization that the labyrinth is guiding rather than trapping.

---

# Content Format

All labyrinth nodes are authored as **Markdown files**.

Each node file contains:

- metadata
- prose
- choices

The exact schema is defined in `CONTENT_MODEL.md`.

AI assistants must follow the canonical schema when creating or modifying nodes.

---

# Writing Style

The prose must remain:

- calm
- contemplative
- symbolic
- sensory
- minimal but evocative

Avoid:

- overly long exposition
- mechanical descriptions
- puzzle instructions
- overt philosophical explanation

Let the spaces and symbols communicate meaning.

Writing guidelines are defined in `STYLE_GUIDE.md`.

---

# Build System Responsibilities

Build tooling may:

- validate node IDs
- validate links
- detect unreachable nodes
- detect broken references
- generate static HTML pages
- organize pages into a navigable site

Build tooling must **not**:

- alter content meaning
- generate narrative content
- expose the global labyrinth structure

---

# Contributor Expectations

AI assistants should:

- prioritize clarity
- avoid over-engineering
- preserve the project's philosophical tone
- maintain compatibility with static deployment

When uncertain, prefer **simplicity**.

The labyrinth grows through carefully placed nodes, not through complex systems.

---

# Guiding Question

When adding content or features, ask:

> Does this make the labyrinth feel more like a place someone can wander?

If the answer is no, reconsider the change.
