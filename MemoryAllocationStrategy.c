#define USE_FPU_RAM_POOL 1

void* malloc_fpu(size_t size) {
#if USE_FPU_RAM_POOL
    if(size <= 512) {
        return FPU_allocate(size); // Use FPU register pool
    }
#endif
    return malloc(size);
}