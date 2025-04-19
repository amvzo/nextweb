// In test suite
- (void)testInterruptResponse {
    uint64_t start = mach_absolute_time();
    [[DSPManager sharedManager] triggerTestInterrupt];
    uint64_t delta = mach_absolute_time() - start;
    XCTAssertLessThan(delta, 1000000, @"Interrupt response >1ms");
}