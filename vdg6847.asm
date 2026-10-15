; VDG 6847 video mode emulation for Commodore 128 VDC (MOS Technology 8563/8568)
; This program configures the VDC to display a 32x16 character grid (each cell 8x8 pixels)
; with a custom character set that includes:
;   - 64 standard text characters (uppercase ASCII/graphics)
;   - 16 custom 2x2 graphics shapes (scaled to 4x4 pixels per cell)
; It then fills the screen with a test pattern showing all 16 shapes in different colors.
; Assemble with: vasm6502_oldstyle -Fbin -o vdg6847.bin vdg6847.asm

        .org $1000
        sei                     ; Disable interrupts
        ldx #$ff
        txs                     ; Initialize stack pointer

        ; ===== Configure VDC registers for 32x16 cell display (8x8 pixels/cell) =====
        ; Horizontal Displayed = 32 chars * 8 pixels = 256 ($0100)
        ldx #$01
        stx $d600               ; VDC register select: $01 (Horizontal Displayed)
        lda #$00
        sta $d601               ; Low byte
        lda #$01
        sta $d601               ; High byte

        ; Vertical Displayed = 16 rows * 8 pixels = 128 ($0080)
        ldx #$06
        stx $d600               ; Register $06 (Vertical Displayed)
        lda #$80
        sta $d601               ; Low byte
        lda #$00
        sta $d601               ; High byte

        ; Character Display Horizontal = 8 pixels/char
        ldx #$16
        stx $d600               ; Register $16
        lda #$08
        sta $d601

        ; Character Display Vertical = 8 scanlines/char
        ldx #$17
        stx $d600               ; Register $17
        lda #$08
        sta $d601

        ; Character Base Address = $2000 in VDC RAM
        ; Register $1C: CB15-CB13 (bits7-5), RAM (bit4), bits3-0 unused.
        ; Setting RAM=1 and CB15-CB13=%000 places charset at $2000 (power-on default).
        ldx #$1c
        stx $d600
        lda #%00010000          ; %000 1 0000 -> CB15-CB13=000, RAM=1
        sta $d601

        ; Underline Scan Line = 0 (disable underlining)
        ldx #$1d
        stx $d600
        lda #$00
        sta $d601

        ; Address Increment per Row = 32 bytes (32 chars per row)
        ldx #$27
        stx $d600               ; Register $27
        lda #$20
        sta $d601

        ; Display Start Address (screen memory) = $0000
        ldx #$0c
        stx $d600               ; Register $0C (high byte)
        lda #$00
        sta $d601
        lda #$00
        sta $d601
        ldx #$0d
        stx $d600               ; Register $0D (low byte)
        lda #$00
        sta $d601
        lda #$00
        sta $d601

        ; Attribute Start Address = $0800
        ldx #$14
        stx $d600               ; Register $14 (high byte)
        lda #$00
        sta $d601
        lda #$08
        sta $d601
        ldx #$15
        stx $d600               ; Register $15 (low byte)
        lda #$00
        sta $d601
        lda #$08
        sta $d601

        ; Default foreground/background color (white on black)
        ldx #$1a
        stx $d600               ; Register $1A (Foreground/Background)
        lda #$0f                ; %1111: FG=$F (white), BG=$0 (black)
        sta $d601

        ; ===== Copy custom character set to VDC RAM =====
        ; Assume charset data is placed in C128 RAM at label CHARSET (see end of file)
        ; We copy 1280 bytes (64 text*16 + 16 shapes*16) to VDC RAM at $2000.
        ldx #$12
        stx $d600               ; Set update address high byte
        lda #$00
        sta $d601               ; Low byte = $00
        lda #$20
        sta $d601               ; High byte = $20  --> address $2000
        ldx #$13
        stx $d600
        lda #$00
        sta $d601
        lda #$20
        sta $d601

        ldy #$00                ; Index into charset data
copy_charset:
        lda CHARSET,y           ; Load byte from C128 RAM
        ldx #$1f
        stx $d600               ; Select data register ($1F)
        sta $d601               ; Write to VDC RAM (triggers write)
        iny
        cpy #$0500              ; 1280 decimal = $0500
        bne copy_charset

        ; ===== Initialize screen memory (fill with spaces) =====
        ldx #$12
        stx $d600
        lda #$00
        sta $d601
        lda #$00
        sta $d601               ; Address $0000
        ldx #$13
        stx $d600
        lda #$00
        sta $d601
        lda #$00
        sta $d601

        ldy #$00
clear_screen:
        lda #$20                ; Space character code
        ldx #$1f
        stx $d600
        sta $d601               ; Write to screen memory
        iny
        cpy #$0800              ; Clear 2KB (more than needed 512 bytes for 32x16)
        bne clear_screen

        ; ===== Initialize attribute memory (default colors) =====
        ldx #$14
        stx $d600
        lda #$00
        sta $d601
        lda #$08
        sta $d601               ; Address $0800
        ldx #$15
        stx $d600
        lda #$00
        sta $d601
        lda #$08
        sta $d601

        ldy #$00
clear_attr:
        lda #$0f                ; White on black (same as default)
        ldx #$1f
        stx $d600
        sta $d601
        iny
        cpy #$0800
        bne clear_attr

        ; ===== Draw test pattern: 16 shapes repeated across first row =====
        ldy #$00                ; Row index (0-15)
draw_row:
        ldx #$00                ; Column index (0-15)
draw_col:
        ; ----- Calculate screen memory offset: (row*32 + col) -----
        tya
        asl a                   ; *2
        asl a                   ; *4
        asl a                   ; *8
        asl a                   ; *16
        asl a                   ; *32
        tay                     ; Y = row*32
        txa
        clc
        adc #$00                ; Add column offset (0-15)
        tax                     ; X = offset in screen memory

        ; ----- Write character code (shape index) to screen memory -----
        ; Character set: 0-63 = text, 64-79 = shapes 0-15
        tya                     ; Reuse Y for column (0-15)
        and #$0f                ; Ensure 0-15
        clc
        adc #$64                ; Base code for shapes = $64
        tay                     ; Y = character code to write

        ldx #$12
        stx $d600               ; Set update address high byte
        lda #$00
        sta $d601               ; Low byte = $00
        txa
        sta $d601               ; Low byte = column offset (high byte still 0)
        ldx #$13
        stx $d600
        lda #$00
        sta $d601
        lda #$00
        sta $d601               ; High byte = 0

        ldx #$1f
        stx $d600               ; Select data register
        tya
        sta $d601               ; Write character code

        ; ----- Write attribute byte (foreground color = column, background = green) -----
        ; Attribute memory base = $0800, same offset as screen memory
        ldx #$12
        stx $d600
        lda #$00
        sta $d601
        txa
        sta $d601               ; Low byte = column offset
        ldx #$13
        stx $d600
        lda #$00
        sta $d601
        lda #$08
        sta $d601               ; High byte = $08 (attribute base)

        ldx #$1f
        stx $d600
        tya                     ; Foreground color = column (0-15)
        ora #$00                ; Background = 0 (green) -> attribute = FG<<4 | BG
        sta $d601

        inx
        cpx #$10                ; 16 columns
        bne draw_col

        iny
        cpy #$10                ; 16 rows
        bne draw_row

        rts                     ; Return from subroutine

        ; ===== Character set data =====
        ; Place this after the code; it will be copied to VDC RAM.
        ; First 64*16 = 1024 bytes: standard text characters (placeholder: all $00)
        ; Next 16*16 = 256 bytes: 16 shapes, each a 2x2 block scaled to 4x4.
        ; Each shape byte represents a row of 8 pixels (2 VDG pixels -> 4 VDC pixels).
        ; We define simple shapes: each shape has a single pixel in a different position.
        ; For brevity, we fill with zeros; replace with actual bitmap data as needed.
CHARSET:
        .repeat 1024, $00       ; Placeholder for text charset
        .repeat 256, $00        ; Placeholder for shapes (to be defined)
        ; Example shape definitions (uncomment and edit as needed):
        ; Shape 0: all off
        ; .byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        ; Shape 1: top-left pixel on (scaled to 2x2 block at top-left)
        ; .byte $f0,$f0,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        ; ... etc.
        .endr
.end