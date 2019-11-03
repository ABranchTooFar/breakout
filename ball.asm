; This file will contain macros/methods for the ball object
; TODO: I'm not sure if this is a good code structure, but I'm going to try it

BallHSpeed .DSB 1
BallVSpeed .DSB 1
BallAnimationTimer .DSB 1

.MACRO InitBallVariables
  ; Initiate variable values
  LDA #$01
  STA BallVSpeed

  LDA #$FF
  STA BallHSpeed
.ENDM

.MACRO InitBallSprite
  ; TODO
  ; Move this to sprite 1 (because I will need sprite 0 for interrupt)
  ; Adds a fireball sprite to the screen
  LDA #$64
  STA $0200
  LDA #$65
  STA $0201
  LDA #$01
  STA $0202
  LDA #$64
  STA $0203
.ENDM

.MACRO BallCheckCollisions
  ; Ball collision with the sides of the screen
  ; Vertical
  LDA $0200
  ; Bounce off the top of the screen
  CMP #$0E
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
  CMP #$10
  BNE +
  LDX #$01
  STX BallHSpeed
+
  CMP #$E8
  BNE +
  LDX #$FF
  STX BallHSpeed
+
  ; Change ball x-position
  CLC
  ADC BallHSpeed
  STA $0203
.ENDM