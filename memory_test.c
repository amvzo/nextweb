void test_dsp_memory() {
    uint24_t *dsp_ram = (uint24_t*)DSP_RAM_BASE;
    
    // Pattern test
    for(int i=0; i<1024; i++) {
        dsp_ram[i] = i & 0x00FFFF; // 24-bit pattern
    }
    
    // Verification
    int errors = 0;
    for(int i=0; i<1024; i++) {
        if(dsp_ram[i] != (i & 0x00FFFF)) {
            errors++;
            printf("Error at %04X: Wrote %06X Read %06X\n", 
                  i*3, i & 0x00FFFF, dsp_ram[i]);
        }
    }
    
    printf("Memory test complete. Errors: %d\n", errors);
}