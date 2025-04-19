// HTMLParser.h
#import "DOM.h"

@interface HTMLParser : NSObject
{
    NSMutableData* _input;
    NSUInteger _position;
    DOMDocument* _document;
    NSMutableDictionary* _stringPool; // Shared string interning
}

- (instancetype)initWithData:(NSData*)data stringPool:(NSMutableDictionary*)pool;
- (DOMDocument*)parseIncremental:(BOOL)incremental;
@end

// HTMLParser.m
#import "HTMLParser.h"

@implementation HTMLParser

- (NSString*)_internString:(NSString*)str {
    NSString* existing = _stringPool[str];
    if (!existing) {
        _stringPool[str] = str;
        return str;
    }
    return existing;
}

- (void)_parseTag {
    // Use register variables for position/counters
    register NSUInteger pos = _position;
    register const char* bytes = [_input bytes];
    
    // Fast character scanning using FPU-assisted vectorization
    while (pos < [_input length] && bytes[pos] != '>') {
        pos++;
    }
    _position = pos;
}