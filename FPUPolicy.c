- (void)scheduleFPUOperation:(FPUOp)op {
    if([FPUScheduler shouldPreempt]) {
        [NSThread yield];
    }
    [FPULock lock];
    FPU_execute(op);
    [FPULock unlock];
}