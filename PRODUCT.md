# Product

## Register

product

## Users

Two-sided agricultural-land marketplace. Both sides carry equal weight; the product succeeds only when both transact.

- **Owners** (landowners, agricultural producers, family estates): list fields for lease, manage reservations, message interested renters, set terms. Their job is to fill idle land with vetted operators and earn from it without losing control of long-term use.
- **Renters** (farmers, agronomists, agribusiness operators): discover land that matches a specific operating profile (soil, water rights, climate, certifications, acreage, distance), reserve it, sign terms, take possession. Their job is to find good ground faster than their season window allows.

Context: Spanish-speaking markets first (LatAm starting point, Spain as a natural second). Farmers and landowners are not power users; they are busy, sometimes on patchy mobile data, sometimes older, sometimes non-tech-native. They will not fight the interface.

## Product Purpose

CowBnB makes leasing farmland as straightforward as booking a stay. Owners post a plot with the data that matters (soil, water, climate, certifications, price per month, dates available). Renters filter, discover on a map, view details, reserve, and chat — all in-app. The product is a thin, opinionated layer over Firebase Auth / Firestore / Realtime DB / Cloud Functions / Storage, in a single Flutter codebase, mobile-first.

Success means: a renter can find and reserve a viable plot in under five minutes on a mid-range Android phone over 3G; an owner can post a new listing in under three minutes and have it appear on the map within seconds. Trust, not novelty, is the metric. Every transaction either side makes must feel safe.

## Brand Personality

**Three words: cálido, confiable, optimista** (warm, dependable, optimistic). The tone is conversational Spanish — the agronomist at the cooperative counter, not a SaaS landing page. Generous whitespace, photography-led listings, and quiet chrome let the land carry the color energy.

Reference: **Airbnb host side** specifically — the way it gives two-sided products an optimistic, photo-first vocabulary, treats hosts and guests with the same quality of surface, and uses warmth in accent and photography rather than in a tinted body background.

Voice rules:
- Spanish copy in the product itself. Natural Castilian or neutral LatAm Spanish — no Spanglish, no translated idioms, no marketing buzzwords ("empoderar", "transformar", "sin fisuras" are banned).
- Landowner and renter speak like people, not personas. A renter who needs a plot for next season's alfalfa gets a sentence, not a slogan.
- Confidence through specifics (hectares, certifications, monthly price, soil type) — not through adjectives.

## Anti-references

- **No Material Design 3 defaults.** CowBnB does not ship the stock M3 sage/forest scheme with rounded-everything and the FilledButton defaults. We are not building on the M3 template; the token system starts fresh.
- **No warm-cream / sand / parchment / linen / paper / wheat / biscuit body background.** That is the 2025-2026 AI neutral; it is banned. The body surface is either pure white or a considered brand-tinted neutral — never a default-warm tinted near-white.
- **No "marketplace template" cliché.** No obligatory search-bar-plus-filter-chips-plus-card-grid-plus-map split. No `01 / 02 / 03` numbered scaffolding over every section. No eyebrow micro-labels above every heading.
- **No farm kitsch.** No wheat icons, no gingham, no "homegrown" hand-drawn scarecrow palette, no leather-and-rope textures. The brand is modern agriculture, not rural nostalgia.
- **No hand-drawn / sketchy SVG illustrations.** If we cannot ship a real asset, we ship no illustration.
- **No gradient text.** No `background-clip: text` with gradients on display headings.
- **No cards-on-cards-on-cards.** Cards are used only where they are the right affordance. Elevation comes from tonal layering, not from stacked `Container`s inside `Container`s.

## Design Principles

1. **Show the land, not the chrome.** Photography is the product. Listings lead with imagery at editorial scale; chrome (chips, metadata, price) recedes around it. Screens are composed around a single hero image, not balanced across competing panels.
2. **Two sides, equal weight.** Owner and renter surfaces get the same quality of design, the same typography, the same spacing cadence. A "secondary" role is never a thinner product.
3. **Trust through data, warmth through copy.** Soil composition, water rights, climate fit, certifications, dates, monthly price — shown cleanly, in tables or compact rows, not buried in prose. Voice stays human. Numbers carry credibility; adjectives do not.
4. **Committed surface, quiet chrome.** The brand's color energy lives in the brand colors (primary + accent) and in photography — not in a tinted body background. Surface stays near-pure-neutral so the land and the typography carry the mood.
5. **Spanish-first, English-ready.** Copy is written for Spanish readers, by Spanish-readers' standards. Structure (string externalization, locale-aware date/number formatting) is in place so English lands as a real second locale, not a machine translation.
6. **Mobile-first, patchy-network-friendly.** A farmer checking listings on a slow 3G connection on a mid-range Android phone is the baseline. Image budgets are real; loading states are real; empty and error states are designed, not stubbed.
7. **Calm motion.** Reveals are short, eased-out-quart/expo, and respect `prefers-reduced-motion`. Motion is intentional, never decoration.

## Accessibility & Inclusion

- **WCAG 2.1 AA.** Body text ≥4.5:1 against its background; large text (≥18px or bold ≥14px) ≥3:1; placeholder text and muted secondary text must also clear 4.5:1, not the default light-gray.
- **Screen readers.** Every interactive widget has a meaningful label. Icon-only buttons get a `Semantics` label. Status pills and reservation states are announced.
- **Keyboard / switch / external input.** Tab order is logical; focus rings are visible against every surface (including the dark navbar).
- **Reduced motion.** Every animation has a `prefers-reduced-motion` alternative — usually an instant transition or a crossfade.
- **Color independence.** Status is never encoded by color alone; reservation states combine color, label, and (where useful) iconography. The brand palette is verified for protanopia / deuteranopia.
- **Language.** Spanish is the first locale; English is a planned second locale with real localization, not auto-translation. Date and currency formatting are locale-aware (ES first; en-US ready).
- **Onboarding for non-tech-native users.** The first-run flow explains a single concept per step, in Spanish, with the smallest possible interaction surface. The app does not assume familiarity with marketplace UX.
