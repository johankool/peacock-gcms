//
//  This file is part of the application with the working name:
//  Peacock
//
//  Created by Johan Kool.
//  Copyright (c) 2003-2005 Johan Kool. All rights reserved.
//

@class JKMainDocument;
@class JKPeakRecord;

@interface JKLibrarySearch : NSObject {
	NSString *libraryPath;
	float lowerAcceptLevel;
	int maximumNumberOfResults;
	
	@private;
	BOOL abortAction;
	NSString *remainingString;
	JKMainDocument *document;
	NSProgressIndicator *progressIndicator;
}

-(NSMutableArray *)searchLibraryForPeak:(JKPeakRecord *)peak;
-(void)searchLibraryForPeaks:(NSArray *)peaks;
-(NSArray *)readJCAMPString:(NSString *)inString;

#pragma mark ACCESSORS (MACROSTYLE)
boolAccessor_h(abortAction, setAbortAction);
idAccessor_h(document, setDocument);
idAccessor_h(progressIndicator, setProgressIndicator);

@end
