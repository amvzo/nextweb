#define FPU_ENABLED 1

#if FPU_ENABLED
    #define FPU_SAVE __asm__ volatile ("fmovem.l %/fp0-%/fp7,sp@-")
    #define FPU_RESTORE __asm__ volatile ("fmovem.l sp@+,%/fp0-%/fp7")
#else
    #define FPU_SAVE
    #define FPU_RESTORE
#endif