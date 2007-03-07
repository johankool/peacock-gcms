//
//  JKStatisticsDocument.h
//  Peacock
//
//  Created by Johan Kool on 19-3-06.
//  Copyright 2006-2007 Johan Kool. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class JKStatisticsWindowController;

@interface JKStatisticsDocument : NSDocument {
    JKStatisticsWindowController *statisticsWindowController;
    NSDictionary *_documentProxy;
}

- (JKStatisticsWindowController *)statisticsWindowController;

@end
