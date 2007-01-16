//
//  JKGAMLDocument.m
//  Peacock
//
//  Created by Johan Kool on 6-10-06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import "JKGAMLDocument.h"
#import "JKGAML.h"

@implementation JKGAMLDocument

- (id)init {
    self = [super init];
    if (self != nil) {
        // initialization code
        gaml = [[JKGAML alloc] initWithEntity:[NSEntityDescription entityForName:@"JKGAML" inManagedObjectContext:[self managedObjectContext]] insertIntoManagedObjectContext:[self managedObjectContext]];
    }
    return self;
}

- (NSString *)windowNibName {
    return @"JKGAMLDocument";
}

- (void)windowControllerDidLoadNib:(NSWindowController *)windowController {
    [super windowControllerDidLoadNib:windowController];
    // user interface preparation code
//    [gamlController setContent:gaml];
}

@end
