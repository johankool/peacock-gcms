//
//  This file is part of the application with the working name:
//  Peacock
//
//  Created by Johan Kool.
//  Copyright 2003-2007 Johan Kool. All rights reserved.
//

#import "JKLibrary.h"
#import "JKLibraryWindowController.h"
#import "JKLibraryEntry.h"

@implementation JKLibrary

#pragma mark INITIALIZATION

- (id)init {
	self = [super init];
    if (self != nil) {
        libraryWindowController = [[JKLibraryWindowController alloc] init];
		libraryEntries = [[NSMutableArray alloc] init];
    }
    return self;
}

- (void)makeWindowControllers {
    [self addWindowController:libraryWindowController];
}

#pragma mark OPEN/SAVE DOCUMENT

- (BOOL)writeToFile:(NSString *)fileName ofType:(NSString *)docType {
	if ([docType isEqualToString:@"JCAMP Library"]) {
		return [self exportJCAMPToFile:fileName];
	} else if ([docType isEqualToString:@"AMDIS Target Library"]) {
		return [self exportAMDISToFile:fileName];
	}
    return NO;
}

- (BOOL)readFromURL:(NSURL *)absoluteURL ofType:(NSString *)typeName error:(NSError **)outError{
	if ([typeName isEqualToString:@"JCAMP Library"]) {
        unsigned int usedEncoding;
        NSString *inString = [NSString stringWithContentsOfURL:absoluteURL usedEncoding:&usedEncoding error:outError];
		if (!inString) {
			JKLogWarning(@"Library encoding is not recognized, trying as UTF8.");
			inString = [NSString stringWithContentsOfURL:absoluteURL encoding:NSUTF8StringEncoding error:outError];
		}
		if (!inString) {
			JKLogWarning(@"Library is not readable as UTF8, perhaps as ASCII?");
			inString = [NSString stringWithContentsOfURL:absoluteURL encoding:NSASCIIStringEncoding error:outError];
		}
		if (!inString) {
			return NO;
		}
		libraryEntries = [[self readJCAMPString:inString] retain];

		return YES;
	} else if ([typeName isEqualToString:@"Inchi File"]) {
		NSString *CASNumber = [[[absoluteURL path] lastPathComponent] stringByDeletingPathExtension];
		NSString *jcampString = [NSString stringWithContentsOfURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://webbook.nist.gov/cgi/cbook.cgi/%@-Mass.jdx?JCAMP=C%@&Index=0&Type=Mass",CASNumber,CASNumber]]];
		JKLibraryEntry *entry = [[JKLibraryEntry alloc] initWithJCAMPString:jcampString];
		[entry setMolString:[NSString stringWithContentsOfURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://webbook.nist.gov/cgi/cbook.cgi/%@-2d.mol?Str2File=C%@",CASNumber,CASNumber]]]];
		
		libraryEntries = [[NSMutableArray arrayWithObject:entry] retain];
		
		return YES;
	}
//	else if ([docType isEqualToString:@"AMDIS Target Library"]) {
//		return [self importAMDISFromFile:fileName];
//	}
    return NO;
}

#pragma mark KEY VALUE CODING/OBSERVING

- (void)changeKeyPath:(NSString *)keyPath ofObject:(id)object toValue:(id)newValue{
	[object setValue:newValue forKeyPath:keyPath];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context{
	NSUndoManager *undo = [self undoManager];
	id oldValue = [change objectForKey:NSKeyValueChangeOldKey];
	[[undo prepareWithInvocationTarget:self] changeKeyPath:keyPath ofObject:object toValue:oldValue];
	
	[undo setActionName:@"Edit"];
}

#pragma mark IMPORT/EXPORT ACTIONS

- (NSArray *)readJCAMPString:(NSString *)inString {
	int count,i;
    BOOL sillyHPJCAMP;
    NSArray *array;
	NSMutableArray *libraryEntriesInString = [[NSMutableArray alloc] init];
	NSCharacterSet *whiteCharacters = [NSCharacterSet whitespaceAndNewlineCharacterSet];
    // Check for silly HP JCAMP file
    if ([inString rangeOfString:@"##END="].location == NSNotFound) {
        array = [inString componentsSeparatedByString:@"##TITLE="];
        sillyHPJCAMP = YES;
    } else {
        array = [inString componentsSeparatedByString:@"##END="];
        sillyHPJCAMP = NO;
    }
    
	JKLibraryEntry *libEntry;
	
	count = [array count];
	
	// We *could* ignore the last entry in the array, because it likely isn't complete 
	// NOTE: we now require at least a return after the last entry in the file or we won't read that entry
	for (i=0; i < count; i++) {
		// If we are dealing with an empty string, bail out
		if ((![[[array objectAtIndex:i] stringByTrimmingCharactersInSet:whiteCharacters] isEqualToString:@""]) && (![[array objectAtIndex:i] isEqualToString:@""])) {
            if (sillyHPJCAMP) {
                libEntry = [[JKLibraryEntry alloc] initWithJCAMPString:[[NSString stringWithString:@"##TITLE="] stringByAppendingString:[array objectAtIndex:i]]];
            } else {
                libEntry = [[JKLibraryEntry alloc] initWithJCAMPString:[array objectAtIndex:i]];                
            }
            [libEntry setDocument:self];
            [libraryEntriesInString addObject:libEntry];
            [libEntry release];
		}
    }
		
//	JKLogDebug(@"Found %d entries", [libraryEntries count]);
	[libraryEntriesInString autorelease];
    return libraryEntriesInString;	
}

- (BOOL)importJCAMPFromFile:(NSString *)fileName {
	NSString *inString = [NSString stringWithContentsOfFile:fileName encoding:NSUTF8StringEncoding error:NULL];
	libraryEntries = [[self readJCAMPString:inString] retain];
	return YES;		
}

- (BOOL)exportJCAMPToFile:(NSString *)fileName {
	NSMutableString *outStr = [[[NSMutableString alloc] init] autorelease]; 
	int i;
	int count = [libraryEntries count];
	
	for (i=0; i < count; i++) {
		[outStr appendString:[[libraryEntries objectAtIndex:i] jcampString]];
	}
	
	if ([outStr writeToFile:fileName atomically:NO encoding:NSASCIIStringEncoding error:nil]) {
		return YES;
	} else {
		NSRunInformationalAlertPanel(NSLocalizedString(@"File saved using UTF-8 encoding",@""),NSLocalizedString(@"Probably non-ASCII characters are used in entries of the library. Peacock will save the library in UTF-8 encoding instead of the prescribed ASCII encoding. In order to use this library in other applications the non-ASCII characters should probably be removed.",@""),NSLocalizedString(@"OK",@""),nil,nil);
		return [outStr writeToFile:fileName atomically:NO];		
	}
}

- (BOOL)importAMDISFromFile:(NSString *)fileName {
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
		[libraryEntries addObject:mutDict];
		[mutDict release];
//		[theScanner release];
    }

    return YES;
}

- (BOOL)exportAMDISToFile:(NSString *)fileName {
	NSMutableString *outStr = [[NSMutableString alloc] init]; 
	NSArray *array;
	int i,j,count2;
	int count = [libraryEntries count];
//	float retentionTime, retentionIndex;
	
	for (i=0; i < count; i++) {
		if ([[[libraryEntries objectAtIndex:i] valueForKey:@"name"] isNotEqualTo:@""]) [outStr appendFormat:@"NAME: %@\r\n", [[libraryEntries objectAtIndex:i] valueForKey:@"name"]];
		if ([[[libraryEntries objectAtIndex:i] valueForKey:@"formula"] isNotEqualTo:@""])[outStr appendFormat:@"FORM: %@\r\n", [[libraryEntries objectAtIndex:i] valueForKey:@"formula"]];
		if ([[[libraryEntries objectAtIndex:i] valueForKey:@"CASNumber"] isNotEqualTo:@""])[outStr appendFormat:@"CASNO: %@\r\n", [[libraryEntries objectAtIndex:i] valueForKey:@"CASNumber"]];
		if (![[[libraryEntries objectAtIndex:i] valueForKey:@"retentionIndex"] isEqualToNumber:[NSNumber numberWithFloat:0.0]])[outStr appendFormat:@"RI: %.3f\r\n", [[[libraryEntries objectAtIndex:i] valueForKey:@"retentionIndex"] floatValue]];
//		if (![[[libraryEntries objectAtIndex:i] valueForKey:@"retentionTime"] isEqualToNumber:[NSNumber numberWithFloat:0.0]]) {
//			retentionTime = [[[libraryEntries objectAtIndex:i] valueForKey:@"retentionTime"] floatValue];
//			retentionIndex = 0.0119 * pow(retentionTime,2) + 0.1337 * retentionTime + 8.1505;
//			[outStr appendFormat:@"RI: %.3f\r\n", retentionIndex*100];
//		}
		if (![[[libraryEntries objectAtIndex:i] valueForKey:@"massWeight"] isEqualToNumber:[NSNumber numberWithFloat:0.0]])[outStr appendFormat:@"MW: %.0f\r\n", [[[libraryEntries objectAtIndex:i] valueForKey:@"massWeight"] floatValue]];
		if (![[[libraryEntries objectAtIndex:i] valueForKey:@"retentionWidth"] isEqualToNumber:[NSNumber numberWithFloat:0.0]])[outStr appendFormat:@"RW: %.3f\r\n", [[[libraryEntries objectAtIndex:i] valueForKey:@"retentionWidth"] floatValue]];
		if (![[[libraryEntries objectAtIndex:i] valueForKey:@"retentionTime"] isEqualToNumber:[NSNumber numberWithFloat:0.0]])[outStr appendFormat:@"RT: %.3f\r\n", [[[libraryEntries objectAtIndex:i] valueForKey:@"retentionTime"] floatValue]];
		if ([[[libraryEntries objectAtIndex:i] valueForKey:@"comment"] isNotEqualTo:@""])[outStr appendFormat:@"COMMENT: %@\r\n", [[libraryEntries objectAtIndex:i] valueForKey:@"comment"]];
		if ([[[libraryEntries objectAtIndex:i] valueForKey:@"source"] isNotEqualTo:@""])[outStr appendFormat:@"SOURCE: %@\r\n", [[libraryEntries objectAtIndex:i] valueForKey:@"source"]];
		array = [[libraryEntries objectAtIndex:i] valueForKey:@"points"];
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

- (NSMutableArray *)libraryEntries {
	return libraryEntries;
}
- (JKLibraryWindowController *)libraryWindowController {
	return libraryWindowController;
}

- (void)setLibraryEntries:(NSMutableArray *)array{
	if (array == libraryEntries)
		return;
    
	// Add the inverse action to the undo stack
	NSUndoManager *undo = [self undoManager];
	[[undo prepareWithInvocationTarget:self] setLibraryEntries:libraryEntries];
	
	if (![undo isUndoing]) {
		[undo setActionName:NSLocalizedString(@"Set LibraryEntries",@"")];
	}
	
	NSEnumerator *e = [libraryEntries objectEnumerator];
	JKLibraryEntry *libraryEntry;
//	while ((libraryEntry = [e nextObject])) {
////		[self stopObservingLibraryEntry:libraryEntry];
//	}
	
	[libraryEntries release];
	[array retain];
	libraryEntries = array;
    
	e = [libraryEntries objectEnumerator];
	while ((libraryEntry = [e nextObject])) {
        [libraryEntry setDocument:self];
	}
}

- (void)insertObject:(JKLibraryEntry *)libraryEntry inLibraryEntriesAtIndex:(int)index{
	// Add the inverse action to the undo stack
	NSUndoManager *undo = [self undoManager];
	[[undo prepareWithInvocationTarget:self] removeObjectFromLibraryEntriesAtIndex:index];
	
	if (![undo isUndoing]) {
		[undo setActionName:NSLocalizedString(@"Insert Library Entry",@"")];
	}
	
	// Add the libraryEntry to the array
    [libraryEntry setDocument:self];
	[libraryEntries insertObject:libraryEntry atIndex:index];
}

- (void)removeObjectFromLibraryEntriesAtIndex:(int)index{
	JKLibraryEntry *libraryEntry = [libraryEntries objectAtIndex:index];
	
	// Add the inverse action to the undo stack
	NSUndoManager *undo = [self undoManager];
	[[undo prepareWithInvocationTarget:self] insertObject:libraryEntry inLibraryEntriesAtIndex:index];
	
	if (![undo isUndoing]) {
		[undo setActionName:NSLocalizedString(@"Delete Library Entry",@"")];
	}
	
	// Remove the libraryEntry from the array
	[libraryEntries removeObjectAtIndex:index];
}

@end
