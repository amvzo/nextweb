// Macro for DSP/CPU fallback
#define RUN_DSP_OR_CPU(cmd, data, fallback) \
    ([DSPManager.sharedManager dspAvailable] ? \
     [self cmd##WithDSP:data] : \
     [self fallback:data])