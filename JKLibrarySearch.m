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
		lowerAcceptLevel = 50.0; //[[[NSUserDefaults standardUserDefaults] valueForKey:@"lowerAcceptLevel"] floatValue];
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
	float score, delta;	

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
		JKLogDebug(@"Reading Libary part i= %d of %d (%d entries): %g seconds (%g sec/entry)",i,count, entriesCount, -[startT timeIntervalSinceNow],  -[startT timeIntervalSinceNow]/entriesCount);
		startT = [NSDate date];
				
		for (j = 0; j < entriesCount; j++) {
			score = [peakSpectrum scoreComparedToLibraryEntry:[libraryEntries objectAtIndex:j]];

			// Add libentry as result to highest scoring peak if it is within range of acceptance
			if (score > lowerAcceptLevel/2.0) {
				NSMutableDictionary *mutDict = [[NSMutableDictionary alloc] init];
				[mutDict setValue:[NSNumber numberWithFloat:score] forKey:@"score"];
				[mutDict setValue:[libraryEntries objectAtIndex:j] forKey:@"libraryHit"];
				delta = [[peak retentionIndex] floatValue] - [[libraryEntries objectAtIndex:j] retentionIndex];
				[mutDict setValue:[NSNumber numberWithFloat:delta] forKey:@"deltaRetentionIndex"];
				[results addObject:mutDict];
				[mutDict release];
			}
		}
	}

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
	for (i = 0; i <= count; i++) {
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
					[[peaks objectAtIndex:maximumIndex] setValue:[[libraryEntries objectAtIndex:j] valueForKey:@"symbol"] forKey:@"symbol"];
					[[peaks objectAtIndex:maximumIndex] setValue:[NSNumber numberWithFloat:maximumScore] forKey:@"score"];
					[[peaks objectAtIndex:maximumIndex] setLibraryHit:[libraryEntries objectAtIndex:j]];
					[[peaks objectAtIndex:maximumIndex] setValue:[NSNumber numberWithBool:YES] forKey:@"identified"];
					[[peaks objectAtIndex:maximumIndex] setValue:[NSNumber numberWithBool:NO] forKey:@"confirmed"];		
					[[peaks objectAtIndex:maximumIndex] setValue:[[[NSUserDefaults standardUserDefaults] valueForKey:@"defaultLibrary"] lastPathComponent] forKey:@"library"];
				}
			}

			if(abortAction){
				JKLogInfo(@"Identifying Compounds Search Aborted by User at entry %d/%d peak %d/%d library part %d/%d.",j,entriesCount, k, peaksCount, i, count);
				return;
			}
		}
	}

	return;
}

//-(NSArray *)readJCAMPString:(NSString *)inString {
//	int count,i,j;
//	NSMutableArray *libraryEntries = [[NSMutableArray alloc] init];
//	NSArray *array = [inString componentsSeparatedByString:@"##END="];
//	NSCharacterSet *whiteCharacters = [NSCharacterSet whitespaceAndNewlineCharacterSet];
//		
//	int scanLocation;
//	int numPeaks; 
//    NSString *xyData; 
//	
//	NSString *scannedString;
//	float scannedFloat;
//	
//	float *masses, *intensities;
//	masses = (float *) malloc(1*sizeof(float));
//	intensities = (float *) malloc(1*sizeof(float));
//	
//	count = [array count];
//	
//	// We ignore the last entry in the array, because it likely isn't complete 
//	// NOTE: we now require at least a return after the last entry in the file or we won't read that entry
//	for (i=0; i < count-1; i++) {
//		// If we are dealing with an empty string, bail out
//		if ([[[array objectAtIndex:i] stringByTrimmingCharactersInSet:whiteCharacters] isEqualToString:@""]) {
//			continue;
//		}
//		
//		NSScanner *theScanner = [[NSScanner alloc] initWithString:[array objectAtIndex:i]];
//		JKLibraryEntry *libEntry = [[JKLibraryEntry alloc] init];
//		scanLocation = 0;
//
//		// Remove all comments
//		#warning Removing all comments is not yet implemented.
//		
//		// Reading header
//		// Title
//		[theScanner scanUpToString:@"##TITLE=" intoString:NULL];
//		if ([theScanner scanString:@"##TITLE=" intoString:NULL]) {
//			[theScanner scanUpToString:@"##" intoString:&scannedString];
//			[libEntry setValue:[scannedString stringByTrimmingCharactersInSet:whiteCharacters] forKey:@"name"];
//			scanLocation = [theScanner scanLocation];
//		} else {
//			JKLogError(@"ERROR: Required ##TITLE entry not found.");
//			[libEntry release];
//			[theScanner release];
//			continue;
//		}
//		
//		// JCAMP-DX
//		[theScanner setScanLocation:scanLocation];
//		[theScanner scanUpToString:@"##JCAMP-DX=" intoString:NULL];
//		if ([theScanner scanString:@"##JCAMP-DX=" intoString:NULL]) {
//			[theScanner scanUpToString:@"##" intoString:&scannedString];
//			scanLocation = [theScanner scanLocation];
//			// Currently ignored, could test JCAMP-DX version here.
//		} else {
//			JKLogWarning(@"WARNING: Required ##JCAMP-DX entry not found.");
//		}
//		
//		// DATA-TYPE
//		[theScanner setScanLocation:scanLocation];
//		[theScanner scanUpToString:@"##DATA-TYPE=" intoString:NULL];
//		if ([theScanner scanString:@"##DATA-TYPE=" intoString:NULL]) {
//			[theScanner scanUpToString:@"##" intoString:&scannedString];
//			scanLocation = [theScanner scanLocation];
//			scannedString = [scannedString stringByTrimmingCharactersInSet:whiteCharacters];
//			if (![scannedString isEqualToString:@"MASS SPECTRUM"]) {
//				JKLogError(@"ERROR: Unsupported ##DATA-TYPE \"%@\" found.", scannedString);
//				[libEntry release];
//				[theScanner release];
//				continue;
//			}
//		} else {
//			JKLogWarning(@"WARNING: Required ##DATA-TYPE entry not found.");
//		}
//
//		// DATA-CLASS
//		[theScanner setScanLocation:scanLocation];
//		[theScanner scanUpToString:@"##DATA-CLASS=" intoString:NULL];
//		if ([theScanner scanString:@"##DATA-CLASS=" intoString:NULL]) {
//			[theScanner scanUpToString:@"##" intoString:&scannedString];
//			scanLocation = [theScanner scanLocation];
//			scannedString = [scannedString stringByTrimmingCharactersInSet:whiteCharacters];
//			if (!([scannedString isEqualToString:@"PEAK TABLE"] | [scannedString isEqualToString:@"XYDATA"])) {
//				JKLogError(@"ERROR: Unsupported ##DATA-CLASS \"%@\" found.", scannedString);
//				[libEntry release];
//				[theScanner release];
//				continue;
//			}
//		} else {
//			JKLogWarning(@"WARNING: Required ##DATA-CLASS entry not found.");
//		}
//
//		// ORIGIN
//		[theScanner setScanLocation:scanLocation];
//		[theScanner scanUpToString:@"##ORIGIN=" intoString:NULL];
//		if ([theScanner scanString:@"##ORIGIN=" intoString:NULL]) {
//			[theScanner scanUpToString:@"##" intoString:&scannedString];
//			scanLocation = [theScanner scanLocation];
//			// Currently ignored
//		} else {
//			JKLogWarning(@"WARNING: Required ##ORIGIN entry not found.");
//		}
//
//		// OWNER
//		[theScanner setScanLocation:scanLocation];
//		[theScanner scanUpToString:@"##OWNER=" intoString:NULL];
//		if ([theScanner scanString:@"##OWNER=" intoString:NULL]) {
//			[theScanner scanUpToString:@"##" intoString:&scannedString];
//			scanLocation = [theScanner scanLocation];
//			[libEntry setValue:[scannedString stringByTrimmingCharactersInSet:whiteCharacters] forKey:@"source"];
//		} else {
//			JKLogWarning(@"WARNING: Required ##OWNER entry not found.");
//		}
//		
//		// Reading chemical information
//		// CAS NAME
//		[theScanner setScanLocation:scanLocation];
//		[theScanner scanUpToString:@"##CAS NAME=" intoString:NULL];
//		if ([theScanner scanString:@"##CAS NAME=" intoString:NULL]) {
//			[theScanner scanUpToString:@"##" intoString:&scannedString];
//			scanLocation = [theScanner scanLocation];
//			[libEntry setValue:[scannedString stringByTrimmingCharactersInSet:whiteCharacters] forKey:@"name"]; // CAS NAME overwrites title, but is often more useful anyway.
//		}		
//
//		// CAS REGISTRY NO
//		[theScanner setScanLocation:scanLocation];
//		[theScanner scanUpToString:@"##CAS REGISTRY NO=" intoString:NULL];
//		if ([theScanner scanString:@"##CAS REGISTRY NO=" intoString:NULL]) {
//			[theScanner scanUpToString:@"##" intoString:&scannedString];
//			scanLocation = [theScanner scanLocation];
//			[libEntry setValue:[scannedString stringByTrimmingCharactersInSet:whiteCharacters] forKey:@"CASNumber"]; 
//		}		
//		
//		// MOLFORM
//		[theScanner setScanLocation:scanLocation];
//		[theScanner scanUpToString:@"##MOLFORM=" intoString:NULL];
//		if ([theScanner scanString:@"##MOLFORM=" intoString:NULL]) {
//			[theScanner scanUpToString:@"##" intoString:&scannedString];
//			scanLocation = [theScanner scanLocation];
//			[libEntry setValue:[scannedString stringByTrimmingCharactersInSet:whiteCharacters] forKey:@"formula"]; 
//		}		
//
//		// MW
//		[theScanner setScanLocation:scanLocation];
//		[theScanner scanUpToString:@"##MW=" intoString:NULL];
//		if ([theScanner scanString:@"##MW=" intoString:NULL]) {
//			scanLocation = [theScanner scanLocation];
//			if ([theScanner scanFloat:&scannedFloat]) {
//				[libEntry setMassWeight:scannedFloat];			
//			} else {
//				JKLogWarning(@"WARNING: Massweight could not be read.");
//			}
//		}		
//
//		// RI
//		[theScanner setScanLocation:scanLocation];
//		[theScanner scanUpToString:@"##RI=" intoString:NULL];
//		if ([theScanner scanString:@"##RI=" intoString:NULL]) {
//			scanLocation = [theScanner scanLocation];
//			if ([theScanner scanFloat:&scannedFloat]) {
//				[libEntry setRetentionIndex:scannedFloat];			
//			} else {
//				JKLogWarning(@"WARNING: Retention index could not be read.");
//			}
//		}	
//		
//		// RTI
//		[theScanner setScanLocation:scanLocation];
//		[theScanner scanUpToString:@"##RTI=" intoString:NULL];
//		if ([theScanner scanString:@"##RTI=" intoString:NULL]) {
//			scanLocation = [theScanner scanLocation];
//			if ([theScanner scanFloat:&scannedFloat]) {
//				[libEntry setRetentionTime:scannedFloat];			
//			} else {
//				JKLogWarning(@"WARNING: Retention time could not be read.");
//			}
//		}		
//		
//		#warning Comment not handled.
////		// Comment
////		[theScanner setScanLocation:0];
////		if ([theScanner scanUpToString:CMT intoString:NULL]) {
////			[theScanner scanString:CMT intoString:NULL]; 
////			if([theScanner scanUpToString:@"##" intoString:&comment])
////				[libEntry setValue:[comment stringByTrimmingCharactersInSet:whiteCharacters] forKey:@"comment"];
////		}
//
//		// NPOINTS
//		[theScanner setScanLocation:scanLocation];
//		[theScanner scanUpToString:@"##NPOINTS=" intoString:NULL];
//		if ([theScanner scanString:@"##NPOINTS=" intoString:NULL]) {
//			scanLocation = [theScanner scanLocation];
//			if (![theScanner scanInt:&numPeaks]) {
//				JKLogError(@"ERROR: Number of points could not be read.");
//				[libEntry release];
//				[theScanner release];
//				continue;
//			}
//		}		
//		
//		// XYDATA
//		[theScanner setScanLocation:scanLocation];
//		[theScanner scanUpToString:@"##XYDATA=" intoString:NULL];
//		if ([theScanner scanString:@"##XYDATA=" intoString:NULL]) {
//			[theScanner scanUpToString:@"\n" intoString:&scannedString];
//			scanLocation = [theScanner scanLocation];
//			scannedString = [scannedString stringByTrimmingCharactersInSet:whiteCharacters];
//			if (![scannedString isEqualToString:@"(XY..XY)"]) {
//				JKLogError(@"ERROR: Unsupported ##XYDATA \"%@\" found.", scannedString);
//				[libEntry release];
//				[theScanner release];
//				continue;
//			}
//		} else {
//			[theScanner setScanLocation:scanLocation];
//			[theScanner scanUpToString:@"##PEAK TABLE=" intoString:NULL];
//			if ([theScanner scanString:@"##PEAK TABLE=" intoString:NULL]) {
//				[theScanner scanUpToString:@"\n" intoString:&scannedString];
//				scanLocation = [theScanner scanLocation];
//				scannedString = [scannedString stringByTrimmingCharactersInSet:whiteCharacters];
//				if (![scannedString isEqualToString:@"(XY..XY)"]) {
//					JKLogError(@"ERROR: Unsupported ##PEAK TABLE \"%@\" found.", scannedString);
//					[libEntry release];
//					[theScanner release];
//					continue;
//				}
//			} else {
//				JKLogError(@"ERROR: No data found.");
//				[libEntry release];
//				[theScanner release];
//				continue;
//			}
//		}
//
//		[theScanner scanUpToCharactersFromSet:[NSCharacterSet letterCharacterSet] intoString:&xyData];
//		
//		NSScanner *theScanner2 = [[NSScanner alloc] initWithString:xyData];
//		masses = (float *) realloc(masses, numPeaks*sizeof(float));
//		intensities = (float *) realloc(intensities, numPeaks*sizeof(float));
//		int massInt, intensityInt;
//		
//		for (j=0; j < numPeaks; j++){
//			if (![theScanner2 scanInt:&massInt]) JKLogError(@"Error during reading library (masses).");
//			//				NSAssert(massInt > 0, @"massInt");
//			masses[j] = massInt*1.0;
//			[theScanner2 scanUpToCharactersFromSet:[NSCharacterSet decimalDigitCharacterSet] intoString:NULL];
//			if (![theScanner2 scanInt:&intensityInt]) JKLogError(@"Error during reading library (intensities).");
//			//				NSAssert(intensityInt > 0, @"intensityInt");
//			intensities[j] = intensityInt*1.0;
//		}
//		[libEntry setMasses:masses withCount:numPeaks];
//		[libEntry setIntensities:intensities withCount:numPeaks];
//		[theScanner2 release];
//			
//		// Add data to Library
//		[libraryEntries addObject:libEntry];
//		[libEntry release];
//		[theScanner release];
//    }
//	free(masses);
//	free(intensities);
//	
//	// library Array should be returned
//	// and the remaining string
//	remainingString = [array objectAtIndex:count-1];
//	
////	JKLogDebug(@"Found %d entries", [libraryEntries count]);
//	[libraryEntries autorelease];
//    return libraryEntries;	
//}
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
    NSString *RETTIME = @"##RTI=";
    NSString *SRC = @"##OWNER=";
    NSString *CMT = @"##COMMENT=";
    NSString *NUMPEAKS = @"##NPOINTS=";
    NSString *XY = @"(XY..XY)";
	
	// Variables to hold the data found
	NSString *name;
    NSString *formula;
    NSString *CASNumber; 
	NSString *symbol;
    float massWeight;
    float retentionIndex; 
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
		
		// Symbol
		[theScanner setScanLocation:0];
		if ([theScanner scanUpToString:@"##.SYMBOL=" intoString:NULL]) {
			[theScanner scanString:@"##.SYMBOL=" intoString:NULL]; 
			if([theScanner scanUpToString:@"##" intoString:&symbol])
				[libEntry setValue:[symbol stringByTrimmingCharactersInSet:whiteCharacters] forKey:@"symbol"];			
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
				if (![theScanner2 scanInt:&massInt]) JKLogError(@"Error during reading library (masses) %@ %@.", [libEntry valueForKey:@"name"], [theScanner2 string]);
				//				NSAssert(massInt > 0, @"massInt");
				masses[j] = massInt*1.0;
				[theScanner2 scanUpToCharactersFromSet:[NSCharacterSet decimalDigitCharacterSet] intoString:NULL];
				if (![theScanner2 scanInt:&intensityInt]) JKLogError(@"Error during reading library (intensities). %@",[libEntry valueForKey:@"name"]);
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
