//
//  This file is part of the application with the working name:
//  Peacock
//
//  Created by Johan Kool.
//  Copyright (c) 2003-2005 Johan Kool. All rights reserved.
//

@class JKDataModel;
@class JKMainWindowController;
@class JKPeakIdentificationWindowController;

extern NSString *const JKMainDocument_DocumentDeactivateNotification;
extern NSString *const JKMainDocument_DocumentActivateNotification;
extern NSString *const JKMainDocument_DocumentLoadedNotification;

@interface JKMainDocument : NSDocument
{
    JKDataModel *dataModel;
    JKMainWindowController *mainWindowController;
//    JKPeakIdentificationWindowController *peakIdentificationWindowController;
	NSString *absolutePathToNetCDF;
	NSFileWrapper *peacockFileWrapper;
}

#pragma mark IMPORT/EXPORT ACTIONS

-(NSString *)exportTabDelimitedText;
-(BOOL)readNetCDFFile:(NSString *)fileName error:(NSError **)anError;
-(NSComparisonResult)metadataCompare:(JKMainDocument *)otherDocument;

#pragma mark ACCESSORS

-(JKDataModel *)dataModel;
-(JKMainWindowController *)mainWindowController;

@end
