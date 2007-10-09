//
//  PKDocumentController.m
//  Peacock
//
//  Created by Johan Kool on 10/9/07.
//  Copyright 2007 Johan Kool. All rights reserved.
//

#import "PKDocumentController.h"
#import "JKGCMSDocument.h"

@implementation PKDocumentController
- (id) init {
    self = [super init];
    if (self != nil) {
        JKLogDebug(@"init");
    }
    return self;
}


- (void)addDocument:(NSDocument *)document
{
    NSLog(@"Document added %@", [document description]);
    if ([document isKindOfClass:[JKGCMSDocument class]]) {
        NSTabViewItem *newTabViewItem = [[NSTabViewItem alloc] initWithIdentifier:document];
        NSWindow *documentWindow = [[(JKGCMSDocument *)document mainWindowController] window];
        [newTabViewItem setView:[documentWindow contentView]];
        [newTabViewItem setLabel:[document displayName]];
        [documentTabView addTabViewItem:newTabViewItem];
        [documentTabView selectTabViewItemWithIdentifier:document];
     }
    [super addDocument:document];
    if ([document isKindOfClass:[JKGCMSDocument class]]) {
        NSWindow *documentWindow = [[(JKGCMSDocument *)document mainWindowController] window];
	   // [documentWindow orderWindow:NSWindowOut relativeTo:0];  
//        [documentWindow performSelector:@selector(orderOut:) withObject:self afterDelay:0.15];
    }
}

- (void)removeDocument:(NSDocument *)document
{
    NSLog(@"Document removed %@", [document description]);
    if ([document isKindOfClass:[JKGCMSDocument class]]) {
        [documentTabView removeTabViewItem:[documentTabView tabViewItemAtIndex:[documentTabView indexOfTabViewItemWithIdentifier:document]]];
    }
	[super removeDocument:document];
}

@end
