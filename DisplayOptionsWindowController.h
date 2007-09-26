//
//  DisplayOptionsWindowController.h
//  HebX
//
//  Created by Andreas on 27.08.05.
//  Copyright 2005 Andreas Mayer. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface DisplayOptionsWindowController : NSWindowController {
	IBOutlet NSMatrix *optionsMatrix;
	IBOutlet NSTextField *headingField;
	IBOutlet NSImageView *iconView;
	NSString *heading;
	NSImage *icon;
	id delegate;
	NSArray *options;
}

- (id)delegate;
- (void)setDelegate:(id)newDelegate;

- (NSArray *)options;
- (void)setOptions:(NSArray *)newOptions;

- (NSImage *)icon;
- (void)setIcon:(NSImage *)newIcon;

- (NSString *)heading;
- (void)setHeading:(NSString *)newHeading;


- (IBAction)ok:(id)sender;

- (IBAction)cancel:(id)sender;

- (IBAction)toggleOption:(id)sender;


@property (retain) NSImageView *iconView;
@property (retain) NSMatrix *optionsMatrix;
@property (retain) NSTextField *headingField;
@property (assign,getter=delegate,setter=setDelegate:) id delegate;
@end
