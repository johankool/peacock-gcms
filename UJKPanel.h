//
//  UJKPanel.h
//  UJKPanel
//
//  Created by Uli Kusterer on Mon Jun 30 2003.
//  Copyright (c) 2003 M. Uli Kusterer. All rights reserved.
//

/*
	DIRECTIONS:
	
	UKPrefsPanel is stupidly simple to use: Create a tabless NSTabView, where the name
	of each tab is the name for the toolbar item, and the identifier of each tab is the
	identifier to be used for the toolbar item to represent it. Then create image files
	with the identifier as their names to be used as icons in the toolbar.
	
	Finally, drag UKPrefsPanel.h into the NIB with the NSTabView, instantiate a
	UKPrefsPanel and connect its tabView outlet to your NSTabView. When you open the
	window, the UKPrefsPanel will automatically add a toolbar to the window with all
	tabs represented by a toolbar item, and clicking an item will switch between the
	tab view's items.
*/

@interface UJKPanel : NSObject
{
	IBOutlet NSTabView*		tabView;		// From this view we pick up the window to change.
	NSMutableDictionary*	itemsList;		// Auto-generated from tab view's items.
	NSString*				baseWindowName;	// Auto-fetched at awakeFromNib time. We append a colon and the name of the current page to the actual window title.
}

// You don't have to care about these:
-(void)	setupToolbar;
-(IBAction)	changePanes: (id)sender;

@end
