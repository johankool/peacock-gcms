//
//  PKDocumentController.m
//  Peacock
//
//  Created by Johan Kool on 10/9/07.
//  Copyright 2007 Johan Kool. All rights reserved.
//

#import "PKDocumentController.h"


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
}

- (void)removeDocument:(NSDocument *)document
{
    NSLog(@"Document removed %@", [document description]);

}
@end
