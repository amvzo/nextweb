// Ensure 24-bit alignment for DSP transfers
#define DSP_ALIGN __attribute__((aligned(4)))
uint24_t DSP_ALIGN dsp_buffer[1024];