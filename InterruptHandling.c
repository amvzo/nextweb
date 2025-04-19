// DSP interrupt handler (68040 side)
void dsp_interrupt_handler() {
    uint24_t status = read_dsp_reg(DSP_SR);
    
    if(status & 0x800000) { // Data ready
        [[DSPManager sharedManager] processInterrupt];
    }
    
    // Acknowledge interrupt
    write_dsp_reg(DSP_CR, 0x000001);
}