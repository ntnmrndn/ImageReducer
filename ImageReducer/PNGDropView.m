//
//  PNGDropView.m
//  ImageReducer
//
//  Created by Jonas Gessner on 21.10.14.
//  Copyright (c) 2014 Jonas Gessner. All rights reserved.
//

#import "PNGDropView.h"

@implementation PNGDropView

- (instancetype)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
    if (self) {
        [self registerForDraggedTypes:@[NSFilenamesPboardType]];
    }
    return self;
}

- (NSDragOperation)draggingEntered:(id<NSDraggingInfo>)sender {
    NSArray *filePaths = [[sender draggingPasteboard] propertyListForType:NSFilenamesPboardType];
    BOOL anyFileValid = NO;
    for (NSString *path in filePaths) {
        if ([[path.pathExtension lowercaseString] isEqualToString:@"png"] || [[path.pathExtension lowercaseString] isEqualToString:@"jpg"]) {
            anyFileValid = YES;
            break;
        }
    }

    return (anyFileValid ? NSDragOperationCopy : NSDragOperationNone);
}


- (BOOL)performDragOperation:(id <NSDraggingInfo>)sender {
    NSArray *filePaths = [[sender draggingPasteboard] propertyListForType:NSFilenamesPboardType];
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"@(\\d)+x" options:NSRegularExpressionCaseInsensitive error:Nil];

    BOOL anyFileValid = NO;
    for (NSString *path in filePaths) {
        NSString *extension = [path.pathExtension lowercaseString];
        NSRange rangeOfLastPathComponent = NSMakeRange(path.length - path.lastPathComponent.length, path.lastPathComponent.length);
        if ([extension isEqualToString:@"png"] || [extension isEqualToString:@"jpg"]) {
            CGFloat scale = (CGFloat)[[[[path.pathComponents.lastObject stringByDeletingPathExtension] componentsSeparatedByString:@"@"] lastObject] integerValue];

            if (scale > 1) {
                NSImage *img = [[NSImage alloc] initWithContentsOfFile:path];
                CGSize naturalSize = img.size;

                for (NSUInteger i = 1; i < scale; i++) {
                    CGFloat screenScale = [[NSScreen mainScreen] backingScaleFactor];
                    NSString *newDensityString = i > 1 ? [NSString stringWithFormat:@"@%lux", (unsigned long)i] : @"";
                    NSString *newFilePath = [regex stringByReplacingMatchesInString:path options:0 range:rangeOfLastPathComponent withTemplate:newDensityString];
                    if ([[NSFileManager defaultManager] fileExistsAtPath:newFilePath]) {
                        continue;
                    }
                    NSSize newSize = (NSSize){(naturalSize.width*(CGFloat)i)/screenScale, (naturalSize.height*(CGFloat)i)/screenScale};
                    NSString *cmd = [NSString stringWithFormat:@"sips --resampleHeightWidth %lux %lux '%@' --out '%@'", (long)newSize.height, (long)newSize.width, path, newFilePath];
                    system(cmd.UTF8String);
                }
            }
        }
    }

    return anyFileValid;
}

@end
