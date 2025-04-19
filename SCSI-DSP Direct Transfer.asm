; Transfer from SCSI to DSP memory
scsi_to_dsp:
    move.l  #SCSI_FIFO, a0
    move.l  #DSP_RAM, a1
    move.w  #2048, d0
.loop:
    move.b  (a0)+, (a1)+
    dbf     d0, .loop
    rts