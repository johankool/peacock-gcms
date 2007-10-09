//
//  PKDocumentController.h
//  Peacock
//
//  Created by Johan Kool on 10/9/07.
//  Copyright 2007 Johan Kool. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface PKDocumentController : NSDocumentController {
    IBOutlet NSWindow *window;
	IBOutlet NSTabView *documentTabView;
}

@end
