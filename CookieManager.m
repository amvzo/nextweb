// CookieManager.m
// This file implements the CookieManager class.

#import "CookieManager.h"

@implementation CookieManager

- (id)initWithFilePath:(NSString *)path {
    self = [super init];
    if (self) {
        filePath = [path copy];
        cookies = [[NSMutableDictionary alloc] init];
        [self loadCookies];
    }
    return self;
}

- (void)dealloc {
    [filePath release];
    [cookies release];
    [super dealloc];
}

- (void)loadCookies {
    NSData *fileData = [NSData dataWithContentsOfFile:filePath];
    if (fileData) {
        NSDictionary *storedCookies = [NSKeyedUnarchiver unarchiveObjectWithData:fileData];
        if (storedCookies) {
            [cookies removeAllObjects];
            [cookies addEntriesFromDictionary:storedCookies];
        }
    }
    NSMutableArray *keysToRemove = [NSMutableArray array];
    for (NSString *domain in cookies) {
        NSMutableDictionary *domainCookies = [cookies objectForKey:domain];
        for (NSString *name in [domainCookies allKeys]) {
            NSDictionary *cookie = [domainCookies objectForKey:name];
            NSDate *expires = [cookie objectForKey:@"expires"];
            if (expires && [expires compare:[NSDate date]] == NSOrderedAscending) {
                [keysToRemove addObject:name];
            }
        }
        for (NSString *name in keysToRemove) {
            [domainCookies removeObjectForKey:name];
        }
        [keysToRemove removeAllObjects];
    }
}

- (void)saveCookies {
    NSData *fileData = [NSKeyedArchiver archivedDataWithRootObject:cookies];
    [fileData writeToFile:filePath atomically:YES];
}

- (void)setCookieFromHeader:(NSString *)header forURL:(NSString *)url {
    NSArray *parts = [header componentsSeparatedByString:@";"];
    if ([parts count] == 0) return;
    
    NSString *nameValue = [[parts objectAtIndex:0] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    NSArray *nameValueParts = [nameValue componentsSeparatedByString:@"="];
    if ([nameValueParts count] != 2) return;
    NSString *name = [nameValueParts objectAtIndex:0];
    NSString *value = [nameValueParts objectAtIndex:1];
    
    NSMutableDictionary *cookie = [NSMutableDictionary dictionary];
    [cookie setObject:value forKey:@"value"];
    
    NSString *domain = nil;
    for (int i = 1; i < [parts count]; i++) {
        NSString *attribute = [[parts objectAtIndex:i] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        NSArray *attrParts = [attribute componentsSeparatedByString:@"="];
        if ([attrParts count] == 2) {
            NSString *attrName = [[attrParts objectAtIndex:0] lowercaseString];
            NSString *attrValue = [attrParts objectAtIndex:1];
            if ([attrName isEqualToString:@"expires"]) {
                NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
                [formatter setDateFormat:@"EEE, dd-MMM-yyyy HH:mm:ss 'GMT'"];
                [formatter setTimeZone:[NSTimeZone timeZoneWithAbbreviation:@"GMT"]];
                NSDate *expires = [formatter dateFromString:attrValue];
                if (expires) [cookie setObject:expires forKey:@"expires"];
                [formatter release];
            } else if ([attrName isEqualToString:@"domain"]) {
                domain = attrValue;
            } else if ([attrName isEqualToString:@"path"]) {
                [cookie setObject:attrValue forKey:@"path"];
            }
        }
    }
    
    if (!domain) {
        NSString *host = [[NSURL URLWithString:url] host];
        domain = host ? host : @"";
    }
    if (![domain hasPrefix:@"."]) domain = [@"." stringByAppendingString:domain];
    
    NSMutableDictionary *domainCookies = [cookies objectForKey:domain];
    if (!domainCookies) {
        domainCookies = [NSMutableDictionary dictionary];
        [cookies setObject:domainCookies forKey:domain];
    }
    [domainCookies setObject:cookie forKey:name];
    
    if ([domainCookies count] > 50) {
        NSArray *sortedKeys = [[domainCookies allKeys] sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
            NSDate *date1 = [domainCookies[obj1] objectForKey:@"expires"];
            NSDate *date2 = [domainCookies[obj2] objectForKey:@"expires"];
            return [date1 compare:date2];
        }];
        [domainCookies removeObjectForKey:[sortedKeys objectAtIndex:0]];
    }
    
    [self saveCookies];
}

- (NSString *)cookieHeaderForURL:(NSString *)url {
    NSMutableString *header = [NSMutableString string];
    NSString *host = [[NSURL URLWithString:url] host];
    NSString *path = [[NSURL URLWithString:url] path] ?: @"/";
    NSDate *now = [NSDate date];
    
    for (NSString *domain in cookies) {
        if ([host hasSuffix:domain] || [host isEqualToString:[domain substringFromIndex:1]]) {
            NSMutableDictionary *domainCookies = [cookies objectForKey:domain];
            for (NSString *name in domainCookies) {
                NSDictionary *cookie = [domainCookies objectForKey:name];
                NSDate *expires = [cookie objectForKey:@"expires"];
                NSString *cookiePath = [cookie objectForKey:@"path"] ?: @"/";
                if ((!expires || [expires compare:now] == NSOrderedDescending) && 
                    [path hasPrefix:cookiePath]) {
                    if ([header length] > 0) [header appendString:@"; "];
                    [header appendFormat:@"%@=%@", name, [cookie objectForKey:@"value"]];
                }
            }
        }
    }
    
    return [header length] > 0 ? header : nil;
}

@end