//
//  JKSynchroScrollView.h
//  Peacock
//
//  Created by Johan Kool on 10-3-06.
//  Copyright 2006-2007 Johan Kool. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface JKSynchroScrollView : NSScrollView {
    NSScrollView* synchronizedScrollView1; // not retained
    NSScrollView* synchronizedScrollView2; // not retained
    BOOL synchronizeHorizontally;
    BOOL synchronizeVertically;
}

- (void)setSynchronizedScrollView1:(NSScrollView*)scrollview;
- (void)setSynchronizedScrollView2:(NSScrollView*)scrollview;
- (void)stopSynchronizingWithView1;
- (void)stopSynchronizingWithView2;
- (void)synchronizedViewContentBoundsDidChange:(NSNotification *)notification;

@property BOOL synchronizeHorizontally;
@property BOOL synchronizeVertically;

@end
