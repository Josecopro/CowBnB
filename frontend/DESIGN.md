# Design System Document: The Fertile Digital Landscape

## 1. Overview & Creative North Star: "CowBnB"
This design system moves beyond the generic "marketplace" aesthetic to establish a visual language rooted in **CowBnB**. Our North Star is a fusion of precision agricultural technology and high-end editorial clarity. We reject the "boxed-in" feeling of standard SaaS templates in favor of a layered, organic experience that feels as expansive as the farmland it represents.

To break the "template" look, we utilize **Intentional Asymmetry**. Hero layouts should push imagery off-center, allowing sophisticated typography scales to occupy the negative space. We prioritize "breathing room" (generous white space) over information density, ensuring that every plot of land feels premium and every transaction feels secure.

---

## 2. Colors & Tonal Depth
Our palette is inspired by satellite imagery and lush topography. We use color not just for decoration, but to define the physical architecture of the interface.

### The "No-Line" Rule
**Strict Mandate:** Designers are prohibited from using 1px solid borders for sectioning. Boundaries between content blocks must be defined solely through background color shifts. For instance, a `surface-container-low` section should sit against a `surface` background to create a "ledge" rather than a "fence."

### Surface Hierarchy & Nesting
Treat the UI as a series of stacked, organic layers. 
- **Base Layer:** `surface` (#f3fbf4) for general page backgrounds.
- **Content Blocks:** Use `surface-container` (#e8f0e9) to group related information.
- **Elevated Cards:** Use `surface-container-lowest` (#ffffff) to make interactive elements pop against muted backgrounds. This "low-to-high" nesting creates natural depth without visual clutter.

### The "Glass & Gradient" Rule
To evoke "Agro-tech" sophistication, use **Glassmorphism** for floating navigation bars or filter drawers. 
- **Effect:** Apply `surface-container-lowest` at 80% opacity with a `24px` backdrop blur.
- **Signature Textures:** For primary CTAs and Hero headers, use a subtle linear gradient (Top-Left to Bottom-Right) transitioning from `primary` (#236b43) to `tertiary-container` (#24a85f). This adds a "living" quality to the interface.

---

## 3. Typography: The Grounded Editorial
We pair **Manrope** (Display/Headlines) with **Work Sans** (Body/Labels) to balance technological precision with human legibility.

*   **Display Scale (Manrope):** Use `display-lg` (3.5rem) for hero statements. Tighten letter-spacing by -2% to give it an authoritative, editorial punch.
*   **Headline Scale (Manrope):** `headline-md` (1.75rem) serves as the primary anchor for land listings.
*   **Body Scale (Work Sans):** `body-lg` (1rem) is the workhorse. Ensure a line-height of 1.6 for maximum readability during long-form lease reviews.
*   **Label Scale (Work Sans):** `label-md` (0.75rem) in `on-surface-variant` (#404941) provides metadata without distracting from the primary narrative.

---

## 4. Elevation & Depth: Tonal Layering
Traditional drop shadows are too "heavy" for this system. We achieve lift through light and tone.

*   **The Layering Principle:** Place a card using `surface-container-lowest` (#ffffff) on a background of `surface-container-low` (#eef6ef). The contrast alone provides the necessary "lift."
*   **Ambient Shadows:** Where floating interaction is required (e.g., a "Book Now" floating bar), use a shadow: `0px 20px 40px rgba(29, 51, 37, 0.06)`. This uses a tinted version of our `deep-background` to mimic natural light filtered through a canopy.
*   **The Ghost Border:** If a boundary is required for accessibility, use a 1px stroke of `outline-variant` (#bfc9bf) at **15% opacity**. It should be felt, not seen.

---

## 5. Components: Precision Primitives

### Buttons: The High-Contrast Action
- **Primary:** Gradient fill (`primary` to `tertiary-container`), white text, `xl` (1.5rem) roundedness.
- **Secondary:** `secondary-container` (#c5e8d0) with `on-secondary-container` (#4a6a56) text. No border.
- **Interaction:** On hover, increase the gradient saturation. On click, use a subtle `0.98` scale transform.

### Inputs: The Clean Slate
- **Surface:** `surface-container-highest` (#dce5de).
- **Border:** None, except for a 2px `primary` bottom-bar that expands from the center on focus.
- **Radius:** `md` (0.75rem).

### Cards & Lists: The Infinite Field
- **The Rule of No Dividers:** Forbid the use of horizontal rules (`<hr>`). Separate list items using the spacing scale (e.g., `8` / 2rem) or alternating tonal shifts between `surface` and `surface-container-low`.
- **Land Cards:** Use `xl` (1.5rem) corner radius for main imagery. Metadata should be clustered in the bottom-left using `title-sm` for price and `label-md` for location.

### Specialized Component: The "Yield Map" Chip
A specialized chip for farmland data. Use `tertiary-fixed` (#81fba8) background with `on-tertiary-fixed-variant` (#00522a) text to highlight soil quality or acreage.

---

## 6. Do’s and Don’ts

### Do:
*   **Do** use asymmetrical margins (e.g., 8rem on the left, 4rem on the right) for editorial layouts.
*   **Do** use `pure white` (#ffffff) text exclusively on `Deep/Background` (#1D3325) or `Primary` surfaces.
*   **Do** leverage the `xl` (1.5rem) corner radius for high-impact imagery to make the tech feel approachable.

### Don’t:
*   **Don’t** use pure black (#000000) for text. Use `on-surface` (#161d19) to maintain a soft, organic feel.
*   **Don’t** use standard "Material" shadows. If it looks like a "box" with a shadow, it’s not refined enough.
*   **Don’t** use icons without a clear "Agro-tech" weight. Use 1.5pt stroke icons that match the `outline` token.