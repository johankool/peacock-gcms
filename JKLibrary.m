//
//  This file is part of the application with the working name:
//  Peacock
//
//  Created by Johan Kool.
//  Copyright (c) 2003-2005 Johan Kool. All rights reserved.
//

#import "JKLibrary.h"
#import "JKLibraryWindowController.h"
#import "JKLibraryEntry.h"

@implementation JKLibrary

#pragma mark INITIALIZATION

-(id)init {
	self = [super init];
    if (self != nil) {
        libraryWindowController = [[JKLibraryWindowController alloc] init];
		libraryArray = [[NSMutableArray alloc] init];
    }
    return self;
}

-(void)makeWindowControllers {
    [self addWindowController:libraryWindowController];
}

#pragma mark OPEN/SAVE DOCUMENT

-(BOOL)writeToFile:(NSString *)fileName ofType:(NSString *)docType {
	if ([docType isEqualToString:@"JCAMP Library"]) {
		return [self exportJCAMPToFile:fileName];
	} else if ([docType isEqualToString:@"AMDIS Target Library"]) {
		return [self exportAMDISToFile:fileName];
	}
    return NO;
}

-(BOOL)readFromFile:(NSString *)fileName ofType:(NSString *)docType {
	if ([docType isEqualToString:@"JCAMP Library"]) {
		return [self importJCAMPFromFile:fileName];
	} else if ([docType isEqualToString:@"AMDIS Target Library"]) {
		return [self importAMDISFromFile:fileName];
	}
    return NO;
}

#pragma mark IMPORT/EXPORT ACTIONS
#warning Old routines in use here, check JKLibrarySearch for correct routines.

-(BOOL)importJCAMPFromFile:(NSString *)fileName {
	NSString *inString = [NSString stringWithContentsOfFile:fileName];

	int count,i,j;
//	NSMutableArray *libraryEntries = [[NSMutableArray alloc] init];
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
		
		// Name
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
		if (([theScanner scanUpToString:XY intoString:NULL]) & (numPeaks > 0)) {
			[theScanner scanString:XY intoString:NULL]; 
			[theScanner scanUpToCharactersFromSet:[NSCharacterSet letterCharacterSet] intoString:&xyData];
			
			NSScanner *theScanner2 = [[NSScanner alloc] initWithString:xyData];
			masses = (float *) realloc(masses, numPeaks*sizeof(float));
			intensities = (float *) realloc(intensities, numPeaks*sizeof(float));
			int massInt, intensityInt;
			
			for (j=0; j < numPeaks; j++){
				if (![theScanner2 scanInt:&massInt]) JKLogError(@"Error during reading library (masses).");
				//				NSAssert(massInt > 0, @"massInt");
				masses[j] = massInt*1.0;
				[theScanner2 scanUpToCharactersFromSet:[NSCharacterSet decimalDigitCharacterSet] intoString:NULL];
				if (![theScanner2 scanInt:&intensityInt]) JKLogError(@"Error during reading library (intensities).");
				//				NSAssert(intensityInt > 0, @"intensityInt");
				intensities[j] = intensityInt*1.0;
			}
			[theScanner2 release];
			
			[libEntry setMasses:masses withCount:numPeaks];
			[libEntry setIntensities:intensities withCount:numPeaks];
			
		}
		// Add data to Library
		[libraryArray addObject:libEntry];
		[libEntry release];
		[theScanner release];
	}
	free(masses);
	free(intensities);
	
	// library Array should be returned
	// and the remaining string
//	remainingString = [array objectAtIndex:count-1];
	
//	[libraryEntries autorelease];

    return YES;	
}

-(BOOL)exportJCAMPToFile:(NSString *)fileName {
	NSMutableString *outStr = [[NSMutableString alloc] init]; 
	NSArray *array;
	int i,j,count2;
	int count = [libraryArray count];
	
	for (i=0; i < count; i++) {
		if ([[[libraryArray objectAtIndex:i] valueForKey:@"name"] isNotEqualTo:@""]) {
			[outStr appendFormat:@"##TITLE= %@\r\n", [[libraryArray objectAtIndex:i] valueForKey:@"name"]];	
		} else {
			[outStr appendFormat:@"##TITLE= %@ entry %d\r\n",[fileName lastPathComponent], i+1];				
		}
		if ([[[libraryArray objectAtIndex:i] valueForKey:@"formula"] isNotEqualTo:@""])[outStr appendFormat:@"##MOLFORM= %@\r\n", [[libraryArray objectAtIndex:i] valueForKey:@"formula"]];
//		if ([[[libraryArray objectAtIndex:i] valueForKey:@"name"] isNotEqualTo:@""]) [outStr appendFormat:@"##CAS NAME= %@\r\n", [[libraryArray objectAtIndex:i] valueForKey:@"name"]];
		if ([[[libraryArray objectAtIndex:i] valueForKey:@"CASNumber"] isNotEqualTo:@""])[outStr appendFormat:@"##CAS REGISTRY NO= %@\r\n", [[libraryArray objectAtIndex:i] valueForKey:@"CASNumber"]];
		if (![[[libraryArray objectAtIndex:i] valueForKey:@"massWeight"] isEqualToNumber:[NSNumber numberWithFloat:0.0]])[outStr appendFormat:@"##MW= %.0f\r\n", [[[libraryArray objectAtIndex:i] valueForKey:@"massWeight"] floatValue]];
		if (![[[libraryArray objectAtIndex:i] valueForKey:@"retentionIndex"] isEqualToNumber:[NSNumber numberWithFloat:0.0]])[outStr appendFormat:@"##RI= %.3f\r\n", [[[libraryArray objectAtIndex:i] valueForKey:@"retentionIndex"] floatValue]];
		if (![[[libraryArray objectAtIndex:i] valueForKey:@"retentionTime"] isEqualToNumber:[NSNumber numberWithFloat:0.0]])[outStr appendFormat:@"##RTI= %.3f\r\n", [[[libraryArray objectAtIndex:i] valueForKey:@"retentionTime"] floatValue]];
		if ([[[libraryArray objectAtIndex:i] valueForKey:@"source"] isNotEqualTo:@""])[outStr appendFormat:@"##SOURCE= %@\r\n", [[libraryArray objectAtIndex:i] valueForKey:@"source"]];
		if ([[[libraryArray objectAtIndex:i] valueForKey:@"comment"] isNotEqualTo:@""])[outStr appendFormat:@"##COMMENT= %@\r\n", [[libraryArray objectAtIndex:i] valueForKey:@"comment"]];
		array = [[libraryArray objectAtIndex:i] valueForKey:@"points"];
		count2 = [array count];
		[outStr appendFormat:@"##DATA TYPE= MASS SPECTRUM\r\n##NPOINTS= %i\r\n##XYDATA= (XY..XY)\r\n", count2];
		for (j=0; j < count2; j++) {
			[outStr appendFormat:@" %.0f, %.0f", [[[array objectAtIndex:j] valueForKey:@"Mass"] floatValue], [[[array objectAtIndex:j] valueForKey:@"Intensity"] floatValue]];
			if (fmod(j,8) == 7 && j != count2-1){
				[outStr appendString:@"\r\n"];
			}
		}
		[outStr appendString:@"\r\n##END= \r\n"];
	}
	
	if ([outStr writeToFile:fileName atomically:NO encoding:NSASCIIStringEncoding error:nil]) {
		return YES;
	} else {
		NSRunInformationalAlertPanel(NSLocalizedString(@"File saved using UTF-8 encoding",@""),NSLocalizedString(@"Probably non-ASCII characters are used in entries of the library. Peacock will save the library in UTF-8 encoding instead of the prescribed ASCII encoding. In order to use this library in other applications the non-ASCII characters should probably be removed.",@""),NSLocalizedString(@"OK",@""),nil,nil);
		return [outStr writeToFile:fileName atomically:NO];		
	}
}

-(BOOL)importAMDISFromFile:(NSString *)fileName {
	int count,i,j;
	NSString *inStr = [NSString stringWithContentsOfFile:fileName];
	NSArray *array = [inStr componentsSeparatedByString:@"\r\n\r\n"];
		
    NSString *CASNAME = @"NAME:";
    NSString *name = @"";
    NSString *MOLFORM = @"FORM:";
    NSString *formula = @"";
    NSString *CASNO = @"CASNO:";
    NSString *CASNumber = @"";
    NSString *RETINDEX = @"RI:";
    float retentionIndex = 0.0;
	NSString *RETWIDTH = @"RW:";
	float retentionWidth = 0.0;
    NSString *RETTIME = @"RT:";
    float retentionTime;
    NSString *SRC = @"SOURCE:";
    NSString *sourceStr = @"";
    NSString *CMT = @"COMMENT:";
    NSString *comment = @"";	
    NSString *XY = @"NUM PEAKS:";
	int numPeaks = 0;
    NSString *xyData;
	float mass, intensity;

	count = [array count];
	for (i=0; i < count; i++) {
		NSScanner *theScanner = [NSScanner scannerWithString:[array objectAtIndex:i]];
		NSMutableDictionary *mutDict = [[NSMutableDictionary alloc] init];

		// Reset
		name = @"";
		formula = @"";
		CASNumber = @"";
		retentionIndex = 0.0;
		retentionWidth = 0.0;
		retentionTime = 0.0;
		sourceStr = @"";
		comment = @"";	
		numPeaks = 0;
		xyData = @"";
		mass = 0.0;
		intensity = 0.0;
		
		
		// Name
		[theScanner setScanLocation:0];
		if ([theScanner scanUpToString:CASNAME intoString:NULL] || [theScanner scanString:CASNAME intoString:NULL]) {
			[theScanner scanString:CASNAME intoString:NULL]; 
			[theScanner scanUpToString:@"\r\n" intoString:&name];
			[mutDict setValue:name forKey:@"name"];
		}
		
		// Formula
		[theScanner setScanLocation:0];
		if([theScanner scanUpToString:MOLFORM intoString:NULL]) {
			[theScanner scanString:MOLFORM intoString:NULL]; 
			[theScanner scanUpToString:@"\r\n" intoString:&formula];
			[mutDict setValue:formula forKey:@"formula"];
		}
		
		// CAS Number
		[theScanner setScanLocation:0];
		if ([theScanner scanUpToString:CASNO intoString:NULL]) {
			[theScanner scanString:CASNO intoString:NULL]; 
			[theScanner scanUpToString:@"\r\n" intoString:&CASNumber];
			[mutDict setValue:CASNumber forKey:@"CASNumber"];			
		}
		
		// Mass weight
		[theScanner setScanLocation:0];
		if ([theScanner scanUpToString:@"MW:" intoString:NULL]) {
			[theScanner scanString:@"MW:" intoString:NULL]; 
			[theScanner scanFloat:&retentionIndex];
			[mutDict setValue:[NSNumber numberWithFloat:retentionIndex] forKey:@"massWeight"];			
		}
		
		// Retention Index
		[theScanner setScanLocation:0];
		if ([theScanner scanUpToString:RETINDEX intoString:NULL]) {
			[theScanner scanString:RETINDEX intoString:NULL]; 
			[theScanner scanFloat:&retentionIndex];
			[mutDict setValue:[NSNumber numberWithFloat:retentionIndex] forKey:@"retentionIndex"];			
		}
		
		// Retention Width
		[theScanner setScanLocation:0];
		if ([theScanner scanUpToString:RETWIDTH intoString:NULL]) {
			[theScanner scanString:RETWIDTH intoString:NULL]; 
			[theScanner scanFloat:&retentionWidth];
			[mutDict setValue:[NSNumber numberWithFloat:retentionWidth] forKey:@"retentionWidth"];
		}
		
		// Retention Time
		[theScanner setScanLocation:0];
		if ([theScanner scanUpToString:RETTIME intoString:NULL]) {
			[theScanner scanString:RETTIME intoString:NULL]; 
			[theScanner scanFloat:&retentionTime];
			[mutDict setValue:[NSNumber numberWithFloat:retentionTime] forKey:@"retentionTime"];			
		}
		
		// Comment
		[theScanner setScanLocation:0];
		if ([theScanner scanUpToString:CMT intoString:NULL]) {
			[theScanner scanString:CMT intoString:NULL]; 
			[theScanner scanUpToString:@"\r\n" intoString:&comment];
			[mutDict setValue:comment forKey:@"comment"];
		}
		
		// Source
		[theScanner setScanLocation:0];
		if ([theScanner scanUpToString:SRC intoString:NULL]) {
			[theScanner scanString:SRC intoString:NULL]; 
			[theScanner scanUpToString:@"\r\n" intoString:&sourceStr];
			[mutDict setValue:sourceStr forKey:@"source"];
		}
		
		// Spectrum data
		[theScanner setScanLocation:0];
		if ([theScanner scanUpToString:XY intoString:NULL]) {
			[theScanner scanString:XY intoString:NULL]; 
			[theScanner scanInt:&numPeaks];
			[theScanner scanUpToCharactersFromSet:[NSCharacterSet letterCharacterSet] intoString:&xyData];
			
			NSScanner *theScannerXY = [NSScanner scannerWithString:xyData];
			NSMutableArray *arrayOut = [[NSMutableArray alloc] init];
			for (j=0; j <  numPeaks; j++) {
				[theScannerXY scanUpToString:@"(" intoString:NULL];
				[theScannerXY scanString:@"(" intoString:NULL];
				[theScannerXY scanFloat:&mass];
				[theScannerXY scanString:@"," intoString:NULL]; // occurs sometimes in msl files and can trip the scanfloat function
				[theScannerXY scanFloat:&intensity];
				[theScannerXY scanUpToString:@")" intoString:NULL];
				
				NSMutableDictionary *mutDict2 = [[NSMutableDictionary alloc] init];
				[mutDict2 setValue:[NSNumber numberWithFloat:mass] forKey:@"Mass"];
				[mutDict2 setValue:[NSNumber numberWithFloat:intensity] forKey:@"Intensity"];
				[arrayOut addObject:mutDict2];
				[mutDict2 release];
			}
			//[theScannerXY release];
			
			[mutDict setObject:arrayOut forKey:@"points"];
			//[arrayOut release];			
		}

		// Add data to Library
		[libraryArray addObject:mutDict];
		[mutDict release];
//		[theScanner release];
    }

    return YES;
}

-(BOOL)exportAMDISToFile:(NSString *)fileName {
	NSMutableString *outStr = [[NSMutableString alloc] init]; 
	NSArray *array;
	int i,j,count2;
	int count = [libraryArray count];
//	float retentionTime, retentionIndex;
	
	for (i=0; i < count; i++) {
		if ([[[libraryArray objectAtIndex:i] valueForKey:@"name"] isNotEqualTo:@""]) [outStr appendFormat:@"NAME: %@\r\n", [[libraryArray objectAtIndex:i] valueForKey:@"name"]];
		if ([[[libraryArray objectAtIndex:i] valueForKey:@"formula"] isNotEqualTo:@""])[outStr appendFormat:@"FORM: %@\r\n", [[libraryArray objectAtIndex:i] valueForKey:@"formula"]];
		if ([[[libraryArray objectAtIndex:i] valueForKey:@"CASNumber"] isNotEqualTo:@""])[outStr appendFormat:@"CASNO: %@\r\n", [[libraryArray objectAtIndex:i] valueForKey:@"CASNumber"]];
		if (![[[libraryArray objectAtIndex:i] valueForKey:@"retentionIndex"] isEqualToNumber:[NSNumber numberWithFloat:0.0]])[outStr appendFormat:@"RI: %.3f\r\n", [[[libraryArray objectAtIndex:i] valueForKey:@"retentionIndex"] floatValue]];
//		if (![[[libraryArray objectAtIndex:i] valueForKey:@"retentionTime"] isEqualToNumber:[NSNumber numberWithFloat:0.0]]) {
//			retentionTime = [[[libraryArray objectAtIndex:i] valueForKey:@"retentionTime"] floatValue];
//			retentionIndex = 0.0119 * pow(retentionTime,2) + 0.1337 * retentionTime + 8.1505;
//			[outStr appendFormat:@"RI: %.3f\r\n", retentionIndex*100];
//		}
		if (![[[libraryArray objectAtIndex:i] valueForKey:@"massWeight"] isEqualToNumber:[NSNumber numberWithFloat:0.0]])[outStr appendFormat:@"MW: %.0f\r\n", [[[libraryArray objectAtIndex:i] valueForKey:@"massWeight"] floatValue]];
		if (![[[libraryArray objectAtIndex:i] valueForKey:@"retentionWidth"] isEqualToNumber:[NSNumber numberWithFloat:0.0]])[outStr appendFormat:@"RW: %.3f\r\n", [[[libraryArray objectAtIndex:i] valueForKey:@"retentionWidth"] floatValue]];
		if (![[[libraryArray objectAtIndex:i] valueForKey:@"retentionTime"] isEqualToNumber:[NSNumber numberWithFloat:0.0]])[outStr appendFormat:@"RT: %.3f\r\n", [[[libraryArray objectAtIndex:i] valueForKey:@"retentionTime"] floatValue]];
		if ([[[libraryArray objectAtIndex:i] valueForKey:@"comment"] isNotEqualTo:@""])[outStr appendFormat:@"COMMENT: %@\r\n", [[libraryArray objectAtIndex:i] valueForKey:@"comment"]];
		if ([[[libraryArray objectAtIndex:i] valueForKey:@"source"] isNotEqualTo:@""])[outStr appendFormat:@"SOURCE: %@\r\n", [[libraryArray objectAtIndex:i] valueForKey:@"source"]];
		array = [[libraryArray objectAtIndex:i] valueForKey:@"points"];
		count2 = [array count];
		[outStr appendFormat:@"NUM PEAKS: %i\r\n", count2];
		for (j=0; j < count2; j++) {
			[outStr appendFormat:@"(%4.f, %4.f) ", [[[array objectAtIndex:j] valueForKey:@"Mass"] floatValue], [[[array objectAtIndex:j] valueForKey:@"Intensity"] floatValue]];
			if (fmod(j,5) == 4 && j != count2-1){
				[outStr appendString:@"\r\n"];
			}
		}
		[outStr appendString:@"\r\n\r\n"];
	}
	
	if ([outStr writeToFile:fileName atomically:NO encoding:NSASCIIStringEncoding error:nil]) {
		return YES;
	} else {
		NSRunInformationalAlertPanel(NSLocalizedString(@"File saved using UTF-8 encoding",@""),NSLocalizedString(@"Probably non-ASCII characters are used in entries of the library. Peacock will save the library in UTF-8 encoding instead of the prescribed ASCII encoding. In order to use this library in other applications the non-ASCII characters should probably be removed.",@""),NSLocalizedString(@"OK",@""),nil,nil);
		return [outStr writeToFile:fileName atomically:NO];
		
	}
}

#pragma mark ACCESSORS

-(NSMutableArray *)libraryArray {
	return libraryArray;
}
-(JKLibraryWindowController *)libraryWindowController {
	return libraryWindowController;
}

@end
