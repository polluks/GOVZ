; VDG 6847 video mode emulation for Commodore 128 VDC (MOS Technology 8563/8568)
; This program configures the VDC to display a 32x16 character grid (each cell 8x8 pixels)
; with a custom character set that includes:
;   - 64 standard text characters (uppercase ASCII/graphics)
;   - 16 custom 2x2 graphics shapes (scaled to 4x4 pixels per cell)
; It then fills the screen with a test pattern showing all 16 shapes in different colors.
; Assemble with: vasm6502_oldstyle -Fbin -o vdg6847_final2.bin vdg6847_final2.asm
; Then convert to .prg: printf '\x00\x10' | cat - vdg6847_final2.bin > vdg6847.prg

        org $1000

        ; ===== Equates for VDC registers =====
VDC_REG   = $d600    ; VDC register select (write only)
VDC_DATA  = $d601    ; VDC data register (read/write)

        ; ===== VDC Register Numbers (0-36) =====
REG_HT    = $00      ; Horizontal Total
REG_HD    = $01      ; Horizontal Displayed
REG_HP    = $02      ; Horizontal Sync Position
REG_VHW   = $03      ; Vertical/Horizontal Sync Width
REG_VT    = $04      ; Vertical Total
REG_VA    = $05      ; Vertical Adjust
REG_VD    = $06      ; Vertical Displayed
REG_VP    = $07      ; Vertical Sync Position
REG_IM    = $08      ; Interlace Mode
REG_CT    = $09      ; Character Total Vertical
REG_CS    = $0a      ; Cursor Mode, Start Scan
REG_CE    = $0b      ; Cursor End Scan Line
REG_DSH   = $0c      ; Display Start Address High Byte
REG_DSL   = $0d      ; Display Start Address Low Byte
REG_CPH   = $0e      ; Cursor Position High Byte
REG_CPL   = $0f      ; Cursor Position Low Byte
REG_LPV   = $10      ; Light Pen Vertical Position
REG_LPH   = $11      ; Light Pen Horizontal Position
REG_UAH   = $12      ; Update Address High Byte
REG_UAL   = $13      ; Update Address Low Byte
REG_AAH   = $14      ; Attribute Start Address High Byte
REG_AAL   = $15      ; Attribute Start Address Low Byte
REG_CTH   = $16      ; Character Total Horizontal
REG_CDH   = $16      ; Character Display Horizontal (same address)
REG_CDV   = $17      ; Character Display Vertical
REG_VSS   = $18      ; Vertical Smooth Scrolling
REG_HSS   = $19      ; Horizontal Smooth Scrolling
REG_FGBG  = $1a      ; Foreground/Background color
REG_AI    = $1b      ; Address Increment per Row
REG_CBA   = $1c      ; Character Base Address
REG_UL    = $1d      ; Underline Scan Line
REG_WC    = $1e      ; Word Count
REG_DR    = $1f      ; Data Register
REG_BSH   = $20      ; Block Start Address High Byte
REG_BSL   = $21      ; Block Start Address Low Byte
REG_DEB   = $22      ; Display Enable Begin
REG_DEE   = $23      ; Display Enable End
REG_DRR   = $24      ; DRAM Refresh Rate

        ; ===== Other constants =====
SCREEN_WIDTH_CHARS  = 32   ; Characters horizontally
SCREEN_HEIGHT_CHARS = 16   ; Characters vertically
CHAR_WIDTH_PIXELS   = 8    ; Pixels per character width
CHAR_HEIGHT_PIXELS  = 8    ; Pixels per character height
SCREEN_WIDTH_PIXELS = SCREEN_WIDTH_CHARS * CHAR_WIDTH_PIXELS
SCREEN_HEIGHT_PIXELS= SCREEN_HEIGHT_CHARS * CHAR_HEIGHT_PIXELS

        ; Character set layout in VDC RAM:
        ;   $0000-$03FF: Standard text characters (64 * 16 bytes)
        ;   $0400-$04FF: Graphics shapes (16 shapes * 16 bytes)
        ; Total: 1280 bytes ($0500)
CHARSET_BASE    = $2000    ; Base address of charset in VDC RAM
SCREEN_BASE     = $0000    ; Base address of screen memory in VDC RAM
ATTRIBUTE_BASE  = $0800    ; Base address of attribute memory in VDC RAM

        ; ===== Begin code =====
        sei                     ; Disable interrupts
        ldx #$ff
        txs                     ; Initialize stack pointer

        ; ===== Configure VDC registers for 32x16 cell display (8x8 pixels/cell) =====
        ; Horizontal Displayed = SCREEN_WIDTH_CHARS * CHAR_WIDTH_PIXELS = 256 ($0100)
        ldx #REG_HD
        stx VDC_REG
        lda #<SCREEN_WIDTH_PIXELS
        sta VDC_DATA            ; Low byte
        lda #>SCREEN_WIDTH_PIXELS
        sta VDC_DATA            ; High byte

        ; Vertical Displayed = SCREEN_HEIGHT_CHARS * CHAR_HEIGHT_PIXELS = 128 ($0080)
        ldx #REG_VD
        stx VDC_REG
        lda #<SCREEN_HEIGHT_PIXELS
        sta VDC_DATA            ; Low byte
        lda #>SCREEN_HEIGHT_PIXELS
        sta VDC_DATA            ; High byte

        ; Character Display Horizontal = CHAR_WIDTH_PIXELS
        ldx #REG_CDH
        stx VDC_REG
        lda #CHAR_WIDTH_PIXELS
        sta VDC_DATA

        ; Character Display Vertical = CHAR_HEIGHT_PIXELS
        ldx #REG_CDV
        stx VDC_REG
        lda #CHAR_HEIGHT_PIXELS
        sta VDC_DATA

        ; Character Base Address = CHARSET_BASE in VDC RAM
        ; Register $1C: CB15-CB13 (bits7-5), RAM (bit4), bits3-0 unused.
        ; Setting RAM=1 and CB15-CB13=%000 places charset at $2000 (power-on default).
        ldx #REG_CBA
        stx VDC_REG
        lda #%00010000          ; %000 1 0000 -> CB15-CB13=000, RAM=1
        sta VDC_DATA

        ; Underline Scan Line = 0 (disable underlining)
        ldx #REG_UL
        stx VDC_REG
        lda #$00
        sta VDC_DATA

        ; Address Increment per Row = SCREEN_WIDTH_CHARS bytes (32 chars per row)
        ldx #REG_AI
        stx VDC_REG
        lda #SCREEN_WIDTH_CHARS
        sta VDC_DATA

        ; Display Start Address (screen memory) = SCREEN_BASE
        ldx #REG_DSH
        stx VDC_REG
        lda #<SCREEN_BASE
        sta VDC_DATA
        lda #>SCREEN_BASE
        sta VDC_DATA
        ldx #REG_DSL
        stx VDC_REG
        lda #<SCREEN_BASE
        sta VDC_DATA
        lda #>SCREEN_BASE
        sta VDC_DATA

        ; Attribute Start Address = ATTRIBUTE_BASE
        ldx #REG_AAH
        stx VDC_REG
        lda #<ATTRIBUTE_BASE
        sta VDC_DATA
        lda #>ATTRIBUTE_BASE
        sta VDC_DATA
        ldx #REG_AAL
        stx VDC_REG
        lda #<ATTRIBUTE_BASE
        sta VDC_DATA
        lda #>ATTRIBUTE_BASE
        sta VDC_DATA

        ; Default foreground/background color (white on black)
        ldx #REG_FGBG
        stx VDC_REG
        lda #$0f                ; %1111: FG=$F (white), BG=$0 (black)
        sta VDC_DATA

        ; ===== Copy custom character set to VDC RAM =====
        ; Assume charset data is placed in C128 RAM at label CHARSET (see end of file)
        ; We copy 1280 bytes (64 text*16 + 16 shapes*16) to VDC RAM at CHARSET_BASE.
        lda #<CHARSET
        sta $fb                 ; Pointer low byte
        lda #>CHARSET
        sta $fc                 ; Pointer high byte
        lda #<1280
        sta $fd                 ; Counter low byte
        lda #>1280
        sta $fe                 ; Counter high byte
copy_charset:
        ldy #$00
        lda ($fb),y             ; Load byte from C128 RAM
        ldx #REG_DR
        stx VDC_REG
        sta VDC_DATA            ; Write to VDC RAM (triggers write)
        iny
        inc $fb
        bne no_inc_fc
        inc $fc
no_inc_fc:
        dec $fd
        bne copy_charset
        dec $fe
        bne copy_charset

        ; ===== Initialize screen memory (fill with spaces) =====
        lda #<SCREEN_BASE
        sta $fb
        lda #>SCREEN_BASE
        sta $fc
        lda #<(SCREEN_WIDTH_CHARS * SCREEN_HEIGHT_CHARS * 2)  ; 2 bytes per cell (screen+attr) but we only clear screen here
        sta $fd
        lda #>(SCREEN_WIDTH_CHARS * SCREEN_HEIGHT_CHARS * 2)
        sta $fe
clear_screen:
        ldy #$00
        lda #$20                ; Space character code
        ldx #REG_DR
        stx VDC_REG
        sta VDC_DATA
        iny
        inc $fb
        bne no_inc2_fc
        inc $fc
no_inc2_fc:
        dec $fd
        bne clear_screen
        dec $fe
        bne clear_screen

        ; ===== Initialize attribute memory (default colors) =====
        lda #<ATTRIBUTE_BASE
        sta $fb
        lda #>ATTRIBUTE_BASE
        sta $fc
        lda #<(SCREEN_WIDTH_CHARS * SCREEN_HEIGHT_CHARS)
        sta $fd
        lda #>(SCREEN_WIDTH_CHARS * SCREEN_HEIGHT_CHARS)
        sta $fe
clear_attr:
        ldy #$00
        lda #$0f                ; White on black (same as default)
        ldx #REG_DR
        stx VDC_REG
        sta VDC_DATA
        iny
        inc $fb
        bne no_inc3_fc
        inc $fc
no_inc3_fc:
        dec $fd
        bne clear_attr
        dec $fe
        bne clear_attr

        ; ===== Draw test pattern: 16 shapes repeated across first row =====
        ; We'll fill the first 16 columns of the first row with shapes 0-15, each with a unique color.
        ldy #$00                ; Row index (0-15 for full screen, but we only do first row)
draw_row:
        ldx #$00                ; Column index (0-15)
draw_col:
        ; ----- Calculate screen memory offset: (row*SCREEN_WIDTH_CHARS + col) -----
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

        ldx #<SCREEN_BASE
        stx $fb
        lda #>SCREEN_BASE
        stx $fc
        txa
        clc
        adc #<SCREEN_BASE
        sta $fb
        lda #>SCREEN_BASE
        sta $fc
        ldx #REG_UAH
        stx VDC_REG
        lda #$00
        sta VDC_DATA            ; High byte of address (0 for <$0100)
        ldx #REG_UAL
        stx VDC_REG
        txa
        sta VDC_DATA            ; Low byte of address
        ldx #REG_DR
        stx VDC_REG
        tya
        sta VDC_DATA            ; Write character code

        ; ----- Write attribute byte (foreground color = column, background = green) -----
        ; Attribute memory base = ATTRIBUTE_BASE, same offset as screen memory
        ldx #<ATTRIBUTE_BASE
        stx $fb
        lda #>ATTRIBUTE_BASE
        stx $fc
        txa
        clc
        adc #<ATTRIBUTE_BASE
        sta $fb
        lda #>ATTRIBUTE_BASE
        sta $fc
        ldx #REG_UAH
        stx VDC_REG
        lda #$08
        sta VDC_DATA            ; High byte = $08
        ldx #REG_UAL
        stx VDC_REG
        txa
        sta VDC_DATA            ; Low byte = column offset
        ldx #REG_DR
        stx VDC_REG
        tya                     ; Foreground color = column (0-15)
        ora #$00                ; Background = 0 (green) -> attribute = FG<<4 | BG
        sta VDC_DATA

        inx
        cpx #SCREEN_WIDTH_CHARS ; 32 columns (but we only do first 16 for shapes)
        bne draw_col

        iny
        cpy #SCREEN_HEIGHT_CHARS ; 16 rows
        bne draw_row

        rts                     ; Return from subroutine

        ; ===== Character set data ==========
        ; Reserve 1280 bytes for the character set (64*16 + 16*16)
        ; This will be filled with zeros; replace with actual bitmap data as needed.
CHARSET:
        ds 1280
        end