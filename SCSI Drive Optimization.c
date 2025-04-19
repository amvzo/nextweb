@interface SCSIDriver : NSObject
+ (void)optimizeForHTMLParsing;
+ (NSData*)readBlocking:(UInt32)block;
@end

// Prefetch parser tables during idle
[SCSIDriver prefetchBlocks:@[@512, @513, @514]];