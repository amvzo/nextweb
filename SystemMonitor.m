- (void)checkDSPHealth {
    static NSUInteger errorCount = 0;
    
    if(_lastDPSErrorTime && [NSDate timeIntervalSinceReferenceDate] - _lastDPSErrorTime < 1.0) {
        errorCount++;
    } else {
        errorCount = MAX(0, errorCount-1);
    }
    
    if(errorCount > 5) {
        NSLog(@"Disabling DSP due to error storm");
        [[DSPManager sharedManager] setEnabled:NO];
        [self triggerSoftwareFallbackAlert];
    }
}