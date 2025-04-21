#import <Foundation/Foundation.h>

@interface CSSParser : NSObject {
}
- (NSDictionary *)parseCSS:(NSString *)cssString;
@end
