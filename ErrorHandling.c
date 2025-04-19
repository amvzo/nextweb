- (void)handleDSPError:(NSInteger)code {
    if (code == DSP_ERR_OVERFLOW) {
        [self fallbackToSoftware];
        [[DSPManager sharedManager] reset];
    }
}