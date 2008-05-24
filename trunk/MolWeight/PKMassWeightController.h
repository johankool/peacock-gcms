//
//  This file is part of the application with the working name:
//  Peacock
//
//  Created by Johan Kool.
//  Copyright (c) 2003-2004 Johan Kool. All rights reserved.
//

@interface PKMassWeightController : NSWindowController {
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

@property (retain) id lowerCase;
@property (retain) id panelWindow;
@property (retain) id formula;
@property (retain) id contents;
@property (retain) id statusIcon;
@property (retain) id weight;
@property (retain) id status;
@end
