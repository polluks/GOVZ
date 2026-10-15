 org $1000
  sei
  ldx #$ff
  txs
  ; ===== Configure VDC registers for 32x16 cell display (8x8 pixels/cell) =====
  ldx #$01
  stx $d600
  lda #$00
  sta $d601
  lda #$01
  sta $d601
  ldx #$06
  stx $d600
  lda #$80
  sta $d601
  lda #$00
  sta $d601
  ldx #$16
  stx $d600
  lda #$08
  sta $d601
  ldx #$17
  stx $d600
  lda #$08
  sta $d601
  ldx #$1c
  stx $d600
  lda #%00010000
  sta $d601
  ldx #$1d
  stx $d600
  lda #$00
  sta $d601
  ldx #$27
  stx $d600
  lda #$20
  sta $d601
  ldx #$0c
  stx $d600
  lda #$00
  sta $d601
  lda #$00
  sta $d601
  ldx #$0d
  stx $d600
  lda #$00
  sta $d601
  lda #$00
  sta $d601
  ldx #$14
  stx $d600
  lda #$00
  sta $d601
  lda #$08
  sta $d601
  ldx #$15
  stx $d600
  lda #$00
  sta $d601
  lda #$08
  sta $d601
  ldx #$1a
  stx $d600
  lda #$0f
  sta $d601
  ; ===== Copy custom character set to VDC RAM =====
  lda #<CHARSET
  sta $fb
  lda #>CHARSET
  sta $fc
  lda #<1280
  sta $fd
  lda #>1280
  sta $fe
cpy1_loop:
  ldy #$00
  lda ($fb),y
  ldx #$1f
  stx $d600
  sta $d601
  iny
  inc $fb
  bne no_inc1_fc
  inc $fc
no_inc1_fc:
  dec $fd
  bne cpy1_loop
  dec $fe
  bne cpy1_loop
  ; ===== Initialize screen memory (fill with spaces) =====
  lda #<$0000
  sta $fb
  lda #>$0000
  sta $fc
  lda #<$0800
  sta $fd
  lda #>$0800
  sta $fe
cls_loop:
  ldy #$00
  lda #$20
  ldx #$1f
  stx $d600
  sta $d601
  iny
  inc $fb
  bne no_inc2_fc
  inc $fc
no_inc2_fc:
  dec $fd
  bne cls_loop
  dec $fe
  bne cls_loop
  ; ===== Initialize attribute memory (default colors) =====
  lda #<$0800
  sta $fb
  lda #>$0800
  sta $fc
  lda #<$0800
  sta $fd
  lda #>$0800
  sta $fe
clattr_loop:
  ldy #$00
  lda #$0f
  ldx #$1f
  stx $d600
  sta $d601
  iny
  inc $fb
  bne no_inc3_fc
  inc $fc
no_inc3_fc:
  dec $fd
  bne clattr_loop
  dec $fe
  bne clattr_loop
  ; ===== Draw test pattern: 16 shapes repeated across first row =====
  ldy #$00
draw_row:
  ldx #$00
draw_col:
  tya
  asl a
  asl a
  asl a
  asl a
  asl a
  tay
  txa
  clc
  adc #$00
  tax
  tya
  and #$0f
  clc
  adc #$64
  tay
  ldx #$12
  stx $d600
  lda #$00
  sta $d601
  txa
  sta $d601
  ldx #$13
  stx $d600
  lda #$00
  sta $d601
  lda #$00
  sta $d601
  ldx #$1f
  stx $d600
  tya
  sta $d601
  ldx #$12
  stx $d600
  lda #$00
  sta $d601
  txa
  sta $d601
  ldx #$13
  stx $d600
  lda #$00
  sta $d601
  lda #$08
  sta $d601
  ldx #$1f
  stx $d600
  tya
  ora #$00
  sta $d601
  inx
  cpx #$10
  bne draw_col
  iny
  cpy #$10
  bne draw_row
  rts
CHARSET ds 1280
 end
