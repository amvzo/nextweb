; test_matrix.asm
    org     p:$200
    move    #>0x123456,x0
    move    #>0x789ABC,y0
    mac     x0,y0,a
    move    a,x:(r1)