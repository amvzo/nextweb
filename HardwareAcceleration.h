#define DSP_FALLBACK(module, task, ...) \
    if([[DSPManager sharedManager] supports##module] && ![DSPManager forceSoftwareRendering]) { \
        [self task##WithDSP:__VA_ARGS__]; \
    } else { \
        [self task##WithoutDSP:__VA_ARGS__]; \
    }

#define DSP_TRY_CATCH(module, task, ...) \
    @try { \
        DSP_FALLBACK(module, task, __VA_ARGS__) \
    } @catch (NSException *e) { \
        NSLog(@"DSP failed for %@, falling back: %@", @#task, e); \
        [self task##WithoutDSP:__VA_ARGS__]; \
        [[DSPManager sharedManager] markFeatureBroken:@#module]; \
    }