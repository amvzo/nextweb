// main.m
#import <AppKit/AppKit.h>
#import "BrowserApp.h"

int main(int argc, char *argv[])
{
    id app;
    [NSApplication sharedApplication];
    app = [[BrowserApp alloc] init];
    [app run];
    [app release];
    return 0;
}