//
//  This file is part of the application with the working name:
//  Peacock
//
//  Created by Johan Kool.
//  Copyright 2003-2007 Johan Kool. All rights reserved.
//

#import "JKManagedLibraryEntry.h"

#import "MolTypes.h"
#import "CFragment.h"

@implementation JKManagedLibraryEntry

#pragma mark Initialization & deallocation
- (id)init {
	self = [super init];
    if (self != nil) {
        numberOfPoints = 0;
        masses = (float *) malloc(numberOfPoints*sizeof(float));
        intensities = (float *) malloc(numberOfPoints*sizeof(float));
        peakTableRead = NO;
    }
    return self;
}

- (void) dealloc {     
    [super dealloc];
}
#pragma mark -

#pragma mark Importing data
- (void)readPeakTable 
{
    NSString *currentPeakTable = [self primitiveValueForKey:@"peakTable"];
    if ((currentPeakTable == nil) || (![currentPeakTable isKindOfClass:[NSString class]])) {
        return;
    }
    
	NSScanner *theScanner = [[NSScanner alloc] initWithString:currentPeakTable];
	int j, massInt, intensityInt;
    
    // Check for silly HP JCAMP file
    if ([currentPeakTable rangeOfString:@","].location == NSNotFound) {
        numberOfPoints = [[currentPeakTable componentsSeparatedByString:@"\n"] count]-1;
    } else {
        numberOfPoints = [[currentPeakTable componentsSeparatedByString:@","] count]-1;
    }
    
    masses = (float *) realloc(masses, numberOfPoints*sizeof(float));
    intensities = (float *) realloc(intensities, numberOfPoints*sizeof(float));
	
	for (j=0; j < numberOfPoints; j++){
		if (![theScanner scanInt:&massInt]) JKLogError(@"Error during reading library (masses).");
		masses[j] = massInt*1.0f;
		[theScanner scanUpToCharactersFromSet:[NSCharacterSet decimalDigitCharacterSet] intoString:NULL];
		if (![theScanner scanInt:&intensityInt]) JKLogError(@"Error during reading library (intensities).");
		intensities[j] = intensityInt*1.0f;
	}
    
	[theScanner release];	
    
	NSMutableString *newPeakTable = [[[NSMutableString alloc] init] autorelease];
	for (j=0; j < numberOfPoints; j++) {
		[newPeakTable appendFormat:@"%.0f, %.0f ", masses[j], intensities[j]];
		if (fmod(j,8) == 7 && j != numberOfPoints-1){
			[newPeakTable appendString:@"\r\n"];
		}
	}
    
    if (peakTableRead) {
        NSAssert([currentPeakTable isEqualToString:newPeakTable], @"peakTable not stable");
    } else if (![currentPeakTable isEqualToString:newPeakTable]) {
        [self setPrimitiveValue:newPeakTable forKey:@"peakTable"];
    }
    
    peakTableRead = YES;
}


- (void)setJCAMPString:(NSString *)inString {
    if (!inString || [inString isEqualToString:@""]) {
        JKLogWarning(@"Empty JCAMPString encountered.");
        return;
    }
		
        NSCharacterSet *whiteCharacters = [NSCharacterSet whitespaceAndNewlineCharacterSet];
		NSScanner *theScanner = [[NSScanner alloc] initWithString:inString];
		
		NSString *xyData = @""; 
		NSString *scannedString = @"";
		float scannedFloat;
		
		// Remove all comments
		// Removing all comments is not yet implemented.
		
		// Reading header
		// Title
		[theScanner scanUpToString:@"##TITLE=" intoString:NULL];
		if ([theScanner scanString:@"##TITLE=" intoString:NULL]) {
            scannedString = @"";
			[theScanner scanUpToString:@"##" intoString:&scannedString];
            [self setName:[scannedString stringByTrimmingCharactersInSet:whiteCharacters]];
		} else {
			JKLogError(@"ERROR: Required ##TITLE entry not found.");
		}
		
//		// JCAMP-DX
//		// Back to start of entry as order of entries is undefined
//		[theScanner setScanLocation:0];
//		[theScanner scanUpToString:@"##JCAMP-DX=" intoString:NULL];
//		if ([theScanner scanString:@"##JCAMP-DX=" intoString:NULL]) {
//			[theScanner scanUpToString:@"##" intoString:&scannedString];
//			// Currently ignored, could test JCAMP-DX version here.
//		} else {
//			//JKLogWarning(@"WARNING: Required ##JCAMP-DX entry not found.");
//		}
		
		
		// ORIGIN
		// Back to start of entry as order of entries is undefined
		[theScanner setScanLocation:0];
		[theScanner scanUpToString:@"##ORIGIN=" intoString:NULL];
		if ([theScanner scanString:@"##ORIGIN=" intoString:NULL]) {
            scannedString = @"";
			if ([theScanner scanUpToString:@"##" intoString:&scannedString]) {
                [self setOrigin:[scannedString stringByTrimmingCharactersInSet:whiteCharacters]]; 
			} else {
			}
		} else {
			//JKLogWarning(@"WARNING: Required ##ORIGIN entry not found.");
		}
	
		// OWNER
		// Back to start of entry as order of entries is undefined
		[theScanner setScanLocation:0];
		[theScanner scanUpToString:@"##OWNER=" intoString:NULL];
		if ([theScanner scanString:@"##OWNER=" intoString:NULL]) {
            scannedString = @"";
			if ([theScanner scanUpToString:@"##" intoString:&scannedString]) {
				[self setOwner:[scannedString stringByTrimmingCharactersInSet:whiteCharacters]];
			} else {
			}
		} else {
			//JKLogWarning(@"WARNING: Required ##OWNER entry not found.");
		}
		
		// Reading chemical information
		// MOLFORM
		// Back to start of entry as order of entries is undefined
		[theScanner setScanLocation:0];
		[theScanner scanUpToString:@"##MOLFORM=" intoString:NULL];
		if ([theScanner scanString:@"##MOLFORM=" intoString:NULL]) {
            scannedString = @"";
			[theScanner scanUpToString:@"##" intoString:&scannedString];
			[self setFormula:[scannedString stringByTrimmingCharactersInSet:whiteCharacters]];
		} else {
		}
		
		
		// CAS NAME
		// Back to start of entry as order of entries is undefined
		[theScanner setScanLocation:0];
		[theScanner scanUpToString:@"##CAS NAME=" intoString:NULL];
		if ([theScanner scanString:@"##CAS NAME=" intoString:NULL]) {
            scannedString = @"";
			[theScanner scanUpToString:@"##" intoString:&scannedString];
			// CAS NAME overwrites title, but is often more useful anyway.
			[self setName:[scannedString stringByTrimmingCharactersInSet:whiteCharacters]];
		}		
		
		// CAS REGISTRY NO
		// Back to start of entry as order of entries is undefined
		[theScanner setScanLocation:0];
		[theScanner scanUpToString:@"##CAS REGISTRY NO=" intoString:NULL];
		if ([theScanner scanString:@"##CAS REGISTRY NO=" intoString:NULL]) {
            scannedString = @"";
			[theScanner scanUpToString:@"##" intoString:&scannedString];
			[self setCASNumber:[scannedString stringByTrimmingCharactersInSet:whiteCharacters]];
		} else {
		}

		// MOLSTRING
		// Back to start of entry as order of entries is undefined
		[theScanner setScanLocation:0];
		[theScanner scanUpToString:@"##$MOLSTRING=" intoString:NULL];
		if ([theScanner scanString:@"##$MOLSTRING=" intoString:NULL]) {
            scannedString = @"";
			[theScanner scanUpToString:@"##" intoString:&scannedString];
			[self setMolString:[scannedString stringByTrimmingCharactersInSet:whiteCharacters]];
		} else {
//			molString = [[NSString stringWithContentsOfURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://webbook.nist.gov/cgi/cbook.cgi/%@-2d.mol?Str2File=C%@",[self CASNumber],[self CASNumber]]]] retain];
//			JKLogDebug([NSString stringWithFormat:@"http://webbook.nist.gov/cgi/cbook.cgi/%@-2d.mol?Str2File=C%@",[self CASNumber],[self CASNumber]]);
//			JKLogDebug(molString);
		}
		
		// $EPA MASS SPEC NO
		// Back to start of entry as order of entries is undefined
		[theScanner setScanLocation:0];
		[theScanner scanUpToString:@"##$EPA MASS SPEC NO=" intoString:NULL];
		if ([theScanner scanString:@"##$EPA MASS SPEC NO=" intoString:NULL]) {
            scannedString = @"";
			[theScanner scanUpToString:@"##" intoString:&scannedString];
			[self setEpaMassSpecNo:[scannedString stringByTrimmingCharactersInSet:whiteCharacters]];
		} else {
		}
		
		// $NIST SOURCE
		// Back to start of entry as order of entries is undefined
		[theScanner setScanLocation:0];
		[theScanner scanUpToString:@"##$NIST SOURCE=" intoString:NULL];
		if ([theScanner scanString:@"##$NIST SOURCE=" intoString:NULL]) {
            scannedString = @"";
			[theScanner scanUpToString:@"##" intoString:&scannedString];
			[self setNistSource:[scannedString stringByTrimmingCharactersInSet:whiteCharacters]];
		} else {
		}

		// MW
		// Back to start of entry as order of entries is undefined
		[theScanner setScanLocation:0];
		[theScanner scanUpToString:@"##MW=" intoString:NULL];
		if ([theScanner scanString:@"##MW=" intoString:NULL]) {
			if ([theScanner scanFloat:&scannedFloat]) {
				[self setMassWeight:[NSNumber numberWithFloat:scannedFloat]];
			} else {
				[self setMassWeight:[self calculateMassWeight:[self formula]]];
			}
		} else {
            if ([self formula])
                [self setMassWeight:[self calculateMassWeight:[self formula]]];
		}	

		// RI
		// Back to start of entry as order of entries is undefined
		[theScanner setScanLocation:0];
		[theScanner scanUpToString:@"##RI=" intoString:NULL];
		if ([theScanner scanString:@"##RI=" intoString:NULL]) {
			if ([theScanner scanFloat:&scannedFloat]) {
				[self setRetentionIndex:[NSNumber numberWithFloat:scannedFloat]];
			} else {
				JKLogWarning(@"WARNING: Retention index could not be read.");
			}
		} else {
			[self setRetentionIndex:[NSNumber numberWithFloat:0.0f]];
		}
		
		// SOURCE
		// Back to start of entry as order of entries is undefined
		[theScanner setScanLocation:0];
		[theScanner scanUpToString:@"##SOURCE=" intoString:NULL];
		if ([theScanner scanString:@"##SOURCE=" intoString:NULL]) {
            scannedString = @"";
			[theScanner scanUpToString:@"##" intoString:&scannedString];
			[self setSource:[scannedString stringByTrimmingCharactersInSet:whiteCharacters]];
		} else {
		}
		
		// COMMENT        
		// Back to start of entry as order of entries is undefined
		[theScanner setScanLocation:0];
		[theScanner scanUpToString:@"##$COMMENT=" intoString:NULL];
		if ([theScanner scanString:@"##$COMMENT=" intoString:NULL]) {
            scannedString = @"";
			[theScanner scanUpToString:@"##" intoString:&scannedString];
			[self setComment:[scannedString stringByTrimmingCharactersInSet:whiteCharacters]];
		} else {
            // Back to start of entry as order of entries is undefined
            [theScanner setScanLocation:0];
            [theScanner scanUpToString:@"##COMMENT=" intoString:NULL];
            if ([theScanner scanString:@"##COMMENT=" intoString:NULL]) {
                scannedString = @"";
                [theScanner scanUpToString:@"##" intoString:&scannedString];
                [self setComment:[scannedString stringByTrimmingCharactersInSet:whiteCharacters]];
            }  else {
            }
        }

        // MODEL
        // Back to start of entry as order of entries is undefined
		[theScanner setScanLocation:0];
		[theScanner scanUpToString:@"##$MODEL=" intoString:NULL];
		if ([theScanner scanString:@"##$MODEL=" intoString:NULL]) {
            scannedString = @"";
			[theScanner scanUpToString:@"##" intoString:&scannedString];
			[self setModel:[scannedString stringByTrimmingCharactersInSet:whiteCharacters]];
		} else {
        }
        
        // GROUP
        // Back to start of entry as order of entries is undefined
		[theScanner setScanLocation:0];
		[theScanner scanUpToString:@"##$GROUP=" intoString:NULL];
		if ([theScanner scanString:@"##$GROUP=" intoString:NULL]) {
            scannedString = @"";
			[theScanner scanUpToString:@"##" intoString:&scannedString];
			[self setGroup:[scannedString stringByTrimmingCharactersInSet:whiteCharacters]];
		} else {
        }
        
        // SYNONYMS
        // Back to start of entry as order of entries is undefined
		[theScanner setScanLocation:0];
		[theScanner scanUpToString:@"##$SYNONYMS=" intoString:NULL];
		if ([theScanner scanString:@"##$SYNONYMS=" intoString:NULL]) {
            scannedString = @"";
			[theScanner scanUpToString:@"##" intoString:&scannedString];
			[self setSynonyms:[scannedString stringByTrimmingCharactersInSet:whiteCharacters]];
		} else {
        }
        
		// XUNITS
		// Back to start of entry as order of entries is undefined
		[theScanner setScanLocation:0];
		[theScanner scanUpToString:@"##XUNITS=" intoString:NULL];
		if ([theScanner scanString:@"##XUNITS=" intoString:NULL]) {
            scannedString = @"";
			[theScanner scanUpToString:@"##" intoString:&scannedString];
			[self setXUnits:[scannedString stringByTrimmingCharactersInSet:whiteCharacters]];
		} else {
        }
		
		// YUNITS
		// Back to start of entry as order of entries is undefined
		[theScanner setScanLocation:0];
		[theScanner scanUpToString:@"##YUNITS=" intoString:NULL];
		if ([theScanner scanString:@"##YUNITS=" intoString:NULL]) {
            scannedString = @"";
			[theScanner scanUpToString:@"##" intoString:&scannedString];
			[self setYUnits:[scannedString stringByTrimmingCharactersInSet:whiteCharacters]];
		} else {
        }
		
		// XFACTOR
		// Back to start of entry as order of entries is undefined
		[theScanner setScanLocation:0];
		[theScanner scanUpToString:@"##XFACTOR=" intoString:NULL];
		if ([theScanner scanString:@"##XFACTOR=" intoString:NULL]) {
			if ([theScanner scanFloat:&scannedFloat]) {
				[self setXFactor:[NSNumber numberWithFloat:scannedFloat]];
			}
		} else {
            [self setXFactor:[NSNumber numberWithFloat:1.0f]];
        }
		
		// YFACTOR
		// Back to start of entry as order of entries is undefined
		[theScanner setScanLocation:0];
		[theScanner scanUpToString:@"##YFACTOR=" intoString:NULL];
		if ([theScanner scanString:@"##YFACTOR=" intoString:NULL]) {
			if ([theScanner scanFloat:&scannedFloat]) {
				[self setYFactor:[NSNumber numberWithFloat:scannedFloat]];
			}
		} else {
            [self setYFactor:[NSNumber numberWithFloat:1.0f]];
        }
		
//		// DATA-TYPE
//		// Back to start of entry as order of entries is undefined
//		[theScanner setScanLocation:0];
//		[theScanner scanUpToString:@"##DATA TYPE=" intoString:NULL];
//		if ([theScanner scanString:@"##DATA TYPE=" intoString:NULL]) {
//			[theScanner scanUpToString:@"##" intoString:&scannedString];
//			scannedString = [scannedString stringByTrimmingCharactersInSet:whiteCharacters];
//			if (![scannedString isEqualToString:@"MASS SPECTRUM"]) {
//				JKLogError(@"ERROR: Unsupported ##DATA TYPE \"%@\" found.", scannedString);
//			}
//		} 
//		
//		// DATA-CLASS
//		// Back to start of entry as order of entries is undefined
//		[theScanner setScanLocation:0];
//		[theScanner scanUpToString:@"##DATA CLASS=" intoString:NULL];
//		if ([theScanner scanString:@"##DATA CLASS=" intoString:NULL]) {
//			[theScanner scanUpToString:@"##" intoString:&scannedString];
//			scannedString = [scannedString stringByTrimmingCharactersInSet:whiteCharacters];
//			if (!([scannedString isEqualToString:@"PEAK TABLE"] | [scannedString isEqualToString:@"XYDATA"])) {
//				JKLogError(@"ERROR: Unsupported ##DATA CLASS \"%@\" found.", scannedString);
//			}
//		}

		// NPOINTS
		// Back to start of entry as order of entries is undefined
		[theScanner setScanLocation:0];
		[theScanner scanUpToString:@"##NPOINTS=" intoString:NULL];
		if ([theScanner scanString:@"##NPOINTS=" intoString:NULL]) {
			if (![theScanner scanInt:&numberOfPoints]) {
				[self setNumberOfPoints:0];
			}
		} else {
			JKLogError(@"Couldn't find number of points.");
		}	
		
		// XYDATA
		// Back to start of entry as order of entries is undefined
		[theScanner setScanLocation:0];
		[theScanner scanUpToString:@"##XYDATA=" intoString:NULL];
		if ([theScanner scanString:@"##XYDATA=" intoString:NULL]) {
            scannedString = @"";
			[theScanner scanUpToString:@"\n" intoString:&scannedString];
			scannedString = [scannedString stringByTrimmingCharactersInSet:whiteCharacters];
			if (![scannedString isEqualToString:@"(XY..XY)"]) {
				JKLogError(@"ERROR: Unsupported ##XYDATA \"%@\" found.", scannedString);
			}
		} else {
			[theScanner setScanLocation:0];
			[theScanner scanUpToString:@"##PEAK TABLE=" intoString:NULL];
			if ([theScanner scanString:@"##PEAK TABLE=" intoString:NULL]) {
                scannedString = @"";
				[theScanner scanUpToString:@"\n" intoString:&scannedString];
				scannedString = [scannedString stringByTrimmingCharactersInSet:whiteCharacters];
				if (![scannedString isEqualToString:@"(XY..XY)"]) {
					JKLogError(@"ERROR: Unsupported ##PEAK TABLE \"%@\" found.", scannedString);
					}
			} else {
				JKLogError(@"ERROR: No data found. For Entry\n\n %@",inString);
			}
		}
		
		[theScanner scanUpToCharactersFromSet:[NSCharacterSet letterCharacterSet] intoString:&xyData];
        if ([xyData length] > 0) {
            [self setPeakTable:[xyData stringByTrimmingCharactersInSet:whiteCharacters]];            
        }
		
		[theScanner release];
}

- (NSString *)jcampString{
	NSMutableString *outStr = [[[NSMutableString alloc] init] autorelease];
    
    if (([[self name] isEqualToString:@""]) || (![self name])) {
        [outStr appendString:@"##TITLE= Untitled Entry\r\n"];	
    } else {
        [outStr appendFormat:@"##TITLE= %@\r\n", [self name]];	        
    }
	[outStr appendString:@"##JCAMP-DX= 4.24 $$ Peacock 0.24\r\n"];	
	[outStr appendString:@"##DATA TYPE= MASS SPECTRUM\r\n"];	
	[outStr appendString:@"##DATA CLASS= PEAK TABLE\r\n"];	
	if ([[self origin] isNotEqualTo:@""]) {
		[outStr appendFormat:@"##ORIGIN= %@\r\n", [self origin]];	
	} else {
		[outStr appendString:@"##ORIGIN=\r\n"];		
	}
	if ([[self owner] isNotEqualTo:@""]) {
		[outStr appendFormat:@"##OWNER= %@\r\n", [self owner]];	
	} else {
		[outStr appendString:@"##OWNER=\r\n"];		
	}
	
	if ([[self CASNumber] isNotEqualTo:@""])
		[outStr appendFormat:@"##CAS REGISTRY NO= %@\r\n", [self CASNumber]];
	if ([[self epaMassSpecNo] isNotEqualTo:@""])
		[outStr appendFormat:@"##$EPA MASS SPEC NO= %@\r\n", [self epaMassSpecNo]];
	if ([[self formula] isNotEqualTo:@""])
		[outStr appendFormat:@"##MOLFORM= %@\r\n", [self formula]];
	if (![[self massWeight] isEqualToNumber:[NSNumber numberWithFloat:0.0]])
		[outStr appendFormat:@"##MW= %.0f\r\n", [[self massWeight] floatValue]];
	if ([[self nistSource] isNotEqualTo:@""])
		[outStr appendFormat:@"##$NIST SOURCE= %@\r\n", [self nistSource]];
	if ([[self ionizationEnergy] isNotEqualTo:@""])
		[outStr appendFormat:@"##.IONIZATION ENERGY= %@\r\n", [self ionizationEnergy]];
	if ([[self xUnits] isNotEqualTo:@""])
		[outStr appendFormat:@"##XUNITS= %@\r\n", [self xUnits]];
	if ([[self yUnits] isNotEqualTo:@""])
		[outStr appendFormat:@"##YUNITS= %@\r\n", [self yUnits]];
	if (![[self xFactor] isEqualToNumber:[NSNumber numberWithFloat:0.0]])
		[outStr appendFormat:@"##XFACTOR= %.2f\r\n", [[self xFactor] floatValue]];
	if (![[self yFactor] isEqualToNumber:[NSNumber numberWithFloat:0.0]])
		[outStr appendFormat:@"##YFACTOR= %.2f\r\n", [[self yFactor] floatValue]];
	if (![[self retentionIndex] isEqualToNumber:[NSNumber numberWithFloat:0.0]])
		[outStr appendFormat:@"##RI= %.3f\r\n", [[self retentionIndex] floatValue]];
	if ([[self source] isNotEqualTo:@""])
		[outStr appendFormat:@"##SOURCE= %@\r\n", [self source]];
	if ([[self comment] isNotEqualTo:@""])
		[outStr appendFormat:@"##$COMMENT= %@\r\n", [self comment]];
	if ([[self molString] isNotEqualTo:@""])
		[outStr appendFormat:@"##$MOLSTRING= %@\r\n", [self molString]];
	if ([[self symbol] isNotEqualTo:@""])
		[outStr appendFormat:@"##$SYMBOL= %@\r\n", [self symbol]];
	if ([[self model] isNotEqualTo:@""])
		[outStr appendFormat:@"##$MODEL= %@\r\n", [self model]];
	if ([[self group] isNotEqualTo:@""])
		[outStr appendFormat:@"##$GROUP= %@\r\n", [self group]];
	if ([[self synonyms] isNotEqualTo:@""])
		[outStr appendFormat:@"##$SYNONYMS= %@\r\n", [self synonyms]];
	[outStr appendFormat:@"##$LIBRARY= %@\r\n", [self library]];
	
	[outStr appendFormat:@"##NPOINTS= %i\r\n##XYDATA= (XY..XY)\r\n%@\r\n", [self numberOfPoints], [self peakTable]];
	[outStr appendString:@"##END= \r\n"];
	return outStr;
}
#pragma mark -

#pragma mark Undo
- (NSUndoManager *)undoManager {
	return [[self managedObjectContext] undoManager];
}
#pragma mark -

#pragma mark Helper functions
- (NSString *)fixString:(NSString *)inString{
	NSString *fixedString = [inString lowercaseString];
	if ([fixedString length] > 1) {
		NSRange range4 = [fixedString rangeOfString:@"/"]; // don't swap, because probably two names are given
		if (range4.location == NSNotFound){
			// Swapping phenol stuff
			NSRange range = [fixedString rangeOfString:@", "];
			if (range.location != NSNotFound){
				NSRange range3 = [[fixedString substringToIndex:range.location] rangeOfCharacterFromSet:[NSCharacterSet letterCharacterSet]];
				if ((range3.location == 0) && (![[fixedString substringWithRange:NSMakeRange([fixedString length]-2,1)] isEqualToString:@")"])){
					fixedString = [NSString stringWithFormat:@"%@%@", [[fixedString substringFromIndex:range.location+2] stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"-"]], [fixedString substringToIndex:range.location]];
				} else {
					fixedString = [NSString stringWithFormat:@"%@%@", [fixedString substringFromIndex:range.location+2], [fixedString substringToIndex:range.location]];
					
				}
			}
		}
		// Capitalize first letter only
		//NSRange range2 = NSMakeRange(0,1);
		NSRange range2 = [fixedString rangeOfCharacterFromSet:[NSCharacterSet letterCharacterSet]];
		fixedString = [NSString stringWithFormat:@"%@%@%@", [fixedString substringToIndex:range2.location], [[fixedString substringWithRange:range2] uppercaseString], [fixedString substringFromIndex:range2.location+1]];
		//fixedString = [fixedString capitalizedString];
	}		
	if ([fixedString length] > 1) {
		
		NSRange range5 = [fixedString rangeOfString:@"N-c"]; //fizx n-alk
		if (range5.location == 0){
			fixedString = [NSString stringWithFormat:@"n-C%@", [fixedString substringFromIndex:3]];
		}
	}
	return fixedString;
}

- (NSNumber *)calculateMassWeight:(NSString *)inString {
	CFragment*	atom;
     
    if (CreateSymbolTable([[[[NSBundle mainBundle] resourcePath] stringByAppendingString:@"/periodic.table"] cString]) != 0) {
        printf("Unable to read periodic table.\n");
        return nil;
    }
	atom = [[CFragment alloc] initFromString:[inString cString]:NULL];
	
	return [NSNumber numberWithFloat:[atom calculateWeight]];
}

- (NSString *)legendEntry {
    return [NSString stringWithFormat:NSLocalizedString(@"Library Entry '%@'",@""),[self name]];
}

//- (IBAction)viewOnline{
//	[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://webbook.nist.gov/cgi/cbook.cgi?ID=%@&Units=SI",[self CASNumber]]]];
//}
//
//- (IBAction)downloadMolFile{
//	[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://webbook.nist.gov/cgi/cbook.cgi/%@-2d.mol?Str2File=C%@",[self CASNumber],[self CASNumber]]]];
//}
//
//- (IBAction)downloadMassSpectrum{
//	[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://webbook.nist.gov/cgi/cbook.cgi/%@-Mass.jdx?JCAMP=C%@&Index=0&Type=Mass",[self CASNumber],[self CASNumber]]]];
//}
- (NSString *)library
{
    id persistentStore = [[self objectID] persistentStore]; 
    if (persistentStore) {
        NSURL *url = [[[self managedObjectContext] persistentStoreCoordinator] URLForPersistentStore:persistentStore];
        return [[[url path] lastPathComponent] stringByDeletingPathExtension]; 
    }
    return @"";
}
#pragma mark -

#pragma mark Accessors (NSManagedObject style)
- (NSString *)name
{
    [self willAccessValueForKey:@"name"];
    NSString *n = [self primitiveValueForKey:@"name"];
    [self didAccessValueForKey:@"name"];
    return n;
}

- (void)setName:(NSString *)newName
{
    [self willChangeValueForKey:@"name"];
    [self setPrimitiveValue:newName forKey:@"name"];
    [self didChangeValueForKey:@"name"];
}

- (NSString *)origin
{
    [self willAccessValueForKey:@"origin"];
    NSString *n = [self primitiveValueForKey:@"origin"];
    [self didAccessValueForKey:@"origin"];
    return n;
}

- (void)setOrigin:(NSString *)neworigin
{
    [self willChangeValueForKey:@"origin"];
    [self setPrimitiveValue:neworigin forKey:@"origin"];
    [self didChangeValueForKey:@"origin"];
}

- (NSString *)owner
{
    [self willAccessValueForKey:@"owner"];
    NSString *n = [self primitiveValueForKey:@"owner"];
    [self didAccessValueForKey:@"owner"];
    return n;
}

- (void)setOwner:(NSString *)newowner
{
    [self willChangeValueForKey:@"owner"];
    [self setPrimitiveValue:newowner forKey:@"owner"];
    [self didChangeValueForKey:@"owner"];
}

- (NSString *)CASNumber
{
    [self willAccessValueForKey:@"CASNumber"];
    NSString *n = [self primitiveValueForKey:@"CASNumber"];
    [self didAccessValueForKey:@"CASNumber"];
    return n;
}

- (void)setCASNumber:(NSString *)newCASNumber
{
    [self willChangeValueForKey:@"CASNumber"];
    [self setPrimitiveValue:newCASNumber forKey:@"CASNumber"];
    [self didChangeValueForKey:@"CASNumber"];
}

- (NSString *)epaMassSpecNo
{
    [self willAccessValueForKey:@"epaMassSpecNo"];
    NSString *n = [self primitiveValueForKey:@"epaMassSpecNo"];
    [self didAccessValueForKey:@"epaMassSpecNo"];
    return n;
}

- (void)setEpaMassSpecNo:(NSString *)newepaMassSpecNo
{
    [self willChangeValueForKey:@"epaMassSpecNo"];
    [self setPrimitiveValue:newepaMassSpecNo forKey:@"epaMassSpecNo"];
    [self didChangeValueForKey:@"epaMassSpecNoepaMassSpecNo"];
}

- (NSString *)formula
{
    [self willAccessValueForKey:@"formula"];
    NSString *n = [self primitiveValueForKey:@"formula"];
    [self didAccessValueForKey:@"formula"];
    return n;
}

- (void)setFormula:(NSString *)newformula
{
    [self willChangeValueForKey:@"formula"];
    [self setPrimitiveValue:newformula forKey:@"formula"];
    [self didChangeValueForKey:@"formula"];
}

- (NSNumber *)massWeight
{
    [self willAccessValueForKey:@"massWeight"];
    NSNumber *n = [self primitiveValueForKey:@"massWeight"];
    [self didAccessValueForKey:@"massWeight"];
    return n;
}

- (void)setMassWeight:(NSNumber *)newmassWeight
{
    [self willChangeValueForKey:@"massWeight"];
    [self setPrimitiveValue:newmassWeight forKey:@"massWeight"];
    [self didChangeValueForKey:@"massWeight"];
}

- (NSString *)nistSource
{
    [self willAccessValueForKey:@"nistSource"];
    NSString *n = [self primitiveValueForKey:@"nistSource"];
    [self didAccessValueForKey:@"nistSource"];
    return n;
}

- (void)setNistSource:(NSString *)newnistSource
{
    [self willChangeValueForKey:@"nistSource"];
    [self setPrimitiveValue:newnistSource forKey:@"nistSource"];
    [self didChangeValueForKey:@"nistSource"];
}

- (NSString *)ionizationEnergy
{
    [self willAccessValueForKey:@"ionizationEnergy"];
    NSString *n = [self primitiveValueForKey:@"ionizationEnergy"];
    [self didAccessValueForKey:@"ionizationEnergy"];
    return n;
}

- (void)setIonizationEnergy:(NSString *)newionizationEnergy
{
    [self willChangeValueForKey:@"ionizationEnergy"];
    [self setPrimitiveValue:newionizationEnergy forKey:@"ionizationEnergy"];
    [self didChangeValueForKey:@"ionizationEnergy"];
}

- (NSString *)xUnits
{
    [self willAccessValueForKey:@"xUnits"];
    NSString *n = [self primitiveValueForKey:@"xUnits"];
    [self didAccessValueForKey:@"xUnits"];
    return n;
}

- (void)setXUnits:(NSString *)newxUnits
{
    [self willChangeValueForKey:@"xUnits"];
    [self setPrimitiveValue:newxUnits forKey:@"xUnits"];
    [self didChangeValueForKey:@"xUnits"];
}

- (NSString *)yUnits
{
    [self willAccessValueForKey:@"yUnits"];
    NSString *n = [self primitiveValueForKey:@"yUnits"];
    [self didAccessValueForKey:@"yUnits"];
    return n;
}

- (void)setYUnits:(NSString *)newyUnits
{
    [self willChangeValueForKey:@"yUnits"];
    [self setPrimitiveValue:newyUnits forKey:@"yUnits"];
    [self didChangeValueForKey:@"yUnits"];
}

- (NSNumber *)xFactor
{
    [self willAccessValueForKey:@"xFactor"];
    NSNumber *n = [self primitiveValueForKey:@"xFactor"];
    [self didAccessValueForKey:@"xFactor"];
    return n;
}

- (void)setXFactor:(NSNumber *)newxFactor
{
    [self willChangeValueForKey:@"xFactor"];
    [self setPrimitiveValue:newxFactor forKey:@"xFactor"];
    [self didChangeValueForKey:@"xFactor"];
}

- (NSNumber *)yFactor
{
    [self willAccessValueForKey:@"yFactor"];
    NSNumber *n = [self primitiveValueForKey:@"yFactor"];
    [self didAccessValueForKey:@"yFactor"];
    return n;
}

- (void)setYFactor:(NSNumber *)newyFactor
{
    [self willChangeValueForKey:@"yFactor"];
    [self setPrimitiveValue:newyFactor forKey:@"yFactor"];
    [self didChangeValueForKey:@"yFactor"];
}

- (NSNumber *)retentionIndex
{
    [self willAccessValueForKey:@"retentionIndex"];
    NSNumber *n = [self primitiveValueForKey:@"retentionIndex"];
    [self didAccessValueForKey:@"retentionIndex"];
    return n;
}

- (void)setRetentionIndex:(NSNumber *)newretentionIndex
{
    [self willChangeValueForKey:@"retentionIndex"];
    [self setPrimitiveValue:newretentionIndex forKey:@"retentionIndex"];
    [self didChangeValueForKey:@"retentionIndex"];
}

- (NSString *)source
{
    [self willAccessValueForKey:@"source"];
    NSString *n = [self primitiveValueForKey:@"source"];
    [self didAccessValueForKey:@"source"];
    return n;
}

- (void)setSource:(NSString *)newsource
{
    [self willChangeValueForKey:@"source"];
    [self setPrimitiveValue:newsource forKey:@"source"];
    [self didChangeValueForKey:@"source"];
}

- (NSString *)comment
{
    [self willAccessValueForKey:@"comment"];
    NSString *n = [self primitiveValueForKey:@"comment"];
    [self didAccessValueForKey:@"comment"];
    return n;
}

- (void)setComment:(NSString *)newcomment
{
    [self willChangeValueForKey:@"comment"];
    [self setPrimitiveValue:newcomment forKey:@"comment"];
    [self didChangeValueForKey:@"comment"];
}

- (NSString *)molString
{
    [self willAccessValueForKey:@"molString"];
    NSString *n = [self primitiveValueForKey:@"molString"];
    [self didAccessValueForKey:@"molString"];
    return n;
}

- (void)setMolString:(NSString *)newmolString
{
    [self willChangeValueForKey:@"molString"];
    [self setPrimitiveValue:newmolString forKey:@"molString"];
    [self didChangeValueForKey:@"molString"];
}

- (NSString *)symbol
{
    [self willAccessValueForKey:@"symbol"];
    NSString *n = [self primitiveValueForKey:@"symbol"];
    [self didAccessValueForKey:@"symbol"];
    return n;
}

- (void)setSymbol:(NSString *)newsymbol
{
    [self willChangeValueForKey:@"symbol"];
    [self setPrimitiveValue:newsymbol forKey:@"symbol"];
    [self didChangeValueForKey:@"symbol"];
}

- (NSString *)model
{
    [self willAccessValueForKey:@"model"];
    NSString *n = [self primitiveValueForKey:@"model"];
    [self didAccessValueForKey:@"model"];
    return n;
}

- (void)setModel:(NSString *)newmodel
{
    [self willChangeValueForKey:@"model"];
    [self setPrimitiveValue:newmodel forKey:@"model"];
    [self didChangeValueForKey:@"model"];
}

- (NSString *)group
{
    [self willAccessValueForKey:@"group"];
    NSString *n = [self primitiveValueForKey:@"group"];
    [self didAccessValueForKey:@"group"];
    return n;
}

- (void)setGroup:(NSString *)newgroup
{
    [self willChangeValueForKey:@"group"];
    [self setPrimitiveValue:newgroup forKey:@"group"];
    [self didChangeValueForKey:@"group"];
}

- (NSString *)synonyms
{
    [self willAccessValueForKey:@"synonyms"];
    NSString *n = [self primitiveValueForKey:@"synonyms"];
    [self didAccessValueForKey:@"synonyms"];
    return n;
}

- (void)setSynonyms:(NSString *)newsynonyms
{
    [self willChangeValueForKey:@"synonyms"];
    [self setPrimitiveValue:newsynonyms forKey:@"synonyms"];
    [self didChangeValueForKey:@"synonyms"];
}

- (int)numberOfPoints
{
    [self willAccessValueForKey:@"numberOfPoints"];
    int f = numberOfPoints;
    [self didAccessValueForKey:@"numberOfPoints"];
    return f;
}

- (void)setNumberOfPoints:(int)newnumberOfPoints
{
    [self willChangeValueForKey:@"numberOfPoints"];
    numberOfPoints = newnumberOfPoints;
    [self didChangeValueForKey:@"numberOfPoints"];
}

- (float *)masses {
    if (!peakTableRead)
        [self readPeakTable];
    return masses;
}

- (float *)intensities {
    if (!peakTableRead)
        [self readPeakTable];
    return intensities;
}

- (NSString *)peakTable{
    [self willAccessValueForKey:@"peakTable"];
    NSString *n = [self primitiveValueForKey:@"peakTable"];
    [self didAccessValueForKey:@"peakTable"];
    return n;
}

- (void)setPeakTable:(NSString *)newPeakTable {
    [self willChangeValueForKey:@"peakTable"];
    [self setPrimitiveValue:newPeakTable forKey:@"peakTable"];
    peakTableRead = NO;
    [self didChangeValueForKey:@"peakTable"];
}
#pragma mark -

#pragma mark Encoding
- (void)encodeWithCoder:(NSCoder *)coder{
    if ( [coder allowsKeyedCoding] ) { // Assuming 10.2 is quite safe!!
        [coder encodeInt:2 forKey:@"version"];
		[coder encodeObject:[self jcampString] forKey:@"jcampString"];
    } 
    return;
}

- (id)initWithCoder:(NSCoder *)coder{
    if ( [coder allowsKeyedCoding] ) {
		int version = [coder decodeIntForKey:@"version"];
		
		if (version >= 2) {
            [self setJCAMPString:[coder decodeObjectForKey:@"jcampString"]];
			return self;
		} else  {
            return nil;
		}
     } 
    return self;
}
#pragma mark -

//#pragma mark Debugging
//- (id)valueForUndefinedKey:(NSString *)key {
//    JKLogDebug(@"%@ %@",[self description], key);
//    return key;
//}
//- (void)setValue:(id)value forUndefinedKey:(NSString *)key {
//    JKLogDebug(@"%@ %@ %@",[self description], key, value);
//}

@end
