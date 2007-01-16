//
//  JKSynchroScrollView.m
//  Peacock
//
//  Created by Johan Kool on 10-3-06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import "JKSynchroScrollView.h"


@implementation JKSynchroScrollView

- (void)setSynchronizedScrollView1:(NSScrollView*)scrollview{
    NSView *synchronizedContentView;
	
    // stop an existing scroll view synchronizing
    [self stopSynchronizingWithView1];
	
    // Don't retain the watched view, because we assume that it will
    // be retained by the view hierarchy for as long as we're around.
    synchronizedScrollView1 = scrollview;
	
    // get the content view of the 
    synchronizedContentView=[synchronizedScrollView1 contentView];
	
    // Make sure the watched view is sending bounds changed
    // notifications (which is probably does anyway, but calling
    // this again won't hurt).
    [synchronizedContentView setPostsBoundsChangedNotifications:YES];
	
    // and register for those notifications on the synchronized content view.
    [[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(synchronizedViewContentBoundsDidChange:)
												 name:NSViewBoundsDidChangeNotification
											   object:synchronizedContentView];
}

- (void)setSynchronizedScrollView2:(NSScrollView*)scrollview{
    NSView *synchronizedContentView;
	
    // stop an existing scroll view synchronizing
    [self stopSynchronizingWithView2];
	
    // Don't retain the watched view, because we assume that it will
    // be retained by the view hierarchy for as long as we're around.
    synchronizedScrollView2 = scrollview;
	
    // get the content view of the 
    synchronizedContentView=[synchronizedScrollView2 contentView];
	
    // Make sure the watched view is sending bounds changed
    // notifications (which is probably does anyway, but calling
    // this again won't hurt).
    [synchronizedContentView setPostsBoundsChangedNotifications:YES];
	
    // and register for those notifications on the synchronized content view.
    [[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(synchronizedViewContentBoundsDidChange:)
												 name:NSViewBoundsDidChangeNotification
											   object:synchronizedContentView];
}

- (void)synchronizedViewContentBoundsDidChange:(NSNotification *)notification{
    // get the changed content view from the notification
    NSView *changedContentView=[notification object];
	
    // Get the origin of the NSClipView of the scroll view that
    // we're watching
    NSPoint changedBoundsOrigin = [changedContentView bounds].origin;
	
    // Get our current origin
    NSPoint curOffset = [[self contentView] bounds].origin;
    NSPoint newOffset = curOffset;
	
    // scrolling is synchronized in the HORIZONTAL plane
    // so only modify the x component of the offset
    newOffset.x = changedBoundsOrigin.x;
	
    // If our synced position is different from our current
    // position, reposition our content view.
    if (!NSEqualPoints(curOffset, changedBoundsOrigin))
   {
    // note that a scroll view watching this one will
    // get notified here!
		[[self contentView] scrollToPoint:newOffset];
    // we have to tell the NSScrollView to update its
    // scrollers
		[self reflectScrolledClipView:[self contentView]];
    }
}

- (void)stopSynchronizingWithView1{
    if (synchronizedScrollView1 != nil) {
		NSView* synchronizedContentView = [synchronizedScrollView1 contentView];
		
    // remove any existing notification registration
		[[NSNotificationCenter defaultCenter] removeObserver:self
														name:NSViewBoundsDidChangeNotification
													  object:synchronizedContentView];
		
    // set synchronizedScrollView to nil
		synchronizedScrollView1=nil;
    }
}
- (void)stopSynchronizingWithView2{
    if (synchronizedScrollView2 != nil) {
		NSView* synchronizedContentView = [synchronizedScrollView2 contentView];
		
    // remove any existing notification registration
		[[NSNotificationCenter defaultCenter] removeObserver:self
														name:NSViewBoundsDidChangeNotification
													  object:synchronizedContentView];
		
    // set synchronizedScrollView to nil
		synchronizedScrollView2=nil;
    }
}

@end
