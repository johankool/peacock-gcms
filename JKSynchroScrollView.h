//
//  JKSynchroScrollView.h
//  Peacock
//
//  Created by Johan Kool on 10-3-06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface JKSynchroScrollView : NSScrollView {
    NSScrollView* synchronizedScrollView1; // not retained
    NSScrollView* synchronizedScrollView2; // not retained

}

- (void)setSynchronizedScrollView1:(NSScrollView*)scrollview;
- (void)setSynchronizedScrollView2:(NSScrollView*)scrollview;
- (void)stopSynchronizingWithView1;
- (void)stopSynchronizingWithView2;
- (void)synchronizedViewContentBoundsDidChange:(NSNotification *)notification;

@end
