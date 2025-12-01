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

---

# Core Palette

## Light Mode – Neutrals

| Name       | Color | Value   |
| ---------- | ----- | ------- |
| Background | White | #FFFFFF |
| Foreground | Black | #1C1C1E |
| Comment    | Gray  | #6E6E73 |
| UI         | Gray  | #C7C7CC |

## Light Mode – Navy

| Name      | Color   | Value   |
| --------- | ------- | ------- |
| Main      | Navy    | #1C2B5A |
| Secondary | Navy    | #6F82B3 |
| Base      | Navy    | #101C3A |

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
| UI         | Gray  | #3A3A3C |

## Dark Mode – Navy

| Name      | Color     | Value   |
| --------- | --------- | ------- |
| Main      | Navy      | #8FA7E8 |
| Secondary | Navy Soft | #5C74B8 |
| Base      | Navy      | #334789 |

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
| 4    | blue    | #1C2B5A | Navy           |
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
| 12   | bright_blue    | #6F82B3 |
| 13   | bright_magenta | #8B6FB1 |
| 14   | bright_cyan    | #6FA1A7 |
| 15   | bright_white   | #FFFFFF |

Defaults:
foreground: #1C1C1E
background: #FFFFFF
cursor: #101C3A

---

# Source ANSI — Dark

## Base 16

| Slot | Name    | Hex     | Role          |
| ---- | ------- | ------- | ------------- |
| 0    | black   | #1C1C1E | Canvas        |
| 1    | red     | #FF453A | Error         |
| 2    | green   | #67B7A4 | Muted success |
| 3    | yellow  | #FFC36A | Warm cue      |
| 4    | blue    | #8FA7E8 | Navy          |
| 5    | magenta | #B58CC9 | Reserved      |
| 6    | cyan    | #6FA1A7 | Teal          |
| 7    | white   | #8E8E93 | Comment gray  |

## Bright 16

| Slot | Name           | Hex     |
| ---- | -------------- | ------- |
| 8    | bright_black   | #3A3A3C |
| 9    | bright_red     | #FF6A5E |
| 10   | bright_green   | #8AD4C2 |
| 11   | bright_yellow  | #FF9F1C |
| 12   | bright_blue    | #8EA2D6 |
| 13   | bright_magenta | #D1A8E6 |
| 14   | bright_cyan    | #9BC7CC |
| 15   | bright_white   | #F2F2F7 |

Defaults:
foreground: #F2F2F7
background: #1C1C1E
cursor: #334789

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
