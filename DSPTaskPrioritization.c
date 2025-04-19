// In BrowserWindow.m
- (void)loadPriorityContent {
    [[DSPManager sharedManager] setTaskPriority:3]; // High priority
    [self decodeAboveTheFoldImages];
    [[DSPManager sharedManager] setTaskPriority:0]; // Reset
}