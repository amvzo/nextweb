- (void)createAccelerationPane {
    NSMatrix* accelerationMatrix = [[NSMatrix alloc] 
        initWithFrame:NSMakeRect(0,0,200,60)
        mode:NSRadioModeMatrix
        prototype:[NSButtonCell new]
        numberOfRows:2
        numberOfColumns:1];
    
    [accelerationMatrix addRowWithTitle:@"Automatic (DSP + CPU)"];
    [accelerationMatrix addRowWithTitle:@"Software Only"];
    
    [accelerationMatrix setTarget:self];
    [accelerationMatrix setAction:@selector(accelerationChanged:)];
}