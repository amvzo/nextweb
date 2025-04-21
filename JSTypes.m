#import "JSTypes.h"

@implementation JSValue

- (id)value {
    return _value;
}

- (void)setValue:(id)value {
    [_value release];
    _value = [value retain];
}

- (void)dealloc {
    [_value release];
    [super dealloc];
}

@end

@implementation JSObject

- (id)init {
    if (self = [super init]) {
        _properties = [[NSMutableDictionary alloc] init];
    }
    return self;
}

- (NSMutableDictionary *)properties {
    return _properties;
}

- (void)dealloc {
    [_properties release];
    [super dealloc];
}

@end
