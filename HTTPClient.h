#import <Foundation/Foundation.h>

@interface HTTPClient : NSObject {
}
- (void)GET:(NSString *)urlString completion:(void (^)(NSData *data, NSError *error))completion;
@end
