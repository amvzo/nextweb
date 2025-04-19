; timing_test.asm
    org     p:$100
    move    #0,r0
    nop
    do      #1000,delay_loop
    nop
delay_loop:
    rts