#import <Foundation/Foundation.h>
@class DOMTree;

@interface CSSApplier : NSObject {
}
- (void)applyStyles:(NSDictionary *)styleMap toDOM:(DOMTree *)dom;
@end
