// Memory-mapped I/O operations
#define DSP_BASE 0xF1000000
volatile uint24_t* dsp_reg = (uint24_t*)DSP_BASE;

void dsp_init() {
    // Reset DSP
    dsp_reg[DSP_CR] = 0x800000; // Soft reset bit
    while(dsp_reg[DSP_CR] & 0x800000); // Wait for reset
    
    // Configure memory interface
    dsp_reg[DSP_STR] = 0x004000; // 24-bit addressing mode
    dsp_reg[DSP_OMR] = 0x00E000; // Operating mode
}

// Verify memory mapping
int verify_mapping() {
    const uint24_t test_pattern = 0x00ABCD;
    dsp_reg[DSP_TEST_REG] = test_pattern;
    return (dsp_reg[DSP_TEST_REG] == test_pattern) ? 0 : -1;
}