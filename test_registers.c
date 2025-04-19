// test_registers.c
#include <dsp/driver.h>

int main() {
    dsp_write_reg(DSP_CR, 0x123456);
    uint24_t val = dsp_read_reg(DSP_CR);
    printf("CR Register: 0x%06X %s\n", 
          val,
          val == 0x123456 ? "[PASS]" : "[FAIL]");
    return 0;
}