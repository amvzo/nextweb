- (void)markFeatureBroken:(NSString*)feature {
    static NSMutableSet* brokenFeatures;
    if(!brokenFeatures) brokenFeatures = [NSMutableSet new];
    
    [brokenFeatures addObject:feature];
    
    if([brokenFeatures count] > 2) {
        NSLog(@"Disabling DSP due to multiple failures");
        _dspEnabled = NO;
    }
}

- (BOOL)supportsJPEGAcceleration {
    return _dspEnabled && 
          ![_brokenFeatures containsObject:@"JPEGAcceleration"];
}