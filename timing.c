#include <mach/mach_time.h>

#define DSP_CYCLE_NS 25 // 40MHz DSP = 25ns/cycle

void dsp_delay_cycles(uint32_t cycles) {
    uint64_t start = mach_absolute_time();
    uint64_t target_ns = cycles * DSP_CYCLE_NS;
    
    while(1) {
        uint64_t now = mach_absolute_time();
        if((now - start) >= target_ns) break;
        
        // Cycle-accurate NOP insertion
        asm volatile (
            "nop\n"
            "nop\n"
            "nop\n"
        );
    }
}

// Calibration function
void calibrate_delay() {
    uint64_t start = mach_absolute_time();
    dsp_delay_cycles(1000); // Delay for 1000 DSP cycles
    uint64_t actual_ns = mach_absolute_time() - start;
    
    printf("Calibration result: Target 25000ns, Actual %lluns\n", actual_ns);
}