; Constants

PRG_COUNT = 1       ; 1 = 16KB, 2 = 32KB
MIRRORING = %0001   ;%0000 = horizontal, %0001 = vertical, %1000 = four-screen


; Macros

.MACRO latchPalette
; TODO: Comment this!
  LDA $2002
  LDA #$3F
  STA $2006
  LDA #$00
  STA $2006
  LDX #$00
.ENDM

.MACRO loadPalette
  LDA #$22
  STA $2007
  LDA #$16
  STA $2007
  LDA #$27
  STA $2007
  LDA #$18
  STA $2007
.ENDM


; Variables

.ENUM $0000

;NOTE: declare variables using the DSB and DSW directives, like this:

;MyVariable0 .dsb 1
;MyVariable1 .dsb 3

; TODO
; First bit is the new frame flag
Flags      .DSB 1

BallHSpeed .DSB 1
BallVSpeed .DSB 1

.ENDE

;NOTE: you can also split the variable declarations into individual pages, like this:

;.enum $0100
;.ende

;.enum $0200
;.ende


; iNES Header

.DB "NES", $1a      ; Identification of the iNES header
.DB PRG_COUNT       ; Number of 16KB PRG-ROM pages
.DB $01             ; Number of 8KB CHR-ROM pages
.DB $00|MIRRORING   ; Mapper 0 and mirroring
.DSB 9, $00         ; clear the remaining bytes


; Program Bank(s)

.BASE $10000-(PRG_COUNT*$4000)

Reset:
  ; Initialization code
  SEI        ; Disable IRQs
  CLD        ; Disable decimal mode
  LDX #$40
  STX $4017  ; Disable APU frame IRQ
  LDX #$FF
  TXS        ; Setup the stack
  INX        ; Now X = 0
  STX $2000  ; Disable NMI
  STX $2001  ; Disable rendering
  STX $4010  ; Disable DMC IRQs

  ; Wait for first vblank
-
  BIT $2002
  BPL -

  ; Clear the memory
-
  LDA #$00
  STA $0000, x
  STA $0100, x
  STA $0200, x
  STA $0400, x
  STA $0500, x
  STA $0600, x
  STA $0700, x
  LDA #$FE
  STA $0300, x
  INX
  BNE -

  ; Wait for second vblank
-
  BIT $2002
  BPL -

  ; PPU is ready now!

  ; Load the palettes
  latchPalette

  ; Sprite palette(?)
  loadPalette
  loadPalette
  loadPalette
  loadPalette

  ; Background palette(?)
  loadPalette
  loadPalette
  loadPalette
  loadPalette

  ; TODO
  ; Make this nicer
  ; Adds a fireball sprite to the screen
  LDA #$64
  STA $0200
  LDA #$65
  STA $0201
  LDA #$01
  STA $0202
  LDA #$64
  STA $0203

  ; Hide all unused sprites
  LDA #$FF
  LDX #$00
  ; Loop through all tiles except the first
HideTiles:
  ; x + 4 (might not be the best method)
  INX
  INX
  INX
  INX
  ; Place the tiles below the screen
  STA $0200, x
  ; Stop when x loops back to 0
  BNE HideTiles

  ; Enable NMI, sprites from pattern table 0
  LDA #%10000000
  STA $2000

  ; No intensify, enable sprites
  LDA #%00010110
  STA $2001

  ; Initiate variable values
  LDA #$01
  STA BallVSpeed

  LDA #$FF
  STA BallHSpeed


MainLoop:
  ; TODO
  ; Check for "new frame" flag and update game logic
  LDA #%00000001
  BIT Flags
  BEQ MainLoop
  ; If there is a "new frame"

  ; Ball collision with the sides of the screen
  ; Vertical
  LDA $0200
  ; Bounce off the top of the screen
  BNE +
  LDX #$01
  STX BallVSpeed
+
  ; Bounce off the bottom of the screen
  CMP #$E6
  BNE +
  LDX #$FF
  STX BallVSpeed
+
  ; Change ball y-position
  CLC
  ADC BallVSpeed
  STA $0200

  ; Horizontal
  LDA $0203
  ; Bounce off the left side of the screen
  BNE +
  LDX #$01
  STX BallHSpeed
+
  CMP #$F9
  BNE +
  LDX #$FF
  STX BallHSpeed
+
  ; Change ball x-position
  CLC
  ADC BallHSpeed
  STA $0203

  ; TODO
  ; Make this more robust
  ; Reset the "new frame" flag
  LDA #%00000000
  STA Flags

  JMP MainLoop

NMI:
  ; vblank interrupt

  ; Set the "new frame" flag
  LDA #%00000001
  STA Flags

  ; Do the DMA transfer to the PPU
  LDA #$00
  STA $2003   ; Set the low byte of the RAM address
  LDA #$02
  STA $4014

  RTI

IRQ:
  ; IRQ code goes here
  RTI

; Interrupt Vectors

.ORG $FFFA

.DW NMI
.DW Reset
.DW IRQ

; CHR-ROM Bank
.INCBIN "tiles.chr"
