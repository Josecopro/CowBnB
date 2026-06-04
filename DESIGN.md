---
name: CowBnB
description: Two-sided marketplace for leasing agricultural land. Photography-led, trust-critical, Spanish-first.
colors:
  primary: "oklch(0.50 0.105 188)"
  primary-hover: "oklch(0.44 0.110 188)"
  primary-soft: "oklch(0.96 0.018 188)"
  primary-ink: "oklch(0.30 0.060 188)"
  accent: "oklch(0.66 0.135 50)"
  accent-hover: "oklch(0.60 0.140 50)"
  accent-soft: "oklch(0.96 0.030 60)"
  surface: "oklch(1.000 0.000 0)"
  surface-container: "oklch(0.985 0.003 188)"
  surface-container-low: "oklch(0.992 0.002 188)"
  surface-sunken: "oklch(0.978 0.004 188)"
  ink: "oklch(0.18 0.005 188)"
  ink-muted: "oklch(0.45 0.005 188)"
  ink-soft: "oklch(0.62 0.004 188)"
  border: "oklch(0.91 0.004 188)"
  border-soft: "oklch(0.95 0.003 188)"
  success: "oklch(0.62 0.130 155)"
  warning: "oklch(0.74 0.140 75)"
  danger: "oklch(0.55 0.180 25)"
  info: "oklch(0.55 0.110 240)"
  on-primary: "oklch(1.000 0.000 0)"
  on-accent: "oklch(0.18 0.020 50)"
  on-dark: "oklch(0.98 0.003 188)"
  dark-bg: "oklch(0.22 0.030 188)"
  dark-bg-deep: "oklch(0.16 0.022 188)"
typography:
  display:
    fontFamily: "Manrope, ui-sans-serif, system-ui, sans-serif"
    fontSize: "clamp(2.25rem, 5vw, 3.5rem)"
    fontWeight: 700
    lineHeight: 1.08
    letterSpacing: "-0.02em"
  headline:
    fontFamily: "Manrope, ui-sans-serif, system-ui, sans-serif"
    fontSize: "1.75rem"
    fontWeight: 700
    lineHeight: 1.2
    letterSpacing: "-0.015em"
  title:
    fontFamily: "Manrope, ui-sans-serif, system-ui, sans-serif"
    fontSize: "1.125rem"
    fontWeight: 600
    lineHeight: 1.35
    letterSpacing: "-0.01em"
  body:
    fontFamily: "Manrope, ui-sans-serif, system-ui, sans-serif"
    fontSize: "1rem"
    fontWeight: 400
    lineHeight: 1.55
  body-small:
    fontFamily: "Manrope, ui-sans-serif, system-ui, sans-serif"
    fontSize: "0.875rem"
    fontWeight: 400
    lineHeight: 1.5
  label:
    fontFamily: "Manrope, ui-sans-serif, system-ui, sans-serif"
    fontSize: "0.875rem"
    fontWeight: 600
    lineHeight: 1.3
    letterSpacing: "0"
  label-small:
    fontFamily: "Manrope, ui-sans-serif, system-ui, sans-serif"
    fontSize: "0.75rem"
    fontWeight: 600
    lineHeight: 1.3
    letterSpacing: "0.02em"
rounded:
  xs: "4px"
  sm: "6px"
  md: "10px"
  lg: "14px"
  pill: "999px"
spacing:
  1: "4px"
  2: "8px"
  3: "12px"
  4: "16px"
  5: "20px"
  6: "24px"
  8: "32px"
  10: "40px"
  12: "48px"
  16: "64px"
  20: "80px"
  24: "96px"
components:
  button-primary:
    backgroundColor: "{colors.primary}"
    textColor: "{colors.on-primary}"
    typography: "{typography.label}"
    rounded: "{rounded.md}"
    padding: "14px 22px"
  button-primary-hover:
    backgroundColor: "{colors.primary-hover}"
  button-accent:
    backgroundColor: "{colors.accent}"
    textColor: "{colors.on-accent}"
    typography: "{typography.label}"
    rounded: "{rounded.md}"
    padding: "14px 22px"
  button-secondary:
    backgroundColor: "{colors.surface-container}"
    textColor: "{colors.ink}"
    typography: "{typography.label}"
    rounded: "{rounded.md}"
    padding: "14px 22px"
  button-ghost:
    backgroundColor: "transparent"
    textColor: "{colors.ink}"
    typography: "{typography.label}"
    rounded: "{rounded.md}"
    padding: "12px 16px"
  input-default:
    backgroundColor: "{colors.surface}"
    textColor: "{colors.ink}"
    typography: "{typography.body}"
    rounded: "{rounded.md}"
    padding: "14px 16px"
  input-focus:
    backgroundColor: "{colors.surface}"
    textColor: "{colors.ink}"
    typography: "{typography.body}"
    rounded: "{rounded.md}"
    padding: "14px 16px"
  card-default:
    backgroundColor: "{colors.surface}"
    textColor: "{colors.ink}"
    rounded: "{rounded.lg}"
    padding: "16px"
  card-sunken:
    backgroundColor: "{colors.surface-container}"
    textColor: "{colors.ink}"
    rounded: "{rounded.lg}"
    padding: "16px"
  chip-default:
    backgroundColor: "{colors.surface-container}"
    textColor: "{colors.ink-muted}"
    typography: "{typography.label-small}"
    rounded: "{rounded.pill}"
    padding: "6px 12px"
  chip-success:
    backgroundColor: "{colors.primary-soft}"
    textColor: "{colors.primary-ink}"
    typography: "{typography.label-small}"
    rounded: "{rounded.pill}"
    padding: "6px 12px"
  nav-bottom:
    backgroundColor: "{colors.dark-bg}"
    textColor: "{colors.on-dark}"
    typography: "{typography.label-small}"
    rounded: "{rounded.lg}"
    padding: "12px 0"
---

# Design System: CowBnB

## 1. Overview

**Creative North Star: "The Field, Framed."**

The CowBnB interface treats agricultural land the way a coffee-table atlas treats a country: a generous photograph, restrained typography, a sentence or two of well-chosen data, and quiet chrome. The product is a thin layer over a Firebase-backed marketplace where landowners list plots and farmers/agronomists discover and reserve them. The interface is Spanish-first and mobile-first, designed for a farmer checking listings on a mid-range Android phone over patchy 3G, not for a designer on a fiber connection.

The visual system is **photography-led**, **data-honest**, and **warmly committed**. Photography is the hero: listings lead with imagery at editorial scale, and metadata (hectares, certifications, monthly price, soil, water rights, climate) appears as compact, scannable rows rather than as prose. Color is **committed** to a deep teal primary anchored to a calm-verdigris brand seed, with a warm ochre accent that carries the "cálido" register without competing the primary for attention. The body surface stays near-pure neutral so the land — and the typography — carries the mood.

This system explicitly rejects the saturated 2025-2026 AI defaults: no warm-cream body backgrounds, no M3 sage/forest stock scheme, no marketplace-template card grids with eyebrow micro-labels, no farm-kitsch wheat/gingham, no gradient text, no sketchy hand-drawn SVGs, no glassmorphism as a default treatment. Cards are flat at rest; depth comes from tonal layering and a sparse, considered shadow vocabulary used only as a response to state, never as decoration.

**Key Characteristics:**
- One sans family (Manrope) carries display, headline, title, body, and label. No display/body pairing.
- Restrained-on-the-surface, committed-in-the-accents. Pure white body; teal primary on chrome and CTAs; warm ochre for warmth-bearing moments (favorites, "save", reservation-confirmed states, profile highlights).
- State-rich component vocabulary. Every interactive element ships with default / hover / focus / active / disabled / loading / error.
- Photography at editorial scale. No image gets cropped to fit a card chrome; the card recedes to fit the image.
- Spanish copy in product surfaces. No Spanglish, no translated idioms, no marketing buzzwords.
- Calm motion: 150-220ms ease-out-quart/expo on state changes; no orchestrated page-loads; reduced-motion alternatives everywhere.

## 2. Colors

The palette is built around a single committed brand color (deep teal) and a single warmth-bearing accent (warm ochre), with a near-pure-neutral surface stack and a deep brand-tinted dark surface for chrome. Body text and metadata are tinted to the brand hue at near-zero chroma so the system reads as one family, not a layer cake of unrelated grays.

### Primary
- **Deep Field Teal** (`oklch(0.50 0.105 188)`): The brand's anchor. Used on the bottom navigation active state, primary CTAs, the brand mark, and the dark surface variant. Carries the "con calma, se hace" confidence the personality calls for. Hue is anchored to the brand seed at 188°, within ±10°; not adjustable to taste.
- **Field Teal Hover** (`oklch(0.44 0.110 188)`): Pressed/hover state of the primary. Slightly deeper, slightly more saturated.
- **Field Teal Soft** (`oklch(0.96 0.018 188)`): The pale tint of primary, used for selected filter chips, "available" status pills, and confirmation banners. Tinted, not gray.
- **Field Teal Ink** (`oklch(0.30 0.060 188)`): Text/icons that need to read as on-brand without the weight of the primary fill (e.g., price tags, status text on a soft pill).

### Accent
- **Warm Ochre** (`oklch(0.66 0.135 50)`): The "cálido" in cálido/confiable/optimista. Reserved for warmth-bearing moments: the heart icon on favorited listings, the "save" confirmation, the reservation-confirmed badge, the owner's earnings highlight, and accent rules on featured listings. Used on ≤8% of any given screen. The accent is **never** the primary CTA color; primary handles the action, accent handles the emotion.
- **Warm Ochre Hover** (`oklch(0.60 0.140 50)`): Hover state of the accent.
- **Warm Ochre Soft** (`oklch(0.96 0.030 60)`): Pale tint of the accent, used for warmth-bearing backgrounds behind a single piece of content (e.g., a feature card highlighting soil quality).

### Neutral (Surface + Ink)
- **Pure Paper** (`oklch(1.000 0.000 0)`): The body background. Pure white, no hidden warmth. The seed-script's Default A. Photographs and typography carry the warmth; the surface stays neutral.
- **Soft Tint** (`oklch(0.992 0.002 188)`): A near-white with a hair of teal. Used for sections that need to "lift" from Pure Paper without darkening — the booking-confirmation panel, the listing-detail metadata block.
- **Container** (`oklch(0.985 0.003 188)`): Slightly deeper tint, for sunken surfaces, side panels, and the input field default background.
- **Sunken** (`oklch(0.978 0.004 188)`): For inset regions, chat-bubble-other, and the disabled-input background.
- **Ink** (`oklch(0.18 0.005 188)`): Body text. Carries the brand hue at near-zero chroma so it reads as warm-neutral, not as a black slab. Must clear WCAG 7:1 against Pure Paper (it does, ~13:1).
- **Ink Muted** (`oklch(0.45 0.005 188)`): Secondary text — labels, metadata, captions. Must clear 4.5:1 against Pure Paper.
- **Ink Soft** (`oklch(0.62 0.004 188)`): Tertiary text. Reserved for placeholders and timestamps. **Must still clear 4.5:1**; this is the single most-failed rule in AI-generated design, and we refuse to ship the "muted gray" default.
- **Border** (`oklch(0.91 0.004 188)`): Visible but felt, not seen. Used for input strokes and card outlines when needed.
- **Border Soft** (`oklch(0.95 0.003 188)`): Reserved for separators inside cards, where the eye shouldn't track to them.

### Dark
- **Field Dark** (`oklch(0.22 0.030 188)`): The bottom navigation background and dark surfaces (modal sheets, image overlays, full-bleed hero overlays). Brand-tinted, not neutral black.
- **Field Dark Deep** (`oklch(0.16 0.022 188)`): The image-overlay gradient endpoint and modal scrim base.

### Semantic
- **Success** (`oklch(0.62 0.130 155)`): Reservation confirmed, listing active, payment processed. Carries an icon (check) and a label, never color alone.
- **Warning** (`oklch(0.74 0.140 75)`): Pending state, lease ending soon, low-availability warning.
- **Danger** (`oklch(0.55 0.180 25)`): Cancellation, error, deletion. Carries an icon and a label, never color alone.
- **Info** (`oklch(0.55 0.110 240)`): Neutral informational state, "system message", help text.

### Named Rules

**The One Voice Rule.** Primary carries the action; accent carries the emotion. The warm ochre is never used on a primary CTA button. The deep teal is never used as a decorative fill — it is functional (CTA, brand mark, active state, dark surface). The two colors earn their place per use, not per screen.

**The No-Cream Rule.** The body background is Pure Paper (`#ffffff`). Period. The "warmth" in cálido comes from the accent, the photography, and the copy. Tinting the body toward warm is the AI neutral of the year, and CowBnB refuses it.

**The Saturation Ceiling.** No primary, accent, or semantic color carries text below WCAG 4.5:1. Saturated mid-luminance fills (L 0.42-0.78, chroma ≥ 0.08) always use **white text**, never dark text — even where WCAG technically passes. Dark text is correct only on pale fills (L > 0.85) or near-neutral fills.

**The Tonal Layering Rule.** Depth comes from a four-step surface stack (Paper → Soft Tint → Container → Sunken) and from a sparse shadow vocabulary — not from saturated colored fills, not from 1px borders everywhere, and not from `box-shadow: 0 Npx 16px` ghost-card patterns.

## 3. Typography

**Display Font:** Manrope
**Body Font:** Manrope
**Label Font:** Manrope

A single sans family carries every text role. Manrope is humanist in proportion, with optical warmth that matches the cálido personality; it has wide language coverage including Spanish, and it has weight contrast (200-800) that gives the scale room to breathe without introducing a display/body pairing. The product register explicitly prefers one family for earned familiarity — the tool disappears into the task.

**Character:** Warm, modern, confident. Manrope at display weight is editorial without being precious; at body weight it is approachable and legible at small sizes. No second family. No serif. No mono unless absolutely needed for invoice numbers, in which case use a system mono stack.

### Hierarchy
- **Display** (700, `clamp(2.25rem, 5vw, 3.5rem)`, 1.08, -0.02em): The hero statement on landing and listing-detail pages only. Cap at `3.5rem` (~56px). Tighter letter-spacing at display weight for editorial authority; no all-caps display, no `font-stretch`.
- **Headline** (700, 1.75rem, 1.2, -0.015em): Section headings inside product surfaces (dashboard section titles, listing titles in detail views, settings panel headings). The workhorse of the app.
- **Title** (600, 1.125rem, 1.35, -0.01em): Card titles, modal titles, drawer titles, list-item primary text. The readable-yet-quiet middle weight.
- **Body** (400, 1rem, 1.55): Reading copy. Cap line length at 65-75ch on prose-heavy screens (listing descriptions, owner bios, terms text). On dense data screens (dashboards, reservations tables) line length is uncapped.
- **Body Small** (400, 0.875rem, 1.5): Metadata, captions, supporting copy under titles. Never the primary reading layer.
- **Label** (600, 0.875rem, 1.3, 0): Button labels, form labels, navigation labels, chip labels. Always rendered at 600 weight to read as actionable, not decorative.
- **Label Small** (600, 0.75rem, 1.3, +0.02em): Status pills, micro-labels on data fields, navigation secondary text. Used sparingly and only when content density demands.

### Named Rules

**The One Family Rule.** Manrope is the only typeface. No pairing. Adding a second family is a design failure unless explicitly approved (e.g., a financial document that requires tabular numerals as a separate stack — not a separate family).

**The Weight-Contrast Rule.** Hierarchy comes from size **and** weight contrast, not from size alone. A `1rem` Body and a `1.125rem` Title at the same weight (400) is the AI-flat trap; Title must hit 600 to read as a title. Step ratio between Body/Title/Headline is 1.125-1.2, not fluid. Display scales fluidly because users view hero at varying device sizes; UI text does not.

**The No-All-Caps-Body Rule.** Uppercase is reserved for status pills ("ACTIVA", "PENDIENTE"), short labels (≤4 words), and the rare section eyebrow (used at most once per page, deliberately). Body copy, headings, and titles are sentence case. The skill's hard rule: sentences in ALL CAPS are unreadable at body sizes.

## 4. Elevation

CowBnB is **flat by default**. Depth is conveyed through a four-step tonal surface stack (Paper → Soft Tint → Container → Sunken) and through a sparse, role-specific shadow vocabulary used only as a response to state. Traditional drop shadows — particularly the `0 4px 16px rgba(0,0,0,0.08)` ghost-card pattern — are prohibited as decoration.

A shadow appears only when an element is **lifted** by interaction: hover on a card, an open modal sheet, a focused input, a snackbar/toast, a floating action button, a popover. The shadow is sized to the lift: small shadows for small lifts (hover), larger shadows for sheets and modals.

### Shadow Vocabulary
- **lift-1** (`0 1px 2px rgba(20, 35, 28, 0.06)`): Hover state on a card, a list item being pressed, a chip being selected. The shadow is almost invisible; the surface is felt to be touchable, not the shadow itself.
- **lift-2** (`0 4px 12px rgba(20, 35, 28, 0.08)`): Active modal sheet, focused input glow, a popover anchored to a button. Carries a slight brand-tinted shadow (the `20 35 28` is the primary in sRGB).
- **lift-3** (`0 12px 32px rgba(20, 35, 28, 0.12)`): Top-level modal, full-screen image viewer, the bottom navigation when raised above a content scroll. Reserved for elements that genuinely need to detach from the page.
- **overlay** (`0 0 0 1px rgba(20, 35, 28, 0.04), 0 24px 64px rgba(20, 35, 28, 0.16)`): A floating CTA bar (the "Reservar" bar on listing detail), a top-of-screen action sheet.

The shadow color uses the brand's deep teal in sRGB, not neutral black, so the shadow reads as part of the system, not as a generic "Material" shadow. This is the opposite of the M3 default and the key reason the system feels considered, not template-y.

### Named Rules

**The Flat-By-Default Rule.** At rest, surfaces are flat. No shadow, no gradient fill, no 1px colored border on cards. The only "decoration" allowed on a resting card is the tonal layering from the surface stack.

**The No-Ghost-Card Rule.** `border: 1px solid X` plus `box-shadow: 0 Npx Mpx ...` with M ≥ 16 on the same element is forbidden. Pick one. Default is: no border + no shadow (rely on tonal layering). If a card needs to read as interactive, give it `lift-1` on hover, not a permanent border.

**The Brand-Tinted Shadow Rule.** Every shadow uses `rgba(20, 35, 28, ...)` — the primary in sRGB — not `rgba(0, 0, 0, ...)`. Neutral black shadows read as "Material default"; brand-tinted shadows read as the system. This is the difference between a system and a template.

## 5. Components

Each component ships with full state coverage: default, hover, focus, active, disabled, loading, error. No component is shipped with only a default and a hover.

### Buttons
- **Shape:** `md` radius (10px). The pill is reserved for chips and tags.
- **Primary:** Field Teal fill, white text, label typography, 14×22 padding. Used for the single primary action on a screen ("Reservar", "Crear publicación", "Guardar cambios"). Disabled state drops fill to Ink Soft and text to Pure Paper at 60% opacity.
- **Hover:** Field Teal Hover, 150ms ease-out-quart. No transform, no scale — color change is enough.
- **Focus:** 2px Field Teal outline at 2px offset; `lift-2` shadow. Visible against any surface, including the dark bottom nav.
- **Active:** Field Teal Hover + 1px darker stroke. Quick release.
- **Loading:** Inline spinner (12px) replacing the label; button width does not jump.
- **Secondary:** Container fill, Ink text, same radius and padding. Used for secondary actions ("Cancelar", "Ver más", "Volver").
- **Ghost:** Transparent fill, Ink text, no border. Used for tertiary actions inside dense screens (dashboard quick actions, list-item trailing icons).
- **Accent (rare):** Warm Ochre fill, dark text (`on-accent: oklch(0.18 0.020 50)`). Used only for emotionally-charged confirmations ("Sí, reservar", "Marcar favorito"). The accent button is **not** a default; the design system asks "would the user feel scolded?" — if yes, use primary, not accent.

### Inputs
- **Style:** Pure Paper fill, Border stroke at 1px, label typography as the hint, `md` radius (10px). No top label by default; placeholders carry the load. When a label is required (form fields, checkout), the label sits *above* the field, left-aligned, label-small, Ink Muted.
- **Focus:** Border thickens to 2px Field Teal; container background stays Pure Paper. `lift-2` shadow appears for keyboard focus only, not for tap.
- **Disabled:** Container fill, Border Soft stroke, Ink Soft text. No interaction affordance.
- **Error:** Border thickens to 2px Danger; an inline message in 0.75rem Danger text appears below the field, prefixed by a 14px alert icon. Never red alone — always icon + label.
- **Search:** Same shape, but with a leading magnifier icon, 40px height minimum, Container fill. Used in the explore page, the chat conversation list, and the listings filter drawer.

### Cards / Listing Cards
- **Corner Style:** `lg` radius (14px). Cards never exceed 14px. Period.
- **Background:** Pure Paper. The card sits on a Soft Tint section to provide the "ledge" — tonal layering, not a border.
- **Shadow Strategy:** None at rest. `lift-1` on press/hover only.
- **Border:** None by default. When a card needs a boundary (e.g., a saved-search item, a chat message), use Border at 1px, not a shadow.
- **Internal Padding:** 16px on metadata cards, 0px on image-led cards (the image is the card; metadata sits in a 16px pad below).
- **Listing Card (image-led):** Image at the top at `4:3` aspect ratio, 14px top corners only (clip the image, not the card). Below: title (Title, 1.125rem), location (Body Small, Ink Muted), price (Label, Field Teal Ink, right-aligned), and a single metadata row (hectares + certification chip) at the bottom. No four-stat grid. No shadow.

### Chips / Pills
- **Style:** `pill` radius (999px), 6px vertical × 12px horizontal padding, Label Small typography.
- **State:** Default (Container fill, Ink Muted text). Selected (Field Teal Soft fill, Field Teal Ink text). Filter chips on the explore page use the selected treatment to indicate the active filter set.
- **Status chips** (reservation status, listing status) carry a 6px leading dot in the semantic color, with the label. Color is never the only signal — the label is mandatory, and an icon is included for screen-reader users.

### Navigation
- **Bottom Navigation:** Field Dark (`oklch(0.22 0.030 188)`) fill, brand-tinted — not neutral black. Top corners `lg` radius. Each item: 24px icon, Label Small label below. Active item: Field Teal Soft pill behind the icon, white-on-dark for the label.
- **Top Bar (page-level):** Pure Paper fill, no border, no shadow. Title in Title typography left-aligned; trailing actions (notifications, profile avatar, back) right-aligned. The top bar disappears on scroll-down and reappears on scroll-up, with 200ms ease-out-quart — never with a transform that fights the content.
- **Back navigation:** A single ghost-icon button (24px chevron-left) on the leading edge of the top bar. No "Volver" label — the icon is the convention.
- **Tab navigation (sub-pages):** A horizontal scroller of tabs at the top of the content region, with a 2px Field Teal underline on the active tab. Tabs are never the primary navigation — they appear only inside a section that has clear sub-categories (listing management: activas / pendientes / completadas).

### Modal / Sheets
- **Bottom sheet (mobile default):** Pure Paper fill, 14px top corners, `lift-3` shadow. A drag handle (40×4px, Ink Soft, pill radius) sits 8px from the top.
- **Center dialog (rare):** Used only for destructive or irreversible actions ("¿Cancelar reserva?", "¿Eliminar publicación?"). Pure Paper fill, 14px radius, `lift-3` shadow. Title in Headline, body in Body, primary action in Danger (for destructive) or Primary, secondary in Ghost.
- **Toast / SnackBar:** Field Dark fill, white text, 10px radius, `lift-2` shadow. Slides up from the bottom on iOS, slides in from below on Android, auto-dismiss at 3s. No "Got it" copy.

### Empty States
- **Shape:** Pure Paper fill, 14px radius card, centered content. A 64px icon in Ink Soft above, a Title and a Body paragraph, then a single Primary button.
- **Tone:** Helpful, not apologetic. "Aún no tienes publicaciones" beats "No hay publicaciones" because it names the state, not the absence. Empty states are an opportunity to teach the interface — they should not feel like a "nothing here" dead end.

### Skeletons (Loading)
- **Shape:** Pure Paper container, 14px radius, with shimmer placeholders at `Container` fill pulsing to `Surface Container Low` and back. Skeletons match the layout of the loaded content (a card-shaped skeleton for a card-shaped result).
- **Why:** Spinners in the middle of content make the user wait for the interface. Skeletons reserve the space, communicate the layout, and let the user feel the content is on its way.

## 6. Do's and Don'ts

The Do's and Don'ts below carry PRODUCT.md's anti-references forward as visual prohibitions. Every line in this list is binding for any screen built on this system.

### Do:
- **Do** use Manrope as the only typeface. Single family. No pairing, no fallback to a system serif.
- **Do** use Pure Paper (`#ffffff`) for the body background. Warmth comes from the accent, photography, and copy.
- **Do** show the land first. Hero images at editorial scale; metadata recedes.
- **Do** show data in compact, scannable rows. Hectares, certifications, monthly price, soil, water rights, climate, dates — name them, give them a unit, leave them visible.
- **Do** give every interactive element a full state vocabulary: default, hover, focus, active, disabled, loading, error. No half-built components.
- **Do** use Field Teal Soft for selected state, available status, and confirmation; Warm Ochre Soft for warmth-bearing moments (favorites, featured listings, reservation-confirmed).
- **Do** use `lift-1` / `lift-2` / `lift-3` shadows on interaction, brand-tinted to `rgba(20, 35, 28, ...)`. Never neutral black shadows.
- **Do** cap card radius at 14px. Chips and tags use the pill. Inputs use `md` (10px).
- **Do** write copy in natural Spanish, sentence case, no buzzwords. Specifics (hectares, certifications, monthly price) over adjectives.
- **Do** reserve motion for state changes (150-220ms ease-out-quart). No orchestrated page-load sequences. Always provide a `prefers-reduced-motion` alternative.
- **Do** verify contrast. Body text ≥4.5:1, large text ≥3:1, placeholder text ≥4.5:1 (not the AI-default light gray). Run the WCAG calculator before shipping.
- **Do** reserve the warm ochre for emotionally-charged moments (favorited, confirmed, "save"). The accent is not a primary CTA color.
- **Do** use skeletons for loading, not centered spinners.

### Don't:
- **Don't** use a warm-cream / sand / parchment / linen / paper / wheat / biscuit body background. The 2025-2026 AI neutral is banned; Pure Paper is the body, period.
- **Don't** use the Material Design 3 stock sage/forest scheme with rounded-everything. This system starts from a fresh token system on purpose.
- **Don't** ship the "marketplace template" cliché: search bar + filter chips + card grid + map split + 01/02/03 numbered scaffolding. Compose each surface for the job, not from the template.
- **Don't** use farm-kitsch — wheat icons, gingham patterns, scarecrow palettes, "homegrown" hand-drawn SVGs, leather-and-rope textures. The brand is modern agriculture, not rural nostalgia.
- **Don't** use hand-drawn / sketchy SVG illustrations. If we cannot ship a real asset, we ship no illustration.
- **Don't** use `background-clip: text` with a gradient on display headings. Decorative emphasis. Use a single solid color and weight contrast.
- **Don't** use glassmorphism as a default. Blur effects appear only as a state response (focus glow, modal scrim) and never as a card treatment.
- **Don't** use 1px colored side-stripe borders (`border-left`, `border-right` > 1px in a colored accent) on cards, list items, callouts, or alerts. Use full borders, background tints, leading numbers/icons, or nothing.
- **Don't** use a `1px solid X` border **plus** a soft wide drop shadow on the same element. The ghost-card pattern. Pick one: a 1px border at the brand color, OR a defined shadow at no more than 8px blur, never both as decoration.
- **Don't** use `border-radius: 24px+` on cards, sections, or inputs. Cards top out at 14px; full-pill is fine for tags/buttons.
- **Don't** use `repeating-linear-gradient(...)` stripe backgrounds in section backgrounds. Decorative noise, not design.
- **Don't** ship "X theater" / "actually X" / "not just X, it's Y" copy ("productivity theater", "empowerment theater", "engagement theater"). Pick a specific noun, not a meta-criticism.
- **Don't** ship ALL CAPS body copy. Reserve uppercase for short labels (≤4 words), status pills, and at most one deliberate section eyebrow per page.
- **Don't** ship display headings above `3.5rem` (~56px). Above that the page is shouting, not designing. Tighten letter-spacing to -0.02em or looser; never tighter than -0.04em.
- **Don't** ship without a `prefers-reduced-motion` alternative for every animation. The reduced-motion user is not a future user; they are today's user.
- **Don't** ship "Search bar + filter chips + result cards + map" as a default composition. Each surface earns its layout; the template is not the answer.
- **Don't** ship the hero-metric template (big number, small label, supporting stats, gradient accent). Stats live where stats are useful, not as a SaaS-cliché above the fold.
- **Don't** ship gradient text. Don't ship 32px+ border-radius on cards. Don't ship the eyebrow-on-every-section kicker. These are the absolute bans; they are not negotiable.
