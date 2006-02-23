//
//  This file is part of the application with the working name:
//  Peacock
//
//  Created by Johan Kool.
//  Copyright (c) 2003-2005 Johan Kool. All rights reserved.
//

#import "JKLibrarySearch.h"
#import "JKLibraryEntry.h"
#import "JKPeakRecord.h"
#import "JKSpectrum.h"
#import "JKMainWindowController.h"

@implementation JKLibrarySearch
- (id) init {
	self = [super init];
	if (self != nil) {
		lowerAcceptLevel = 50.0;
		libraryPath = [[NSUserDefaults standardUserDefaults] valueForKey:@"defaultLibrary"];
		remainingString = [NSString stringWithString:@""];
	}
	return self;
}

/*!
    @method     
    @abstract   Search Library for the best fitting entry to peak.
    @discussion Returns an array of best fits to the peak according to the settings set for the class. The returned array contains JKLibraryEntry entries, sorted by score, with the best fit at position 0.
*/
-(NSMutableArray *)searchLibraryForPeak:(JKPeakRecord *)peak {
	NSDate *startT;
    startT = [NSDate date];
	
	NSArray *libraryEntries;
	JKSpectrum *peakSpectrum;
	NSMutableArray *results = [[NSMutableArray alloc] init];
	int i,j;
	int entriesCount;
	float score;	

	remainingString = [NSString stringWithString:@""];
	
	// Determine spectra for peak
	peakSpectrum = [mainWindowController getSpectrumForPeak:peak];	
		
	// Read library piece by piece
	NSData *aLibrary = [NSData dataWithContentsOfMappedFile:[[NSUserDefaults standardUserDefaults] valueForKey:@"defaultLibrary"]];
	
	int count = [aLibrary length]/65536;
	int remainder = [aLibrary length]%65536;
	unsigned char aBuffer[65536]; 
	unsigned char aBuffer2[remainder]; 
	NSString *tempString;
	
	for (i = 0; i <= count; i++) {
		if (i == count) {
			[aLibrary getBytes:aBuffer2 range:NSMakeRange(65536*i, remainder)];
			tempString = [[[NSString alloc] initWithBytes:aBuffer2 length:remainder encoding:NSMacOSRomanStringEncoding] autorelease];	
		} else {
			[aLibrary getBytes:aBuffer range:NSMakeRange(65536*i, 65536)];			
			tempString = [[[NSString alloc] initWithBytes:aBuffer length:65536 encoding:NSMacOSRomanStringEncoding] autorelease];	
		}
	
		// Find out what library entries we have encountered
		libraryEntries = [self readJCAMPString:[remainingString stringByAppendingString:tempString]];
		
		// Loop through peaks(=combined spectra) and determine score
		entriesCount = [libraryEntries count];
		NSLog(@"Reading Libary part i= %d of %d (%d entries): %g seconds (%g sec/entry)",i,count, entriesCount, -[startT timeIntervalSinceNow],  -[startT timeIntervalSinceNow]/entriesCount);
		startT = [NSDate date];
				
		for (j = 0; j < entriesCount; j++) {
			score = [peakSpectrum scoreComparedToLibraryEntry:[libraryEntries objectAtIndex:j]];

			// Add libentry as result to highest scoring peak if it is within range of acceptance
			if (score > 20.0) {
				NSMutableDictionary *mutDict = [[NSMutableDictionary alloc] init];
				[mutDict setValue:[NSNumber numberWithFloat:score] forKey:@"score"];
				[mutDict setValue:[libraryEntries objectAtIndex:j] forKey:@"libraryHit"];
				
				[results addObject:mutDict];
				[mutDict release];
			}
		}
	}
	NSLog(@"Found %d matches", [results count]);
	// Sort the array
	NSSortDescriptor *scoreDescriptor = [[[NSSortDescriptor alloc] initWithKey:@"score"  ascending:NO] autorelease];
	NSArray *sortDescriptors=[NSArray arrayWithObject:scoreDescriptor];	
	[results sortUsingDescriptors:sortDescriptors];
	
	// Return top 50 entries only
	int lengthRange = [results count]-50;
	int startRange = 50;
	if ([results count] < 50) {
		lengthRange = 0;
		startRange = [results count];
	}
	[results removeObjectsInRange:NSMakeRange(startRange, lengthRange)];

	[results autorelease];
	return results;	
}

/*!
@method     
 @abstract   Search Library for the best fitting entry to the array of peaks.
 @discussion Returns an array of best fits to the peaks according to the settings set for the class. The returned array contains arrays containing JKLibraryEntry entries, sorted by score, with the best fit at position 0 for each peak.
 */
-(void)searchLibraryForPeaks:(NSArray *)peaks {
	NSDate *startT;
    startT = [NSDate date];

	NSArray *libraryEntries;
	NSMutableArray *spectra = [[[NSMutableArray alloc] init] autorelease];
	int i,j,k;
	int entriesCount;
	int maximumIndex;
	float score, maximumScore;	
	[self setAbortAction:NO];
	remainingString = [NSString stringWithString:@""];

	[progressIndicator setIndeterminate:YES];
	[progressIndicator startAnimation:self];
	// Determine spectra for peaks
	int peaksCount = [peaks count];
	for (i = 0; i < peaksCount; i++ ) {
		[spectra addObject:[mainWindowController getSpectrumForPeak:[peaks objectAtIndex:i]]];	
	}

	// Read library piece by piece
	NSData *aLibrary = [NSData dataWithContentsOfMappedFile:[[NSUserDefaults standardUserDefaults] valueForKey:@"defaultLibrary"]];
		
	int count = [aLibrary length]/65536;
	[progressIndicator setIndeterminate:NO];
	[progressIndicator setMaxValue:count*1.0];

	unsigned char aBuffer[65536]; 
	for (i = 0; i < count; i++) {
		[progressIndicator setDoubleValue:i*1.0];

		[aLibrary getBytes:aBuffer range:NSMakeRange(65536*i, 65536)];
		NSString *tempString = [[[NSString alloc] initWithBytes:aBuffer length:65536 encoding:NSASCIIStringEncoding] autorelease];	
		
		// Find out what library entries we have encountered
		libraryEntries = [self readJCAMPString:[remainingString stringByAppendingString:tempString]];
		
		// Loop through peaks(=combined spectra) and determine score
		entriesCount = [libraryEntries count];
		
		for (j = 0; j < entriesCount; j++) {
			maximumScore = 0.0;
			maximumIndex = -1;
			for (k = 0; k < peaksCount; k++) {
				score = [[spectra objectAtIndex:k] scoreComparedToLibraryEntry:[libraryEntries objectAtIndex:j]];
				if (score >= maximumScore) {
					maximumScore = score;
					maximumIndex = k;
				}
			}
			// Add libentry as result to highest scoring peak if it is within range of acceptance
			if (maximumScore >= lowerAcceptLevel) {
				if (maximumScore > [[[peaks objectAtIndex:maximumIndex] valueForKey:@"score"] floatValue]) {
					[[peaks objectAtIndex:maximumIndex] setValue:[[libraryEntries objectAtIndex:j] valueForKey:@"name"] forKey:@"label"];
					[[peaks objectAtIndex:maximumIndex] setValue:[NSNumber numberWithFloat:maximumScore] forKey:@"score"];
					[[peaks objectAtIndex:maximumIndex] setLibraryHit:[libraryEntries objectAtIndex:j]];
					[[peaks objectAtIndex:maximumIndex] setValue:[NSNumber numberWithBool:YES] forKey:@"identified"];
					[[peaks objectAtIndex:maximumIndex] setValue:[NSNumber numberWithBool:NO] forKey:@"confirmed"];		
					[[peaks objectAtIndex:maximumIndex] setValue:[[[NSUserDefaults standardUserDefaults] valueForKey:@"defaultLibrary"] lastPathComponent] forKey:@"library"];
				}
			}

			if(abortAction){
				NSLog(@"Autopilot Search Aborted by User at entry %d/%d peak %d/%d library part %d/%d.",j,entriesCount, k, peaksCount, i, count);
				return;
			}
		}
	}

	return;
}

-(NSArray *)readJCAMPString:(NSString *)inString {
	int count,i,j;
	NSMutableArray *libraryEntries = [[NSMutableArray alloc] init];
	NSArray *array = [inString componentsSeparatedByString:@"##END="];
	NSCharacterSet *whiteCharacters = [NSCharacterSet whitespaceAndNewlineCharacterSet];
	
	// The strings we are looking for
    NSString *TITLE = @"##TITLE=";
    NSString *CASNAME = @"##CAS NAME=";
    NSString *MOLFORM = @"##MOLFORM=";
    NSString *CASNO = @"##CAS REGISTRY NO=";
    NSString *MASSWEIGHT = @"##MW=";
    NSString *RETINDEX = @"##RI=";
	NSString *RETWIDTH = @"##RW=";
    NSString *RETTIME = @"##RTI=";
    NSString *SRC = @"##OWNER=";
    NSString *CMT = @"##COMMENT=";
    NSString *NUMPEAKS = @"##NPOINTS=";
    NSString *XY = @"(XY..XY)";
	
	// Variables to hold the data found
	NSString *name;
    NSString *formula;
    NSString *CASNumber; 
    float massWeight;
    float retentionIndex; 
	float retentionWidth; 
    float retentionTime; 
    NSString *sourceStr; 
    NSString *comment; 
	int numPeaks; 
    NSString *xyData; 
	
	float *masses, *intensities;
	masses = (float *) malloc(1*sizeof(float));
	intensities = (float *) malloc(1*sizeof(float));
	
	count = [array count];
	
	// We ignore the last entry in the array, because it likely isn't complete 
	// NOTE: we now require at least a return after the last entry in the file or we won't read that entry
	for (i=0; i < count-1; i++) {
		// If we are dealing with an empty string, bail out
		if ([[[array objectAtIndex:i] stringByTrimmingCharactersInSet:whiteCharacters] isEqualToString:@""]) {
			break;
		}
		
		NSScanner *theScanner = [[NSScanner alloc] initWithString:[array objectAtIndex:i]];
		JKLibraryEntry *libEntry = [[JKLibraryEntry alloc] init];

		// Title
		[theScanner setScanLocation:0];
		[theScanner scanUpToString:CASNAME intoString:NULL];
		if ([theScanner scanString:CASNAME intoString:NULL]) { 
			[theScanner scanUpToString:@"##" intoString:&name];
			[libEntry setValue:[name stringByTrimmingCharactersInSet:whiteCharacters] forKey:@"name"];
			[theScanner setScanLocation:0];
			[theScanner scanUpToString:TITLE intoString:NULL];
			if ([theScanner scanString:TITLE intoString:NULL]) {
				[theScanner scanUpToString:@"##" intoString:&name];
				[libEntry setValue:[name stringByTrimmingCharactersInSet:whiteCharacters] forKey:@"source"];
			} 
			
		} else {
			[theScanner setScanLocation:0];
			[theScanner scanUpToString:TITLE intoString:NULL];
			if ([theScanner scanString:TITLE intoString:NULL]) {
				[theScanner scanUpToString:@"##" intoString:&name];
				[libEntry setValue:[name stringByTrimmingCharactersInSet:whiteCharacters] forKey:@"name"];
			} 
		}
		
		// Formula
		[theScanner setScanLocation:0];
		if([theScanner scanUpToString:MOLFORM intoString:NULL]) {
			[theScanner scanString:MOLFORM intoString:NULL]; 
			if ([theScanner scanUpToString:@"##" intoString:&formula])	
				[libEntry setValue:[formula stringByTrimmingCharactersInSet:whiteCharacters] forKey:@"formula"];
		}
		
		// CAS Number
		[theScanner setScanLocation:0];
		if ([theScanner scanUpToString:CASNO intoString:NULL]) {
			[theScanner scanString:CASNO intoString:NULL]; 
			if([theScanner scanUpToString:@"##" intoString:&CASNumber])
				[libEntry setValue:[CASNumber stringByTrimmingCharactersInSet:whiteCharacters] forKey:@"CASNumber"];			
		}
		
		// Mass weight
		[theScanner setScanLocation:0];
		if ([theScanner scanUpToString:MASSWEIGHT intoString:NULL]) {
			[theScanner scanString:MASSWEIGHT intoString:NULL]; 
			if ([theScanner scanFloat:&massWeight])
				[libEntry setMassWeight:massWeight];			
		}
		
		// Retention Index
		[theScanner setScanLocation:0];
		if ([theScanner scanUpToString:RETINDEX intoString:NULL]) {
			[theScanner scanString:RETINDEX intoString:NULL]; 
			if ([theScanner scanFloat:&retentionIndex])		
				[libEntry setRetentionIndex:retentionIndex];			
		}
		
		// Retention Width
		[theScanner setScanLocation:0];
		if ([theScanner scanUpToString:RETWIDTH intoString:NULL]) {
			[theScanner scanString:RETWIDTH intoString:NULL]; 
			if ([theScanner scanFloat:&retentionWidth])
				[libEntry setRetentionWidth:retentionWidth];
		}
		
		// Retention Time
		[theScanner setScanLocation:0];
		if ([theScanner scanUpToString:RETTIME intoString:NULL]) {
			[theScanner scanString:RETTIME intoString:NULL]; 
			if ([theScanner scanFloat:&retentionTime])
				[libEntry setRetentionTime:retentionTime];			
		}
		
		// Comment
		[theScanner setScanLocation:0];
		if ([theScanner scanUpToString:CMT intoString:NULL]) {
			[theScanner scanString:CMT intoString:NULL]; 
			if([theScanner scanUpToString:@"##" intoString:&comment])
				[libEntry setValue:[comment stringByTrimmingCharactersInSet:whiteCharacters] forKey:@"comment"];
		}
		
		// Source
		[theScanner setScanLocation:0];
		if ([theScanner scanUpToString:SRC intoString:NULL]) {
			[theScanner scanString:SRC intoString:NULL]; 
			if ([theScanner scanUpToString:@"##" intoString:&sourceStr])
				[libEntry setValue:[sourceStr stringByTrimmingCharactersInSet:whiteCharacters] forKey:@"source"];
		}
		
		// Number of peaks
		[theScanner setScanLocation:0];
		if ([theScanner scanUpToString:NUMPEAKS intoString:NULL]) {
			[theScanner scanString:NUMPEAKS intoString:NULL]; 
			[theScanner scanInt:&numPeaks];
		}
		
		// Spectrum data
		[theScanner setScanLocation:0];
		if ([theScanner scanUpToString:XY intoString:NULL] & numPeaks > 0) {
			[theScanner scanString:XY intoString:NULL]; 
			[theScanner scanUpToCharactersFromSet:[NSCharacterSet letterCharacterSet] intoString:&xyData];
			
			NSScanner *theScanner2 = [[NSScanner alloc] initWithString:xyData];
			masses = (float *) realloc(masses, numPeaks*sizeof(float));
			intensities = (float *) realloc(intensities, numPeaks*sizeof(float));
			int massInt, intensityInt;

			for (j=0; j < numPeaks; j++){
				if (![theScanner2 scanInt:&massInt]) NSLog(@"Error during reading library (masses).");
//				NSAssert(massInt > 0, @"massInt");
				masses[j] = massInt*1.0;
				[theScanner2 scanUpToCharactersFromSet:[NSCharacterSet decimalDigitCharacterSet] intoString:NULL];
				if (![theScanner2 scanInt:&intensityInt]) NSLog(@"Error during reading library (intensities).");
//				NSAssert(intensityInt > 0, @"intensityInt");
				intensities[j] = intensityInt*1.0;
			}
			[theScanner2 release];
			
			[libEntry setMasses:masses withCount:numPeaks];
			[libEntry setIntensities:intensities withCount:numPeaks];
			
		}
		// Add data to Library
		[libraryEntries addObject:libEntry];
		[libEntry release];
		[theScanner release];
    }
	free(masses);
	free(intensities);
	
	// library Array should be returned
	// and the remaining string
	remainingString = [array objectAtIndex:count-1];
	
	[libraryEntries autorelease];
    return libraryEntries;	
}

boolAccessor(abortAction, setAbortAction);
idAccessor(mainWindowController, setMainWindowController);
idAccessor(progressIndicator, setProgressIndicator);


@end
