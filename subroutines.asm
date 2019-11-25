; ReadControllers
; Ring counters are used to store controller button state in the address 'Controller<N>'
; Adapted from https://wiki.nesdev.com/w/index.php/Controller_Reading
.IF NUMBER_OF_PLAYERS!=0
  ReadControllers:
    ; Set the strobe bit to get controller status
    LDA #$01
    STA CONTROLLER_REGISTER_1
    .IF NUMBER_OF_PLAYERS==1
      STA Controller1
    .ELSE
      STA Controller2
    .ENDIF
    ; Clear the strobe bit to keep the controller status steady
    LSR a                       ; A is now 0
    STA CONTROLLER_REGISTER_1   ; Clear the strobe bit
  -                             ; Loop to read the controller status
    LDA CONTROLLER_REGISTER_1
    LSR a                       ; a[0] bit -> Carry
    ROL Controller1             ; Carry -> a[0] bit and a[7] bit -> Carry
    .IF NUMBER_OF_PLAYERS==2
      LDA CONTROLLER_REGISTER_2
      LSR a                     ; a[0] bit -> Carry
      ROL Controller2           ; Carry -> a[0] bit and a[7] bit -> Carry
    .ENDIF
    BCC -
    RTS
.ENDIF

