//
//  This file is part of the application with the working name:
//  Peacock
//
//  Created by Johan Kool.
//  Copyright (c) 2003-2005 Johan Kool. All rights reserved.
//

@class JKGCMSDocument;
@class JKPeakRecord;
@class BDAlias;

@interface JKLibrarySearch : NSObject <NSCoding> {
	// Search options
	BDAlias *libraryAlias;
	NSString *libraryPath;
	float lowerAcceptLevel;
	int maximumNumberOfResults;
	// retentionIndex = retentionSlope * retentionTime +  retentionRemainder
	BOOL penalizeForRetentionIndex;
	NSNumber *retentionIndexSlope;     
	NSNumber *retentionIndexRemainder;
	
	@private;
	BOOL abortAction;
	NSString *remainingString;
	JKGCMSDocument *document;
	NSProgressIndicator *progressIndicator;
}

#pragma mark ACTIONS

- (NSMutableArray *)searchLibraryForPeak:(JKPeakRecord *)peak;
- (void)searchLibraryForPeaks:(NSArray *)peaks;
- (NSArray *)readJCAMPString:(NSString *)inString;

#pragma mark ACCESSORS (MACROSTYLE)

boolAccessor_h(abortAction, setAbortAction);
idAccessor_h(document, setDocument);
idAccessor_h(progressIndicator, setProgressIndicator);

@end
