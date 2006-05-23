//
//  JKStatisticsDocument.h
//  Peacock
//
//  Created by Johan Kool on 19-3-06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class JKStatisticsWindowController;

@interface JKStatisticsDocument : NSDocument {
    JKStatisticsWindowController *statisticsWindowController;
}

- (JKStatisticsWindowController *)statisticsWindowController;

@end
