# Technical Decisions — Web / TypeScript

> This document is filled in by the LLM after the bootstrap conversation. It records what was decided and WHY, so every future prompt has context. If this is still a template, the bootstrap hasn't happened yet.

---

## Engine Path

**Engine**: Web (TypeScript)

## Tech Stack

| Category | Choice | Why |
|----------|--------|-----|
| **Renderer** | _TBD_ (Three.js / Babylon.js / Phaser / PixiJS / etc.) | _reasoning_ |
| **State management** | _TBD_ (Simple objects / FSM / ECS) | _reasoning_ |
| **Physics** | _TBD_ (Rapier / cannon-es / Ammo.js / none) | _reasoning_ |
| **Audio** | _TBD_ (Howler.js / Web Audio / framework built-in) | _reasoning_ |
| **Build tool** | _TBD_ (Vite recommended) | _reasoning_ |
| **Networking** | _TBD_ (None / Socket.io / Colyseus / WebRTC) | _reasoning_ |

## Dependencies

| Package | Purpose | Alternatives Considered |
|---------|---------|------------------------|
| _TBD_ | _TBD_ | _TBD_ |

## Architecture Notes

_How do the major pieces connect? What's the data flow? Written after tech stack is confirmed._

## Rejected Alternatives

_Record what you decided NOT to do and why. This prevents revisiting the same discussions._

| Option | Rejected Because |
|--------|-----------------|
| _TBD_ | _TBD_ |
