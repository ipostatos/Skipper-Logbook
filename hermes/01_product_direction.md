# 01 — Product Direction

## Positioning

> Apple Health / Voice Memos for captains.
> A calm, native iOS logbook for every voyage.

Skipper Logbook is a **digital helper logbook**, not a certified navigation
system. It never competes with Navionics/ECDIS on charts; it wins by being the
cleanest captain's memory system: record the passage, capture events and voice
notes, keep the vessel's history, stay safe with MOB and anchor watch.

## Approved visual direction — Liquid Nautical Minimalism

- White/milky background, soft glass cards, thin strokes for sunlight readability.
- Large tabular numerals; minimal text; SF Symbols.
- Calm maritime palette; **red is reserved for MOB / emergency / danger states**.
- One main accent per screen.
- No dark marine cockpit, no fake Navionics/ECDIS look, no visual noise.
- Feels like a system app next to Apple Health, Voice Memos, Apple Maps.

## Non-negotiable principles

1. **Clarity over decoration** — speed, course, ETA, distance, coordinates, MOB
   state and recording state must be readable at a glance, in sunlight, on a
   heeling boat.
2. **No fake functionality** — unfinished features are `.comingSoon()` (dimmed,
   disabled, badged) or hidden. Never a dead button that pretends to work.
3. **Safety first** — MOB is always reachable, always red, protected by
   long-press + haptics, never buried in settings. Anchor watch must actually
   alarm (haptic + sound + notification), not just recolor a label.
4. **Smart State Dashboard** — Today adapts: no voyage → Start Voyage CTA;
   underway → live metrics + quick actions; anchored → anchor watch status;
   MOB active → red banner overriding everything else.
5. **Solo developer guardrail** — boring, documented architecture. Every change
   understandable without the original author.
6. **Offline-first** — basic logbook never requires internet, location
   permission, or an account. Manual entries always work.

## Target users

Sailing & motor skippers, yacht owners, delivery crews, sailing schools,
instructors, regatta participants — anyone who wants a clean history of their
passages.

## Monetization (future)

Free: 1 vessel, limited voyages, manual logbook, basic MOB.
Pro (subscription/lifetime): unlimited vessels/voyages, audio notes, GPX/CSV/PDF
export, maintenance log, widgets, advanced statistics. School/fleet tier later.

## Safety disclaimer (must ship in-app and in README)

> Skipper Logbook is a digital logbook and voyage tracking assistant. It is not
> a certified navigation system and must not be used as the sole source of
> navigation or safety decisions.
