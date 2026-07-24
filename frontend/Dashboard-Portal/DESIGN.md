---
name: Kinetic Logic
colors:
  surface: '#f8f9ff'
  surface-dim: '#cbdbf5'
  surface-bright: '#f8f9ff'
  surface-container-lowest: '#ffffff'
  surface-container-low: '#eff4ff'
  surface-container: '#e5eeff'
  surface-container-high: '#dce9ff'
  surface-container-highest: '#d3e4fe'
  on-surface: '#0b1c30'
  on-surface-variant: '#584237'
  inverse-surface: '#213145'
  inverse-on-surface: '#eaf1ff'
  outline: '#8c7164'
  outline-variant: '#e0c0b1'
  surface-tint: '#9d4300'
  primary: '#9d4300'
  on-primary: '#ffffff'
  primary-container: '#f97316'
  on-primary-container: '#582200'
  inverse-primary: '#ffb690'
  secondary: '#006c49'
  on-secondary: '#ffffff'
  secondary-container: '#6cf8bb'
  on-secondary-container: '#00714d'
  tertiary: '#006591'
  on-tertiary: '#ffffff'
  tertiary-container: '#09a4e8'
  on-tertiary-container: '#003650'
  error: '#ba1a1a'
  on-error: '#ffffff'
  error-container: '#ffdad6'
  on-error-container: '#93000a'
  primary-fixed: '#ffdbca'
  primary-fixed-dim: '#ffb690'
  on-primary-fixed: '#341100'
  on-primary-fixed-variant: '#783200'
  secondary-fixed: '#6ffbbe'
  secondary-fixed-dim: '#4edea3'
  on-secondary-fixed: '#002113'
  on-secondary-fixed-variant: '#005236'
  tertiary-fixed: '#c9e6ff'
  tertiary-fixed-dim: '#89ceff'
  on-tertiary-fixed: '#001e2f'
  on-tertiary-fixed-variant: '#004c6e'
  background: '#f8f9ff'
  on-background: '#0b1c30'
  surface-variant: '#d3e4fe'
typography:
  headline-xl:
    fontFamily: Inter
    fontSize: 36px
    fontWeight: '700'
    lineHeight: 44px
    letterSpacing: -0.02em
  headline-lg:
    fontFamily: Inter
    fontSize: 28px
    fontWeight: '600'
    lineHeight: 36px
    letterSpacing: -0.01em
  headline-md:
    fontFamily: Inter
    fontSize: 20px
    fontWeight: '600'
    lineHeight: 28px
  body-lg:
    fontFamily: Inter
    fontSize: 18px
    fontWeight: '400'
    lineHeight: 28px
  body-md:
    fontFamily: Inter
    fontSize: 16px
    fontWeight: '400'
    lineHeight: 24px
  body-sm:
    fontFamily: Inter
    fontSize: 14px
    fontWeight: '400'
    lineHeight: 20px
  label-lg:
    fontFamily: Inter
    fontSize: 14px
    fontWeight: '600'
    lineHeight: 20px
    letterSpacing: 0.05em
  label-md:
    fontFamily: Inter
    fontSize: 12px
    fontWeight: '500'
    lineHeight: 16px
  headline-xl-mobile:
    fontFamily: Inter
    fontSize: 28px
    fontWeight: '700'
    lineHeight: 34px
rounded:
  sm: 0.25rem
  DEFAULT: 0.5rem
  md: 0.75rem
  lg: 1rem
  xl: 1.5rem
  full: 9999px
spacing:
  base: 8px
  xs: 4px
  sm: 12px
  md: 24px
  lg: 40px
  xl: 64px
  gutter: 24px
  margin-mobile: 16px
  margin-desktop: 32px
---

## Brand & Style

The design system is built for high-performance data environments where clarity is paramount and engagement is driven by energetic visual cues. It targets professional analysts and decision-makers who require a tool that feels both powerful and approachable. 

The aesthetic is **Corporate Modern** with a lean toward **High-Contrast Minimalism**. By pairing a high-energy primary orange with a pristine white canvas and rigorous grid logic, the design system avoids the cluttered "spreadsheet" look of traditional dashboards. It evokes an emotional response of confidence, precision, and momentum. Visual hierarchy is maintained through generous whitespace and a purposeful use of accent colors to guide the user's eye to key performance indicators and actionable insights.

## Colors

The palette is anchored by a vibrant **International Orange** that serves as the primary driver for action and brand presence. This is balanced by a **Success Green** used for positive growth metrics and "go" states. 

The background architecture utilizes a "Layered White" approach: a slightly tinted off-white (`#F8FAFC`) for the page canvas and pure white (`#FFFFFF`) for interactive cards and surfaces. This subtle contrast ensures that dashboard modules remain distinct without requiring heavy borders. Neutrals are pulled from a cool slate palette to maintain a professional, tech-forward feel that doesn't compete with the primary orange.

## Typography

The design system utilizes **Inter** across all levels to leverage its exceptional legibility and systematic feel. The type scale is optimized for data density; headings use a tighter letter-spacing and heavier weights to stand out against analytical content.

Label styles are crucial for this design system; they employ a mix of medium and semi-bold weights with slight tracking increases to ensure category headers and table captions are immediately scannable. On mobile devices, large display headings scale down to prevent awkward line breaks in narrow dashboard columns.

## Layout & Spacing

This design system follows a **12-column fluid grid** for desktop, collapsing to a **4-column grid** for mobile. It is built on an **8px base unit**, ensuring all spatial relationships are multiples of 8 to maintain mathematical harmony.

- **Margins:** Large 32px outer margins on desktop provide the "generous whitespace" requested, preventing the UI from feeling cramped.
- **Gutters:** Standardized 24px gutters provide clear separation between dashboard widgets.
- **Padding:** Internal card padding should default to `md` (24px) to ensure data visualizations have room to breathe.

## Elevation & Depth

Visual hierarchy is established through **Ambient Shadows** and **Tonal Layering**. Instead of harsh borders, we use depth to signify interactivity.

1.  **Level 0 (Flat):** The page background.
2.  **Level 1 (Raised):** Standard dashboard cards. Use a very soft, diffused shadow: `0px 4px 12px rgba(0, 0, 0, 0.05)`.
3.  **Level 2 (Interactive/Hover):** Applied when a user hovers over a card or button. The shadow deepens slightly and the element shifts upwards by 2px: `0px 8px 24px rgba(0, 0, 0, 0.08)`.
4.  **Level 3 (Overlay):** For modals and dropdowns. High diffusion to pull the element significantly forward: `0px 12px 32px rgba(0, 0, 0, 0.12)`.

Glassmorphism is used sparingly, only for persistent navigation sidebars to allow background dashboard colors to subtly bleed through, maintaining a sense of place.

## Shapes

The design system uses a **Rounded** shape language to soften the analytical nature of the dashboard and make it feel modern and user-friendly.

- **Small Components (Chips/Badges):** Use `rounded-lg` (1rem) to create a pill-like effect.
- **Standard Components (Buttons/Inputs):** Use the base `rounded` (0.5rem) for a balanced, professional look.
- **Large Containers (Cards/Modals):** Use `rounded-xl` (1.5rem) to define the major structural blocks of the page.

## Components

### Buttons
- **Primary:** Solid Orange background with white text. High-contrast, bold, and rounded.
- **Secondary:** White background with Orange border and Orange text.
- **Ghost:** No background or border; Orange text. Used for less critical actions like "Cancel."

### Cards
Cards are the primary container for data. They feature a pure white surface, a `rounded-xl` corner radius, and a Level 1 shadow. States include:
- **Default:** Level 1 shadow.
- **Hover:** Level 2 shadow + 1px Orange border.
- **Selected:** 2px Orange border.

### Alerts
Alerts use a desaturated version of the semantic color for the background and a high-saturated version for the text and side-accent bar.
- **Success:** Soft green background, dark green text.
- **Warning:** Soft orange background, dark orange text.
- **Error:** Soft red background, dark red text.

### Input Fields
Inputs are minimalist: a light gray border that transitions to a 2px Orange border on focus. Labels sit clearly above the field in `label-md` style.

### Data Visualization Accents
Charts should primarily use the primary Orange for the main data series, with Green used for comparative growth and a secondary Blue for multi-series charts. All chart elements should respect the `rounded` corner logic (e.g., bar chart tops).