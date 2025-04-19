// JSInterpreter.h
#import "JSTypes.h"

@interface JSInterpreter : NSObject
{
    JSHeap* _heap;
    JSValue* _globalObject;
    FPUContext* _fpuContext;
}

- (JSValue*)evaluateScript:(NSString*)script;
- (void)enableFPUOptimizations:(BOOL)enable;
@end

// JSInterpreter.m
#import "JSInterpreter.h"

@implementation JSInterpreter

- (JSValue*)_executeMathOperation:(JSOperation)op {
    if (_useFPU) {
        FPU_enable();
        double result = FPU_perform_operation(op);
        FPU_disable();
        return [JSValue numberWithDouble:result];
    }
    // Software fallback
}