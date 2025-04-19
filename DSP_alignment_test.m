// alignment_test.m
DSPBuffer* buf = [[DSPBuffer alloc] initWithSize:1024];
NSAssert((uintptr_t)buf.bytes % 4 == 0, 
        @"Buffer not 32-bit aligned!");
[buf release];