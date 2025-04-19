// ContentView.m
// This file implements the ContentView class, rendering HTML with expanded tags/CSS.

#import "ContentView.h"
#import "NetworkFetcher.h"

@implementation ContentView

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        currentURL = nil;
        htmlContent = nil;
        linkRects = [[NSMutableArray alloc] init];
        linkURLs = [[NSMutableArray alloc] init];
        images = [[NSMutableArray alloc] init];
        imageRects = [[NSMutableArray alloc] init];
        imageFetcher = nil;
        pendingImages = [[NSMutableDictionary alloc] init];
        imageCache = [[NSMutableDictionary alloc] init];
        imageCacheOrder = [[NSMutableArray alloc] init];
        imageCacheSize = 0;
        totalImages = 0;
        loadedImages = 0;
        contentSize = frame.size;
        totalBytesReceived = 0;
        totalContentLength = 0;
    }
    return self;
}

- (void)dealloc {
    [currentURL release];
    [htmlContent release];
    [linkRects release];
    [linkURLs release];
    [images release];
    [imageRects release];
    [imageFetcher release];
    [pendingImages release];
    [imageCache release];
    [imageCacheOrder release];
    [super dealloc];
}

- (void)renderURL:(NSString *)urlString {
    [currentURL release];
    currentURL = [urlString copy];
    totalImages = 0;
    loadedImages = 0;
    totalBytesReceived = 0;
    totalContentLength = 0;
    [pendingImages removeAllObjects];
    [self setNeedsDisplay:YES];
}

- (void)setHTMLContent:(NSString *)html {
    [htmlContent release];
    htmlContent = [html copy];
    totalImages = 0;
    loadedImages = 0;
    totalBytesReceived = 0;
    totalContentLength = 0;
    [pendingImages removeAllObjects];
    [self setNeedsDisplay:YES];
}

- (void)setImageFetcher:(NetworkFetcher *)fetcher {
    [imageFetcher release];
    imageFetcher = [fetcher retain];
    [imageFetcher fetchURL:nil];
}

- (NSString *)absoluteURLFromRelative:(NSString *)relativeURL {
    if ([relativeURL hasPrefix:@"http://"] || [relativeURL hasPrefix:@"https://"]) return relativeURL;
    NSRange lastSlash = [currentURL rangeOfString:@"/" options:NSBackwardsSearch];
    NSString *baseURL = (lastSlash.location != NSNotFound) ? [currentURL substringToIndex:lastSlash.location + 1] : currentURL;
    return [baseURL stringByAppendingString:relativeURL];
}

- (void)didReceiveData:(NSString *)data {
    [self setHTMLContent:data];
}

- (void)didFailWithError:(NSString *)error {
    [self setHTMLContent:[NSString stringWithFormat:@"Error: %@", error]];
}

- (void)didReceiveImageData:(NSData *)data forURL:(NSString *)url {
    NSImage *image = [[NSImage alloc] initWithData:data];
    if (image) {
        NSSize origSize = [image size];
        NSSize newSize = origSize;
        if (newSize.width > 200 || newSize.height > 200) {
            float scale = MIN(200.0 / newSize.width, 200.0 / newSize.height);
            newSize.width *= scale;
            newSize.height *= scale;
            [image setSize:newSize];
        }
        unsigned long imageSize = [data length];
        while (imageCacheSize + imageSize > 3 * 1024 * 1024 && [imageCacheOrder count] > 0) {
            NSString *oldestURL = [imageCacheOrder objectAtIndex:0];
            NSImage *oldImage = [imageCache objectForKey:oldestURL];
            imageCacheSize -= [[oldImage TIFFRepresentation] length];
            [imageCache removeObjectForKey:oldestURL];
            [imageCacheOrder removeObjectAtIndex:0];
        }
        [imageCache setObject:image forKey:url];
        [imageCacheOrder addObject:url];
        imageCacheSize += imageSize;
        
        NSDictionary *pendingInfo = [pendingImages objectForKey:url];
        if (pendingInfo) {
            NSRect rect = [[pendingInfo objectForKey:@"rect"] rectValue];
            rect.size = newSize;
            [images addObject:image];
            [imageRects addObject:[NSValue valueWithRect:rect]];
            [pendingImages removeObjectForKey:url];
            loadedImages++;
            [self setNeedsDisplayInRect:rect];
            [self setNeedsDisplayInRect:NSMakeRect(0, 0, 800, 20)];
        }
        [image release];
    }
}

- (void)didUpdateProgress:(float)progress forURL:(NSString *)url {
    NSDictionary *pendingInfo = [pendingImages objectForKey:url];
    if (pendingInfo) {
        NSMutableDictionary *newInfo = [NSMutableDictionary dictionaryWithDictionary:pendingInfo];
        [newInfo setObject:[NSNumber numberWithFloat:progress] forKey:@"progress"];
        [pendingImages setObject:newInfo forKey:url];
        NSRect rect = [[pendingInfo objectForKey:@"rect"] rectValue];
        [self setNeedsDisplayInRect:rect];
    }
}

- (void)didUpdateTotalProgress:(float)progress bytesReceived:(unsigned long)bytes totalBytes:(unsigned long)total {
    totalBytesReceived = bytes;
    totalContentLength = total;
    [self setNeedsDisplayInRect:NSMakeRect(0, 0, 800, 20)];
}

- (NSDictionary *)parseTag:(const char *)html index:(int *)i length:(int)len {
    int start = *i;
    while (*i < len && html[*i] != ' ' && html[*i] != '>') (*i)++;
    NSString *tagName = [NSString stringWithCString:&html[start] length:*i - start];
    NSMutableDictionary *attributes = [NSMutableDictionary dictionary];
    while (*i < len && html[*i] != '>') {
        while (*i < len && html[*i] == ' ') (*i)++;
        start = *i;
        while (*i < len && html[*i] != '=' && html[*i] != '>') (*i)++;
        NSString *attrName = [NSString stringWithCString:&html[start] length:*i - start];
        if (*i < len && html[*i] == '=') {
            (*i)++;
            if (*i < len && html[*i] == '"') {
                (*i)++;
                start = *i;
                while (*i < len && html[*i] != '"') (*i)++;
                NSString *attrValue = [NSString stringWithCString:&html[start] length:*i - start];
                [attributes setObject:attrValue forKey:attrName];
                (*i)++;
            }
        }
    }
    (*i)++;
    return @{@"tag": tagName, @"attributes": attributes};
}

- (NSDictionary *)parseStyle:(NSString *)styleString {
    NSMutableDictionary *styles = [NSMutableDictionary dictionary];
    NSArray *parts = [styleString componentsSeparatedByString:@";"];
    for (NSString *part in parts) {
        NSArray *keyValue = [part componentsSeparatedByString:@":"];
        if ([keyValue count] == 2) {
            NSString *key = [[keyValue objectAtIndex:0] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
            NSString *value = [[keyValue objectAtIndex:1] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
            [styles setObject:value forKey:key];
        }
    }
    return styles;
}

- (NSDictionary *)applyStyles:(NSDictionary *)currentAttrs styles:(NSDictionary *)styles {
    NSMutableDictionary *newAttrs = [NSMutableDictionary dictionaryWithDictionary:currentAttrs];
    for (NSString *key in styles) {
        NSString *value = [styles objectForKey:key];
        if ([key isEqualToString:@"color"]) {
            NSColor *color = nil;
            if ([value isEqualToString:@"red"]) color = [NSColor redColor];
            else if ([value isEqualToString:@"blue"]) color = [NSColor blueColor];
            else if ([value isEqualToString:@"black"]) color = [NSColor blackColor];
            if (color) [newAttrs setObject:color forKey:NSForegroundColorAttributeName];
        } else if ([key isEqualToString:@"font-size"]) {
            float size = [[value stringByTrimmingCharactersInSet:[NSCharacterSet letterCharacterSet]] floatValue];
            NSFont *font = [currentAttrs objectForKey:NSFontAttributeName];
            if (font) [newAttrs setObject:[NSFont fontWithName:[font fontName] size:size] forKey:NSFontAttributeName];
        } else if ([key isEqualToString:@"background-color"]) {
            NSColor *bgColor = nil;
            if ([value isEqualToString:@"yellow"]) bgColor = [NSColor yellowColor];
            else if ([value isEqualToString:@"green"]) bgColor = [NSColor greenColor];
            else if ([value isEqualToString:@"white"]) bgColor = [NSColor whiteColor];
            if (bgColor) [newAttrs setObject:bgColor forKey:@"backgroundColor"];
        } else if ([key isEqualToString:@"margin"]) {
            float margin = [value floatValue];
            [newAttrs setObject:@(margin) forKey:@"margin"];
        } else if ([key isEqualToString:@"padding"]) {
            float padding = [value floatValue];
            [newAttrs setObject:@(padding) forKey:@"padding"];
        } else if ([key isEqualToString:@"text-align"]) {
            [newAttrs setObject:value forKey:@"text-align"];
        }
    }
    return newAttrs;
}

- (void)drawRect:(NSRect)rect {
    [[NSColor whiteColor] set];
    NSRectFill(rect);
    
    if (htmlContent) {
        NSPoint drawPoint = NSMakePoint(10, self.bounds.size.height - 20);
        NSFont *font = [NSFont fontWithName:@"Helvetica" size:12];
        float lineHeight = 16.0;
        float cellWidth = 100.0;
        float cellHeight = 20.0;
        NSDictionary *normalAttrs = @{NSFontAttributeName: font, NSForegroundColorAttributeName: [NSColor blackColor]};
        NSMutableArray *attributeStack = [NSMutableArray arrayWithObject:normalAttrs];
        NSMutableArray *tagStack = [NSMutableArray array];
        
        const char *html = [htmlContent UTF8String];
        int i = 0, len = [htmlContent length];
        NSMutableString *text = [NSMutableString string];
        BOOL inTable = NO, inRow = NO;
        float tableX = 0, tableWidth = 0;
        float currentCellWidth = cellWidth;
        NSString *currentCellAlign = @"left";
        
        while (i < len) {
            if (html[i] == '<') {
                if (html[i+1] == '/') {
                    i += 2;
                    int start = i;
                    while (i < len && html[i] != '>') i++;
                    NSString *tagName = [NSString stringWithCString:&html[start] length:i - start];
                    if ([tagStack count] > 0 && [[tagStack lastObject] isEqualToString:tagName]) {
                        [tagStack removeLastObject];
                        [attributeStack removeLastObject];
                    }
                    if ([text length] > 0) {
                        NSDictionary *attrs = [attributeStack lastObject];
                        NSSize textSize = [text sizeWithAttributes:attrs];
                        float xPos = drawPoint.x;
                        float margin = [[attrs objectForKey:@"margin"] floatValue];
                        float padding = [[attrs objectForKey:@"padding"] floatValue];
                        NSString *textAlign = [attrs objectForKey:@"text-align"] ?: @"left";
                        xPos += margin + padding;
                        if ([tagName isEqualToString:@"td"]) {
                            if ([currentCellAlign isEqualToString:@"center"]) {
                                xPos += (currentCellWidth - textSize.width) / 2;
                            } else if ([currentCellAlign isEqualToString:@"right"]) {
                                xPos += currentCellWidth - textSize.width - 5;
                            }
                            NSColor *bgColor = [attrs objectForKey:@"backgroundColor"];
                            if (bgColor) {
                                [bgColor set];
                                NSRectFill(NSMakeRect(drawPoint.x, drawPoint.y, currentCellWidth, cellHeight));
                            }
                            currentCellWidth = cellWidth;
                            currentCellAlign = @"left";
                        } else if ([textAlign isEqualToString:@"center"]) {
                            xPos = (self.bounds.size.width - textSize.width) / 2;
                        } else if ([textAlign isEqualToString:@"right"]) {
                            xPos = self.bounds.size.width - textSize.width - margin - padding;
                        }
                        NSColor *bgColor = [attrs objectForKey:@"backgroundColor"];
                        if (bgColor) {
                            [bgColor set];
                            NSRectFill(NSMakeRect(drawPoint.x, drawPoint.y, textSize.width + 2 * padding, textSize.height));
                        }
                        [text drawAtPoint:NSMakePoint(xPos, drawPoint.y) withAttributes:attrs];
                        if ([tagName isEqualToString:@"p"] || [tagName isEqualToString:@"div"] || [tagName isEqualToString:@"tr"]) {
                            drawPoint.x = 10;
                            drawPoint.y -= lineHeight + margin + padding;
                        } else if ([tagName isEqualToString:@"td"]) {
                            drawPoint.x += currentCellWidth;
                        } else if ([tagName isEqualToString:@"span"] || [tagName isEqualToString:@"a"]) {
                            drawPoint.x += textSize.width + padding;
                        }
                        [text setString:@""];
                    }
                    if ([tagName isEqualToString:@"tr"]) {
                        inRow = NO;
                        drawPoint.x = tableX;
                        drawPoint.y -= cellHeight;
                    } else if ([tagName isEqualToString:@"table"]) {
                        inTable = NO;
                    }
                    i++;
                } else {
                    i++;
                    NSDictionary *tagInfo = [self parseTag:html index:&i length:len];
                    NSString *tagName = [tagInfo objectForKey:@"tag"];
                    NSDictionary *attributes = [tagInfo objectForKey:@"attributes"];
                    NSDictionary *currentAttrs = [attributeStack lastObject];
                    NSDictionary *styles = [self parseStyle:[attributes objectForKey:@"style"]];
                    NSDictionary *newAttrs = [self applyStyles:currentAttrs styles:styles];
                    if ([attributeStack count] < 100) {
                        [attributeStack addObject:newAttrs];
                        [tagStack addObject:tagName];
                    }
                    if ([tagName isEqualToString:@"p"] || [tagName isEqualToString:@"div"]) {
                        if ([text length] > 0) {
                            [text drawAtPoint:drawPoint withAttributes:currentAttrs];
                            drawPoint.x += [text sizeWithAttributes:currentAttrs].width;
                            [text setString:@""];
                        }
                        drawPoint.x = 10 + [[newAttrs objectForKey:@"margin"] floatValue] + [[newAttrs objectForKey:@"padding"] floatValue];
                        drawPoint.y -= lineHeight;
                    } else if ([tagName isEqualToString:@"table"]) {
                        inTable = YES;
                        tableX = drawPoint.x;
                        NSString *widthStr = [attributes objectForKey:@"width"];
                        if ([widthStr hasSuffix:@"%"]) {
                            tableWidth = ([widthStr intValue] / 100.0) * self.bounds.size.width;
                        } else {
                            tableWidth = [widthStr intValue];
                        }
                        cellWidth = tableWidth ? (tableWidth / 3) : cellWidth;
                    } else if ([tagName isEqualToString:@"tr"]) {
                        inRow = YES;
                        drawPoint.x = tableX;
                        drawPoint.y -= cellHeight;
                    } else if ([tagName isEqualToString:@"td"]) {
                        currentCellWidth = cellWidth;
                        currentCellAlign = [attributes objectForKey:@"align"] ?: @"left";
                        NSString *widthStr = [attributes objectForKey:@"width"];
                        if (widthStr) {
                            if ([widthStr hasSuffix:@"%"]) {
                                currentCellWidth = ([widthStr intValue] / 100.0) * tableWidth;
                            } else {
                                currentCellWidth = [widthStr intValue];
                            }
                        }
                    } else if ([tagName isEqualToString:@"a"]) {
                        NSString *href = [attributes objectForKey:@"href"];
                        if (href && [text length] > 0) {
                            [linkURLs addObject:[self absoluteURLFromRelative:href]];
                            [linkRects addObject:[NSValue valueWithRect:NSMakeRect(drawPoint.x, drawPoint.y, [text sizeWithAttributes:newAttrs].width, lineHeight)]];
                        }
                    } else if ([tagName isEqualToString:@"img"]) {
                        NSString *src = [attributes objectForKey:@"src"];
                        if (src) {
                            NSString *imgURL = [self absoluteURLFromRelative:src];
                            NSImage *cachedImage = [imageCache objectForKey:imgURL];
                            if (cachedImage) {
                                NSSize imgSize = [cachedImage size];
                                NSRect imgRect = NSMakeRect(drawPoint.x, drawPoint.y - imgSize.height, imgSize.width, imgSize.height);
                                [images addObject:cachedImage];
                                [imageRects addObject:[NSValue valueWithRect:imgRect]];
                                drawPoint.x += imgSize.width;
                            } else {
                                totalImages++;
                                NSRect placeholder = NSMakeRect(drawPoint.x, drawPoint.y - 50, 50, 50);
                                [pendingImages setObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:
                                                          [NSValue valueWithRect:placeholder], @"rect",
                                                          [NSNumber numberWithFloat:0.0], @"progress",
                                                          nil] forKey:imgURL];
                                [imageFetcher fetchURL:imgURL];
                                drawPoint.x += 50;
                            }
                        }
                    }
                }
            } else {
                if (html[i] == '\n' || html[i] == '\r') {
                    if ([text length] > 0) {
                        NSDictionary *attrs = [attributeStack lastObject];
                        float margin = [[attrs objectForKey:@"margin"] floatValue];
                        float padding = [[attrs objectForKey:@"padding"] floatValue];
                        NSSize textSize = [text sizeWithAttributes:attrs];
                        float xPos = drawPoint.x + margin + padding;
                        NSString *textAlign = [attrs objectForKey:@"text-align"] ?: @"left";
                        if ([textAlign isEqualToString:@"center"]) {
                            xPos = (self.bounds.size.width - textSize.width) / 2;
                        } else if ([textAlign isEqualToString:@"right"]) {
                            xPos = self.bounds.size.width - textSize.width - margin - padding;
                        }
                        [text drawAtPoint:NSMakePoint(xPos, drawPoint.y) withAttributes:attrs];
                        drawPoint.x = 10;
                        drawPoint.y -= lineHeight + margin + padding;
                        [text setString:@""];
                    }
                } else {
                    [text appendFormat:@"%c", html[i]];
                }
                i++;
            }
        }
        if ([text length] > 0) {
            NSDictionary *attrs = [attributeStack lastObject];
            float margin = [[attrs objectForKey:@"margin"] floatValue];
            float padding = [[attrs objectForKey:@"padding"] floatValue];
            NSSize textSize = [text sizeWithAttributes:attrs];
            float xPos = drawPoint.x + margin + padding;
            NSString *textAlign = [attrs objectForKey:@"text-align"] ?: @"left";
            if ([textAlign isEqualToString:@"center"]) {
                xPos = (self.bounds.size.width - textSize.width) / 2;
            } else if ([textAlign isEqualToString:@"right"]) {
                xPos = self.bounds.size.width - textSize.width - margin - padding;
            }
            [text drawAtPoint:NSMakePoint(xPos, drawPoint.y) withAttributes:attrs];
        }
        
        for (int j = 0; j < [images count]; j++) {
            NSImage *image = [images objectAtIndex:j];
            NSRect imgRect = [[imageRects objectAtIndex:j] rectValue];
            [image drawInRect:imgRect fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0];
        }
        
        NSEnumerator *enumerator = [pendingImages keyEnumerator];
        NSString *url;
        while ((url = [enumerator nextObject])) {
            NSDictionary *info = [pendingImages objectForKey:url];
            NSRect placeholder = [[info objectForKey:@"rect"] rectValue];
            float progress = [[info objectForKey:@"progress"] floatValue];
            [[NSColor grayColor] set];
            NSRectFill(placeholder);
            NSRect progressBar = NSMakeRect(placeholder.origin.x + 2, placeholder.origin.y + 2,
                                            (placeholder.size.width - 4) * progress, placeholder.size.height - 4);
            [[NSColor blueColor] set];
            NSRectFill(progressBar);
        }
    }
}

@end