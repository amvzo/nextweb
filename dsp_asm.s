; Matrix multiplication for CSS transforms
    org     p:$100
css_matrix_mult:
    move    #>matrix_a,r0      ; Load matrix A address
    move    #>matrix_b,r4      ; Load matrix B address
    move    #>result,r1        ; Result matrix
    move    #15,m0             ; Modulo 16 addressing
    
    do      #4,outer_loop      ; 4x4 matrix
    clr     a                  ; Clear accumulator
    move    x:(r0)+,x0         ; Load A[row][0]
    move    y:(r4)+,y0         ; Load B[0][col]
    mac     x0,y0,a            ; Multiply and accumulate
    ...                        ; Repeat for all elements
outer_loop:
    move    a,x:(r1)+          ; Store result
    rts