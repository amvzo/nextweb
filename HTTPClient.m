#import "HTTPClient.h"
#import <Foundation/NSURL.h>
#import <Foundation/NSData.h>
#import <Foundation/NSError.h>

@implementation HTTPClient

- (void)GET:(NSString *)urlString completion:(void (^)(NSData *data, NSError *error))completion {
    NSURL *url = [NSURL URLWithString:urlString];
    if (!url) {
        if (completion) {
            completion(nil, [NSError errorWithDomain:@"InvalidURL" code:400 userInfo:nil]);
        }
        return;
    }
    NSData *data = [NSData dataWithContentsOfURL:url];
    if (completion) {
        completion(data, nil);
    }
}

@end
