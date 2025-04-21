#import <Foundation/Foundation.h>

@interface JSValue : NSObject {
    id _value;
}
- (id)value;
- (void)setValue:(id)value;
@end

@interface JSObject : NSObject {
    NSMutableDictionary *_properties;
}
- (NSMutableDictionary *)properties;
@end
