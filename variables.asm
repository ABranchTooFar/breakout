  .IF NUMBER_OF_PLAYERS!=0
    Controller1 .DSB 1
    .IF NUMBER_OF_PLAYERS>1
      Controller2 .DSB 1
    .ENDIF
    .IF NUMBER_OF_PLAYERS>2
      Controller3 .DSB 1
    .ENDIF
    .IF NUMBER_OF_PLAYERS>3
      Controller4 .DSB 1
    .ENDIF
  .ENDIF
