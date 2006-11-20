//
//  This file is part of the application with the working name:
//  Peacock
//
//  Created by Johan Kool.
//  Copyright (c) 2003-2004 Johan Kool. All rights reserved.
//

@interface MWController : NSWindowController {
    IBOutlet id contents;
    IBOutlet id formula;
    IBOutlet id lowerCase;
    IBOutlet id status;
    IBOutlet id statusIcon;
    IBOutlet id weight;
    IBOutlet id panelWindow;
}
- (IBAction)calculate:(id)sender;
- (IBAction)clear:(id)sender;
- (void)showError:(BOOL)input;
- (IBAction)openPanel:(id)sender;

@end
