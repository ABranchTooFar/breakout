; Constants

PRG_COUNT = 1       ; 1 = 16KB, 2 = 32KB
MIRRORING = %0001   ;%0000 = horizontal, %0001 = vertical, %1000 = four-screen

CONTROLLER_REGISTER_1 .EQU #$4016
CONTROLLER_REGISTER_2 .EQU #$4017

.INCLUDE "config.asm"


; Macros

.MACRO LatchNametable
; TODO: Comment this!
  LDA $2002
  LDA #$20
  STA $2006
  LDA #$00
  STA $2006
.ENDM

.MACRO LatchAttributeTable
; TODO: Comment this!
  LDA $2002
  LDA #$3F
  STA $2006
  LDA #$00
  STA $2006
.ENDM

.MACRO LatchPalette
; TODO: Comment this!
  LDA $2002
  LDA #$3F
  STA $2006
  LDA #$00
  STA $2006
.ENDM

.MACRO LoadPalette
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

PaddlePosition .DSB 1

.INCLUDE "variables.asm"

; TODO
; First bit is the new frame flag
Flags      .DSB 1

  ; TODO: find a work-around (it will cause issues with functions in the ball.asm file!)
  ; Include this file here so that the variables are in the correct location
  .INCLUDE "ball.asm"

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

.INCLUDE "subroutines.asm"

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

  ; Load the nametable
  LatchNametable

  ; Top row of blocks
  LDY #$40
  LDA #$47
-
  STA $2007
  DEY
  BNE -

  LDY #$1E
--
  ; Left wall background
  LDA #$47
  STA $2007
  LDA #$47
  STA $2007

  ; Sky background index
  LDX #$1C
-
  LDA #$24
  STA $2007
  DEX
  BNE -

  ; Right wall background
  LDA #$47
  STA $2007
  LDA #$47
  STA $2007

  DEY
  BNE --

  ; Load the attribute table


  ; Load the palettes
  LatchPalette

  ; Sprite palette(?)
  LoadPalette
  LoadPalette
  LoadPalette
  LoadPalette

  ; Background palette(?)
  LoadPalette
  LoadPalette
  LoadPalette
  LoadPalette

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


  InitBallSprite

  ; DEBUG
  ; Add a sprite-0 for testing
  LDA #$64
  STA $0200
  LDA #$08
  STA $0203

  ; Enable NMI, sprites from pattern table 0
  LDA #%10010000
  STA $2000

  ; No intensify, enable sprites
  LDA #%00011110
  STA $2001

  InitBallVariables


MainLoop:
  ; TODO
  ; Check for "new frame" flag and update game logic
  LDA #%00000001
  BIT Flags
  BEQ MainLoop
  ; If there is a "new frame"

  ; Set the scroll registers to zero
  LDA #$00
  STA $2005
  STA $2005

  BallCheckCollisions

  LDA BallAnimationTimer
  CMP #$08
  BNE +
  LDA #$64
  STA $0205
  ; Flip the sprites
  LDA $0206
  EOR #%11000000
  STA $0206
+
  CMP #$10
  BNE +
  LDA #$65
  STA $0205
  ; Reset the timer
  LDA #$00
  STA BallAnimationTimer
+
  LDA BallAnimationTimer
  CLC
  ADC #$01
  STA BallAnimationTimer

  ; Wait for the end of the h-blank???
  LDA #%01000000
-
  BIT $2002
  BNE -

  ; Wait for the sprite-0 hit
  LDA #%01000000
-
  BIT $2002
  BEQ -

  ; Set the scroll registers to zero
  ;LDA #$10
  LDA PaddlePosition
  STA $2005
  LDA #$00
  STA $2005

  ; TODO
  ; Make this more robust
  ; Reset the "new frame" flag
  LDA #%00000000
  STA Flags

  JMP MainLoop

NMI:
  ; vblank interrupt

  ; Read the controller input
  JSR ReadControllers

  LDA #%00000001
  BIT Controller1
  BEQ +
  LDA PaddlePosition
  CLC
  ADC #$01
  STA PaddlePosition
+

  ; Do the DMA transfer to the PPU
  LDA #$00
  STA $2003   ; Set the low byte of the RAM address
  LDA #$02
  STA $4014

  ; Set the "new frame" flag
  LDA #%00000001
  STA Flags

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
