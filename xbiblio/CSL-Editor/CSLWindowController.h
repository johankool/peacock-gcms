//
//  CSLWindowController.h
//  CSL Editor
//
//  Created by Johan Kool on 7-10-05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "AccessorMacros.h"

@interface CSLWindowController : NSWindowController {
	IBOutlet NSView *infoView;
	IBOutlet NSView *contentView;
	IBOutlet NSView *citationView;
	IBOutlet NSView *bibliographyView;	
	IBOutlet NSView *bibliographyOutlineView;	
}

#pragma mark NSTOOLBAR MANAGEMENT
-(IBAction)showInfo:(id)sender;
-(IBAction)showContent:(id)sender;
-(IBAction)showCitation:(id)sender;
-(IBAction)showBibliography:(id)sender;
-(void)setupToolbar;

@end
