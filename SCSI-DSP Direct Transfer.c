// In SCSIDriver.m
- (void)directToDSP:(SCSIBlock)block {
    [self setupDMA:block.address];
    [[DSPManager sharedManager] sendCommand:DSP_CMD_MEMCPY_DMA 
                                  data:nil];
}