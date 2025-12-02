# Source Color Palette Reference

A color system designed for **typographic clarity first**, with minimal but expressive color, tuned for deuteranomaly-friendly contrast and macOS consistency.

This palette intentionally avoids rainbow syntax highlighting and instead provides a restrained, system-integrated environment using:

- Navy for structure
- Orange for attention
- Gray for readability
- Typography for meaning

---

# Philosophy

## Goals

✅ Readability over decoration
✅ Typography as the primary signal
✅ Color as secondary emphasis
✅ Grayscale-first design
✅ macOS-native tone and contrast

## Design Principles

- **Meaning ≠ color**
- **Eyes read code like books**
- **Avoid color noise**
- **macOS integrated**

## Usage

Base Navy

✔ borders
✔ active frame
✔ caret
✔ underlines
✔ subtle UI anchors

Main Navy

✔ functions
✔ namespaces
✔ types
✔ links

Secondary Navy

✔ selections (with alpha)
✔ search
✔ highlights
✔ shadows

---

# Core Palette

## Light Mode – Neutrals

| Name       | Color | Value   |
| ---------- | ----- | ------- |
| Background | White | #FFFFFF |
| Foreground | Black | #1C1C1E |
| Comment    | Gray  | #6E6E73 |
| Subtle     | Gray  | #8E8E93 |
| UI         | Gray  | #C7C7CC |

## Light Mode – Navy

| Name      | Color | Value   |
| --------- | ----- | ------- |
| Base      | Ink   | #1B2340 |
| Main      | Navy  | #2F4A8F |
| Secondary | Sky   | #8FA7E8 |

## Light Mode – Accent

| Name      | Color  | Value   |
| --------- | ------ | ------- |
| Highlight | Orange | #FF8F1F |
| Emphasis  | Orange | #FFB766 |
| Surface   | Orange | #B45309 |
| Error     | Red    | #D70015 |

---

## Dark Mode – Neutrals

| Name       | Color | Value   |
| ---------- | ----- | ------- |
| Background | Black | #1C1C1E |
| Foreground | White | #F2F2F7 |
| Comment    | Gray  | #8E8E93 |
| Subtle     | Gray  | #A1A1A6 |
| UI         | Gray  | #2C2C2E |

## Dark Mode – Navy

| Name      | Color | Value   |
| --------- | ----- | ------- |
| Base      | Ink   | #3D4F86 |
| Main      | Navy  | #6C86C3 |
| Secondary | Sky   | #A9B9E8 |

## Dark Mode – Accent

| Name      | Color  | Value   |
| --------- | ------ | ------- |
| Highlight | Orange | #FF9F1C |
| Emphasis  | Orange | #FFC36A |
| Surface   | Orange | #C2410C |
| Error     | Red    | #FF453A |

---

# Typographic Roles

| Role      | Style       |
| --------- | ----------- |
| Keywords  | Bold        |
| Functions | Italic navy |
| Types     | Semi-bold   |
| Comments  | Dim gray    |
| Strings   | Italic      |
| Errors    | Red         |
| Focus     | Underline   |

---

# ANSI Guidance

ANSI color slots are preserved.
Values are harmonized, not remapped.

**Bright = contrast, not neon**
**Dim = de-emphasis, not disabled**

# Source — ANSI Palette

This ANSI mapping harmonizes traditional terminal colors with the **Source** palette philosophy.

Rules:

- Slots remain standard ANSI (no remapping).
- Bright means higher contrast, not neon.
- Dim is de-emphasis only.
- Navy replaces generic blue.
- Yellow is warm orange.
- Red reserved for errors.

---

# Source ANSI — Light

## Base 16

| Slot | Name    | Hex     | Role           |
| ---- | ------- | ------- | -------------- |
| 0    | black   | #1C1C1E | Foreground ink |
| 1    | red     | #D70015 | Error          |
| 2    | green   | #3E6F6B | Muted success  |
| 3    | yellow  | #FFB766 | Warm cue       |
| 4    | blue    | #2F4A8F | Navy           |
| 5    | magenta | #6E4B8B | Reserved       |
| 6    | cyan    | #3D6970 | Teal           |
| 7    | white   | #C7C7CC | UI gray        |

## Bright 16

| Slot | Name           | Hex     |
| ---- | -------------- | ------- |
| 8    | bright_black   | #6E6E73 |
| 9    | bright_red     | #FF453A |
| 10   | bright_green   | #5F8F8C |
| 11   | bright_yellow  | #FF8F1F |
| 12   | bright_blue    | #8FA7E8 |
| 13   | bright_magenta | #8B6FB1 |
| 14   | bright_cyan    | #6FA1A7 |
| 15   | bright_white   | #FFFFFF |

## Dim

| Name        | Hex     |
| ----------- | ------- |
| dim_black   | #8E8E93 |
| dim_red     | #A11318 |
| dim_green   | #2F5C58 |
| dim_yellow  | #D89A51 |
| dim_blue    | #24396C |
| dim_magenta | #573C70 |
| dim_cyan    | #2F5358 |
| dim_white   | #AEB3B8 |

## Defaults

| Name              | Hex     |
| ----------------- | ------- |
| foreground        | #1C1C1E |
| background        | #FFFFFF |
| cursor            | #1B2340 |
| bright_foreground | #000000 |
| dim_foreground    | #6E6E73 |

---

# Source ANSI — Dark

## Base 16

| Slot | Name    | Hex     | Role          |
| ---- | ------- | ------- | ------------- |
| 0    | black   | #1C1C1E | Canvas        |
| 1    | red     | #FF453A | Error         |
| 2    | green   | #67B7A4 | Muted success |
| 3    | yellow  | #FFC36A | Warm cue      |
| 4    | blue    | #6C86C3 | Navy          |
| 5    | magenta | #B58CC9 | Reserved      |
| 6    | cyan    | #6FA1A7 | Teal          |
| 7    | white   | #8E8E93 | Comment gray  |

## Bright 16

| Slot | Name           | Hex     |
| ---- | -------------- | ------- |
| 8    | bright_black   | #2C2C2E |
| 9    | bright_red     | #FF6A5E |
| 10   | bright_green   | #8AD4C2 |
| 11   | bright_yellow  | #FF9F1C |
| 12   | bright_blue    | #A9B9E8 |
| 13   | bright_magenta | #D1A8E6 |
| 14   | bright_cyan    | #9BC7CC |
| 15   | bright_white   | #F2F2F7 |

## Dim

| Name        | Hex     |
| ----------- | ------- |
| dim_black   | #121214 |
| dim_red     | #C53A33 |
| dim_green   | #4F9383 |
| dim_yellow  | #D2A14E |
| dim_blue    | #536AA2 |
| dim_magenta | #8E73A3 |
| dim_cyan    | #558287 |
| dim_white   | #6D6D72 |

## Defaults

| Name              | Hex     |
| ----------------- | ------- |
| foreground        | #F2F2F7 |
| background        | #1C1C1E |
| cursor            | #3D4F86 |
| bright_foreground | #FFFFFF |
| dim_foreground    | #3D4F86 |

---

# Book Mode Notes

Designed for ANSI-only terminals.

- Normal text: foreground
- Keywords: Bold
- Functions & types: Italic
- Strings: Italic or Yellow sparingly
- Comments: Bright black
- Errors: Red / Bright red
- Focus: Underline

Typography first. Color second.

---

# Book Mode

Book mode uses:

- ANSI only
- No decorative color
- Typographic emphasis
- Single accent color
