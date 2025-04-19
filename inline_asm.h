static inline void dsp_sync() {
    asm volatile (
        "move.l #0x8000, %%d0\n"
        "trap #15\n"           // NeXT-specific supervisor call
        "nop\n"
        ::: "d0"
    );
}

static inline uint24_t read_dsp_reg(uint32_t reg) {
    uint24_t value;
    asm volatile (
        "move.l %1, %%a0\n"
        "move.l (%%a0), %0\n"
        : "=r" (value)
        : "r" (DSP_BASE + reg)
        : "a0"
    );
    return value;
}