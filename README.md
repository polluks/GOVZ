# MC6847 (VDG) Video Modes for C128 8563 VDC

This document describes the MC6847 Video Display Generator (VDG) modes as used on
the VZ200 series computers, and how a compatible alphanumeric mode is implemented
on the Commodore 128's 8563 Video Display Controller (VDC).

> **References:** vz200.org hardware documentation and standard MC6847 datasheets
> for the VDG side; the C128 Programmer's Reference Guide, the MOS 8563/8568
> datasheet, the VICE VDC emulation sources (`vdc.c`, `vdc-mem.c`, `vdc-color.c`)
> and the C128 KERNAL ROM (`kernal-318020-05`, VDC init table at `$E2F8`) for the
> VDC side.

## 1. MC6847 Mode Control

The MC6847 is controlled by 8 input pins that determine the display mode:

| Pin | Function | Description |
|-----|----------|-------------|
| AG  | Alphanumeric/Graphics | 0 = Alpha/Semigraphics, 1 = Graphics |
| AS  | Alpha/Semigraphics | 0 = Alphanumeric, 1 = Semigraphics (only when AG=0) |
| INT/EXT | Internal/External Character ROM | 0 = Internal 5x7 font, 1 = External character ROM |
| GM0, GM1, GM2 | Graphics Mode Select | 3-bit mode selector (only when AG=1) |
| CSS | Color Set Select | Selects alternate color palette |
| INV | Invert | Inverts alphanumeric characters |

## 2. MC6847 Display Modes (Standard)

### 2.1 Alphanumeric Modes (AG=0, AS=0)

| Mode | INT/EXT | Resolution (chars) | Char Size | Colors | Notes |
|------|---------|-------------------|-----------|--------|-------|
| Internal Alpha | 0 | 32×16 | 8×12 | 2 | Green/Orange on dark background, or inverted |
| Internal Alpha Inverted | 0 + INV | 32×16 | 8×12 | 2 | Inverse video |
| External Alpha | 1 | 32×16 | 8×12 | 2 | Uses external character ROM |
| External Alpha Inverted | 1 + INV | 32×16 | 8×12 | 2 | Inverse video with external ROM |

**Screen Memory:** 512 bytes (32×16 = 512 character cells). Each byte is a character code (0-255).

### 2.2 Semigraphics Modes (AG=0, AS=1)

| Mode | INT/EXT | Resolution (pixels) | Effective Grid | Colors | Bytes |
|------|---------|--------------------|----------------|--------|-------|
| SG4 (Semigraphics 4) | 0 | 64×32 | 2×2 blocks per char cell | 8+black | 512 |
| SG6 (Semigraphics 6) | 1 | 64×48 | 2×3 blocks per char cell | 8+black (or 4-color sets) | 512 |

### 2.3 Graphics Modes (AG=1)

| GM2 | GM1 | GM0 | Mode Name | Resolution (pixels) | Colors | Bytes/Screen | Row Height |
|-----|-----|-----|-----------|--------------------|--------|--------------|------------|
| 0   | 0   | 0   | CG1 (Color Graphics 1) | 64×64 | 4 | 1024 | 3 lines/row |
| 0   | 0   | 1   | RG1 (Resolution Graphics 1) | 128×64 | 2 (mono) | 1024 | 3 lines/row |
| 0   | 1   | 0   | CG2 (Color Graphics 2) | 128×64 | 4 | 2048 | 3 lines/row |
| 0   | 1   | 1   | RG2 (Resolution Graphics 2) | 128×96 | 2 | 1536 | 2 lines/row |
| 1   | 0   | 0   | CG3 (Color Graphics 3) | 128×96 | 4 | 3072 | 2 lines/row |
| 1   | 0   | 1   | RG3 (Resolution Graphics 3) | 128×192 | 2 | 1536 | 1 line/row |
| 1   | 1   | 0   | CG6 (Color Graphics 6) | 128×192 | 4 | 6144 | 1 line/row |
| 1   | 1   | 1   | RG6 (Resolution Graphics 6) | 256×192 | 2 | 6144 | 1 line/row |

**CSS Pin:** When set, selects alternate color set (Green/Yellow/Blue/Red vs Buff/Cyan/Magenta/Orange in graphics modes).

## 3. VZ200 Mode Mapping

The VZ200 computer maps MC6847 modes via its video mode register (typically at I/O port $68 / 104 decimal). Common VZ200 mode numbers:

| VZ200 Mode | MC6847 Configuration | Description | Resolution |
|------------|---------------------|-------------|------------|
| Mode 0 | AG=0,AS=0,INT/EXT=0 | Internal Text | 32×16 characters |
| Mode 1 | AG=0,AS=1,INT/EXT=0 | Semigraphics 4 | 64×32 blocks |
| Mode 2 | AG=1, GM=001 (RG1) | Resolution Graphics 1 | 128×64 |
| Mode 3 | AG=1, GM=011 (RG2) | Resolution Graphics 2 | 128×96 |
| Mode 4 | AG=1, GM=101 (RG3) | Resolution Graphics 3 | 128×192 |
| Mode 5 | AG=1, GM=111 (RG6) | Resolution Graphics 6 | 256×192 |
| Mode 6 | AG=1, GM=000 (CG1) | Color Graphics 1 | 64×64 (4-color) |
| Mode 7 | AG=1, GM=010 (CG2) | Color Graphics 2 | 128×64 (4-color) |
| Mode 8 | AG=1, GM=100 (CG3) | Color Graphics 3 | 128×96 (4-color) |
| Mode 9 | AG=1, GM=110 (CG6) | Color Graphics 6 | 128×192 (4-color) |

*Note: SG6 (64×48) requires INT/EXT=1 and is less commonly used on stock VZ200.*

## 4. 8563 VDC (C128) Capabilities vs MC6847

The 8563 VDC is fundamentally different from the MC6847:

| Feature | MC6847 (VDG) | 8563 VDC (C128) |
|---------|--------------|-----------------|
| Type | Character+Bitmap generator with fixed modes | Programmable display controller |
| Max Resolution | 256×192 (2-color), 128×192 (4-color) | Up to ~640×200 mono, 320×200 4-color (R0/R1/R6/R7 configurable) |
| Colors | Fixed palette (NTSC) | 16 colours; foreground/background from R26, or per-cell attributes |
| Text | 32×16 fixed cells | Fully programmable (rows/cols, 8×8 or 8×16 chars) |
| Memory | Directly fetches from CPU address space | Has its own 16KB/64KB video RAM, accessed via registers |
| Sync | Generates NTSC composite sync directly | Generates separate H/V sync, needs external encoder |

**Key Point:** The 8563 cannot directly replicate 6847's NTSC-specific analog
colour generation or its exact fetch timing. However, it can reproduce the
*geometric resolutions and bit layouts* of 6847 modes through register programming
and a matching memory organisation.

## 5. Mapping the MC6847 onto the 8563 VDC

### 5.1 8563 VDC register map (confirmed)

| Reg | Name | Function |
|-----|------|----------|
| R0  | HT   | Horizontal total, in characters, minus 1 |
| R1  | HD   | Horizontal displayed (visible characters per row) |
| R2  | HP   | Horizontal sync position |
| R3  | VW/HW| Vertical/Horizontal sync width |
| R4  | VT   | Vertical total, in character rows, minus 1 |
| R5  | VA   | Vertical total fine adjust (extra scan lines) |
| R6  | VD   | Vertical displayed (visible character rows) |
| R7  | VP   | Vertical sync position |
| R8  | IM   | Interlace mode, plus 0/1 scan-line delay |
| R9  | CTV  | Scan lines per character row (0-31); `< 16` selects 16 bytes/char |
| R10 | CM/CS| Cursor mode and start scan line |
| R11 | CE   | Cursor end scan line |
| R12 | -    | Display start address, high byte |
| R13 | -    | Display start address, low byte |
| R14 | -    | Cursor position, high byte |
| R15 | -    | Cursor position, low byte |
| R16 | -    | Light pen position, high byte (read only) |
| R17 | -    | Light pen position, low byte (read only) |
| R18 | -    | Update (memory) address, high byte |
| R19 | -    | Update (memory) address, low byte |
| R20 | -    | Attribute start address, high byte |
| R21 | -    | Attribute start address, low byte |
| R22 | -    | Character width: high nibble = width-1, low nibble = horizontal gap |
| R23 | CDV  | Vertical character pixel spacing |
| R24 | VSS  | Vertical smooth scroll; bit 6 = reverse screen |
| R25 | -    | bit 7 bitmap, bit 6 attributes on, bit 5 semigraphics, bit 4 double-pixel (40-col), bits 3-0 horizontal smooth scroll |
| R26 | -    | High nibble = foreground colour, low nibble = background colour (C128 colour index 0-15) |
| R27 | AI   | Additional address increment per character row |
| R28 | CB   | Character set base: bits 7-5 are A15-A13 of the character generator address |
| R29 | UL   | Underline scan line |
| R30 | WC   | Word count; writing it starts a block fill/copy |
| R31 | -    | Data port for VDC RAM access (auto-increments R18/R19) |

### 5.2 VDC memory access

* The VDC has its own 16KB or 64KB of RAM that is **not** part of the CPU address
  space. It is reached through the update address (R18/R19) and the data port
  (R31).
* Write the address to R18 (high) and R19 (low), then read or write R31. Every
  R31 access automatically increments R18/R19, so consecutive bytes are
  transferred without touching the address registers again.
* Writing R30 (word count) triggers a hardware fill/copy using R31 and R32/R33.

### 5.3 Character cell format

* A character uses **16 bytes** when R9 < 16 (8 rows of pixel data followed by 8
  bytes of padding), and 32 bytes when R9 >= 16 (16 rows + padding). Data row 0
  comes first.
* Bit order is MSB first: bit 7 is the **left-most** pixel of the cell. This is
  identical to the VIC-II character set, so dumped VIC-II/VDC fonts are directly
  interchangeable.
* The character generator base address is `(R28 & 0xE0) << 8`. With R28 = `$20`
  the character set lives at VDC `$2000` (the same place the C128 KERNAL keeps its
  80-column set).

### 5.4 Screen row stride

* After every character row the VDC advances the screen pointer by
  **`R1 (horizontal displayed) + R27`**. R27 is an *additional* increment, not an
  absolute stride.
* The C128 KERNAL VDC init table (in `kernal-318020-05` at `$E2F8`) programs
  `R1 = 80`, `R27 = 0`, i.e. contiguous 80-byte rows.
* Consequence: to get N-byte rows, set `R1 = N` and **leave `R27 = 0`**. If R27 is
  set to N as well you get a 2N-byte stride and only every second row is used.

## 6. Implemented mode: MC6847 alphanumeric text

`vdg6847_final2.asm` implements the MC6847 internal alphanumeric mode (32×16 cells
of 8×8 pixels → a 256×128 window) on the VDC. Register settings:

| Register | Value | Meaning |
|----------|-------|---------|
| R1 (HD)  | `$20` (32) | 32 characters wide |
| R6 (VD)  | `$10` (16) | 16 character rows |
| R10 (CM) | `$20`      | cursor off |
| R12/R13  | `$0000`    | display starts at VDC `$0000` |
| R25      | `$00`      | text mode, attributes off (one byte per cell, colours from R26) |
| R26      | `$54`      | foreground 5 = light green, background 4 = green |
| R27 (AI) | `$00`      | row stride = R1 = 32 bytes |

Registers left at the KERNAL 80-column defaults, which are compatible with this
mode:

| Register | Default | Meaning |
|----------|---------|---------|
| R22      | `$78`   | character width-1 = 7 → 8 pixels wide |
| R9       | `$07`   | 8 scan lines per row (`< 16` → 16 bytes/char) |
| R28      | `$20`   | character set at VDC `$2000` |

VDC RAM layout used:

| Address | Size | Contents |
|---------|------|----------|
| `$0000` | 512  | screen matrix: 16 rows × 32 character codes |
| `$2000` | 1024 | character set: 64 glyphs × 16 bytes |

The character set is the **real MC6847 internal character ROM** (as dumped for
MAME's `ntsc_square_fontdata8x12`). Each glyph is 5×7 pixels inside an 8×12 cell;
rows 3..9 are copied and the 5 pixels (bits 5..1) are centred into the 8-pixel VDC
cell with `(g & 0x3E) << 1`.

### 6.1 Extending to the graphics mode

Because the MC6847 alphanumeric cell is 8×12 and the VDC cell here is 8×8, the
VDC cell is one row short. For a pixel-exact 6847 picture use R9 = 11 (12 scan
lines) and supply 16-row glyphs, or emulate the 6847's semi-graphics/graphics
modes directly with the VDC bitmap mode:

* **RG6 (256×192, 2-colour):** R1 = 32, R6 = 24, R9 = 7, R25 bit 7 = 1 (bitmap),
  monochrome. 32×24 cells × 8 bytes = 6144 bytes, matching RG6 exactly.
* **CG6 (128×192, 4-colour):** R1 = 16, R6 = 24, R9 = 7, bitmap mode with the
  VDC's paired 2-bit-attribute bitmap layout; 128×192 pixels.

These are layout starting points; aspect ratio and colour need tuning (see §8).

## 7. Verification

The program was assembled with vasm (`vasm6502_oldstyle -Fbin`) and executed in
VICE 3.10 (`x128`). The live VDC state was read back through a monitor-injected
routine that copies the 8563 registers and RAM into main RAM:

* Registers: R1=`$20`, R6=`$10`, R25=`$00`, R26=`$54`, **R27=`$00`**, R28=`$20`,
  R10=`$20`, R12/R13=`$0000` — exactly as programmed.
* VDC `$0000` held the 32×16 screen matrix (`0d 03 36 38 34 37 20 …` →
  "MC6847 VDG MODE…").
* VDC `$2000` held the uploaded 6847 character set (`38 44 04 34 54 54 38 …` →
  the `@` glyph).
* Rendering those two buffers with the confirmed VDC rules (stride = R1 + R27,
  MSB-left, 16 bytes/char) produces a legible MC6847 text screen.

Note: VICE's VDC snapshot module is a stub ("VDC snapshots are not implemented"),
so a machine snapshot does **not** contain the VDC state; the read-back routine
above was required instead.

## 8. Implementation Notes

* **Colour translation:** the MC6847's palette (green/yellow/blue/red/buff/cyan/
  magenta/orange plus dark variants) maps to the C128's 16-colour index used in
  R26 / attribute bytes. The MC6847 alphanumeric colours chosen here are light
  green (5) on green (4).
* **Aspect ratio:** NTSC 6847 modes have non-square pixels. Exact timing would
  require reprogramming the VDC's horizontal total (R0) and sync registers rather
  than keeping the 80-column KERNAL defaults.
* **Memory banking:** VDC RAM is separate from main memory; all mode data must be
  written via R18/R19 and R31.
* **Speed:** VDC access is slower than direct memory fetches; software that changes
  the screen every frame must account for this.

## 9. References

- vz200.org - VZ200/VZ300 Hardware Documentation
- Motorola MC6847 Video Display Generator Datasheet
- Commodore 128 Programmer's Reference Guide - 8563 VDC
- MOS 8563/8568 VDC datasheet
- VICE emulator sources: `src/vdc/vdc.c`, `src/vdc/vdc-mem.c`, `src/vdc/vdc-color.c`
- C128 KERNAL ROM `kernal-318020-05` (VDC init table at `$E2F8`)
- Wikipedia: Motorola 6847
