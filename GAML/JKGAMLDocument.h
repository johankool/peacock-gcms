//
//  JKGAMLDocument.h
//  Peacock
//
//  Created by Johan Kool on 6-10-06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class JKGAML;

@interface JKGAMLDocument : NSPersistentDocument {
    JKGAML *gaml;
    
    IBOutlet NSObjectController *gamlController;
    IBOutlet NSArrayController *experimentsController;
    IBOutlet NSArrayController *tracesController;
}

@end
