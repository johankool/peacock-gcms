//
//  This file is part of the application with the working name:
//  Peacock
//
//  Created by Johan Kool.
//  Copyright 2003-2007 Johan Kool. All rights reserved.
//

#import "JKLibraryEntry.h"

#import "JKLibrary.h"
#import "PKSpectrumDataSeries.h"
#import "jk_statistics.h"
#include "CFragment.h"
#include "MolTypes.h"


@implementation JKLibraryEntry

+ (id)libraryEntryWithJCAMPString:(NSString *)inString 
{
    return [[[[self class] alloc] initWithJCAMPString:inString] autorelease];
}

- (id)initWithJCAMPString:(NSString *)inString{
	self = [super init];
    if (self != nil) {
        NSAssert(inString != nil, @"JKLibraryEntry inited with nil inString");
        if ([inString isEqualToString:@""]) {
            return nil;
        }
        
        NSAssert1(![inString isEqualToString:@""], @"JKLibraryEntry inited with empty inString %@", inString);
		
        NSCharacterSet *whiteCharacters = [NSCharacterSet whitespaceAndNewlineCharacterSet];
		NSScanner *theScanner = [[NSScanner alloc] initWithString:inString];
//		name = @"";			// ##TITLE=
//		origin = @"";		// ##ORIGIN=
//		owner = @"";		// ##OWNER=
//		CASNumber = @"";	// ##CAS REGISTRY NO=
//		epaMassSpecNo = @"";// ##$EPA MASS SPEC NO=
//		formula = @"";		// ##MOLFORM=
//		massWeight = [[NSNumber alloc] initWithFloat:0.0f];	// ##MW=
//		nistSource = @"";	// ##$NIST SOURCE=
//		ionizationEnergy = @""; // ##.IONIZATION ENERGY=
//		xUnits = @"";		// ##XUNITS=
//		yUnits = @"";		// ##YUNITS=
//		xFactor = [[NSNumber alloc] initWithFloat:0.0f];		// ##XFACTOR=
//		yFactor = [[NSNumber alloc] initWithFloat:0.0f];		// ##YFACTOR=
//		retentionIndex = [[NSNumber alloc] initWithFloat:0.0f]; // ##RI=
//		source = @"";		// ##SOURCE=
//		comment = @"";		// ##$COMMENT=
//		molString = @"";	// ##$MOLSTRING=
//		symbol = @"";		// ##$SYMBOL=
		
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
//			name = [[self fixString:[scannedString stringByTrimmingCharactersInSet:whiteCharacters]] retain];
			name = [[scannedString stringByTrimmingCharactersInSet:whiteCharacters] retain];
		} else {
			name = [[NSString alloc] init];
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
				origin = [[scannedString stringByTrimmingCharactersInSet:whiteCharacters] retain];				
			} else {
				origin = [[NSString alloc] initWithString:@""];
			}
		} else {
			origin = [[NSString alloc] initWithString:@""];
			//JKLogWarning(@"WARNING: Required ##ORIGIN entry not found.");
		}
	
		// OWNER
		// Back to start of entry as order of entries is undefined
		[theScanner setScanLocation:0];
		[theScanner scanUpToString:@"##OWNER=" intoString:NULL];
		if ([theScanner scanString:@"##OWNER=" intoString:NULL]) {
            scannedString = @"";
			if ([theScanner scanUpToString:@"##" intoString:&scannedString]) {
				owner = [[scannedString stringByTrimmingCharactersInSet:whiteCharacters] retain];
			} else {
				owner = [[NSString alloc] initWithString:@""];
			}
		} else {
			owner = [[NSString alloc] initWithString:@""];
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
			formula = [[scannedString stringByTrimmingCharactersInSet:whiteCharacters] retain];
		} else {
			formula = [[NSString alloc] init];
		}
		
		
		// CAS NAME
		// Back to start of entry as order of entries is undefined
		[theScanner setScanLocation:0];
		[theScanner scanUpToString:@"##CAS NAME=" intoString:NULL];
		if ([theScanner scanString:@"##CAS NAME=" intoString:NULL]) {
            scannedString = @"";
			[theScanner scanUpToString:@"##" intoString:&scannedString];
			// CAS NAME overwrites title, but is often more useful anyway.
			[name release];
			name = [[scannedString stringByTrimmingCharactersInSet:whiteCharacters] retain];
		}		
		
		// CAS REGISTRY NO
		// Back to start of entry as order of entries is undefined
		[theScanner setScanLocation:0];
		[theScanner scanUpToString:@"##CAS REGISTRY NO=" intoString:NULL];
		if ([theScanner scanString:@"##CAS REGISTRY NO=" intoString:NULL]) {
            scannedString = @"";
			[theScanner scanUpToString:@"##" intoString:&scannedString];
			CASNumber = [[scannedString stringByTrimmingCharactersInSet:whiteCharacters] retain];
		} else {
			CASNumber = [[NSString alloc] init];
		}

		// MOLSTRING
		// Back to start of entry as order of entries is undefined
		[theScanner setScanLocation:0];
		[theScanner scanUpToString:@"##$MOLSTRING=" intoString:NULL];
		if ([theScanner scanString:@"##$MOLSTRING=" intoString:NULL]) {
            scannedString = @"";
			[theScanner scanUpToString:@"##" intoString:&scannedString];
			molString = [[scannedString stringByTrimmingCharactersInSet:whiteCharacters] retain];
		} else {
			molString = [[NSString alloc] init];
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
			epaMassSpecNo = [[scannedString stringByTrimmingCharactersInSet:whiteCharacters] retain];
		} else {
			epaMassSpecNo = [[NSString alloc] init];
		}
		
		// $NIST SOURCE
		// Back to start of entry as order of entries is undefined
		[theScanner setScanLocation:0];
		[theScanner scanUpToString:@"##$NIST SOURCE=" intoString:NULL];
		if ([theScanner scanString:@"##$NIST SOURCE=" intoString:NULL]) {
            scannedString = @"";
			[theScanner scanUpToString:@"##" intoString:&scannedString];
			nistSource = [[scannedString stringByTrimmingCharactersInSet:whiteCharacters] retain];
		} else {
			nistSource = [[NSString alloc] init];
		}

		// MW
		// Back to start of entry as order of entries is undefined
		[theScanner setScanLocation:0];
		[theScanner scanUpToString:@"##MW=" intoString:NULL];
		if ([theScanner scanString:@"##MW=" intoString:NULL]) {
			if ([theScanner scanFloat:&scannedFloat]) {
				massWeight = [[NSNumber numberWithFloat:scannedFloat] retain];
			} else {
				massWeight = [[self calculateMassWeight:formula] retain];
			}
		} else {
			massWeight = [[self calculateMassWeight:formula] retain];
		}	

		// RI
		// Back to start of entry as order of entries is undefined
		[theScanner setScanLocation:0];
		[theScanner scanUpToString:@"##RI=" intoString:NULL];
		if ([theScanner scanString:@"##RI=" intoString:NULL]) {
			if ([theScanner scanFloat:&scannedFloat]) {
				retentionIndex = [[NSNumber numberWithFloat:scannedFloat] retain];
			} else {
				JKLogWarning(@"WARNING: Retention index could not be read.");
			}
		} else {
			retentionIndex = [[NSNumber numberWithFloat:0.0f] retain];
		}
		
		// SOURCE
		// Back to start of entry as order of entries is undefined
		[theScanner setScanLocation:0];
		[theScanner scanUpToString:@"##SOURCE=" intoString:NULL];
		if ([theScanner scanString:@"##SOURCE=" intoString:NULL]) {
            scannedString = @"";
			[theScanner scanUpToString:@"##" intoString:&scannedString];
			source = [[scannedString stringByTrimmingCharactersInSet:whiteCharacters] retain];
		} else {
			source = [[NSString alloc] init];
		}
		
		// COMMENT        
		// Back to start of entry as order of entries is undefined
		[theScanner setScanLocation:0];
		[theScanner scanUpToString:@"##$COMMENT=" intoString:NULL];
		if ([theScanner scanString:@"##$COMMENT=" intoString:NULL]) {
            scannedString = @"";
			[theScanner scanUpToString:@"##" intoString:&scannedString];
			comment = [[scannedString stringByTrimmingCharactersInSet:whiteCharacters] retain];
		} else {
            // Back to start of entry as order of entries is undefined
            [theScanner setScanLocation:0];
            [theScanner scanUpToString:@"##COMMENT=" intoString:NULL];
            if ([theScanner scanString:@"##COMMENT=" intoString:NULL]) {
                scannedString = @"";
                [theScanner scanUpToString:@"##" intoString:&scannedString];
                comment = [[scannedString stringByTrimmingCharactersInSet:whiteCharacters] retain];
            }  else {
                comment = [[NSString alloc] init];
            }
        }

        // MODEL
        // Back to start of entry as order of entries is undefined
		[theScanner setScanLocation:0];
		[theScanner scanUpToString:@"##$MODEL=" intoString:NULL];
		if ([theScanner scanString:@"##$MODEL=" intoString:NULL]) {
            scannedString = @"";
			[theScanner scanUpToString:@"##" intoString:&scannedString];
			model = [[scannedString stringByTrimmingCharactersInSet:whiteCharacters] retain];
		} else {
            model = [[NSString alloc] init];
        }
        
        // SYMBOL
        // Back to start of entry as order of entries is undefined
		[theScanner setScanLocation:0];
		[theScanner scanUpToString:@"##$SYMBOL=" intoString:NULL];
		if ([theScanner scanString:@"##$SYMBOL=" intoString:NULL]) {
            scannedString = @"";
			[theScanner scanUpToString:@"##" intoString:&scannedString];
			symbol = [[scannedString stringByTrimmingCharactersInSet:whiteCharacters] retain];
		} else {
            symbol = [[NSString alloc] init];
        }
        
        // GROUP
        // Back to start of entry as order of entries is undefined
		[theScanner setScanLocation:0];
		[theScanner scanUpToString:@"##$GROUP=" intoString:NULL];
		if ([theScanner scanString:@"##$GROUP=" intoString:NULL]) {
            scannedString = @"";
			[theScanner scanUpToString:@"##" intoString:&scannedString];
			group = [[scannedString stringByTrimmingCharactersInSet:whiteCharacters] retain];
		} else {
            group = [[NSString alloc] init];
        }
        
        // SYNONYMS
        // Back to start of entry as order of entries is undefined
		[theScanner setScanLocation:0];
		[theScanner scanUpToString:@"##$SYNONYMS=" intoString:NULL];
		if ([theScanner scanString:@"##$SYNONYMS=" intoString:NULL]) {
            scannedString = @"";
			[theScanner scanUpToString:@"##" intoString:&scannedString];
			synonyms = [[scannedString stringByTrimmingCharactersInSet:whiteCharacters] retain];
		} else {
            synonyms = [[NSString alloc] init];
        }
        
        // LIBRARY
        // Back to start of entry as order of entries is undefined
		[theScanner setScanLocation:0];
		[theScanner scanUpToString:@"##$LIBRARY=" intoString:NULL];
		if ([theScanner scanString:@"##$LIBRARY=" intoString:NULL]) {
            scannedString = @"";
			[theScanner scanUpToString:@"##" intoString:&scannedString];
			library = [[scannedString stringByTrimmingCharactersInSet:whiteCharacters] retain];
		} else {
            library = [[NSString alloc] init];
        }
        
		// XUNITS
		// Back to start of entry as order of entries is undefined
		[theScanner setScanLocation:0];
		[theScanner scanUpToString:@"##XUNITS=" intoString:NULL];
		if ([theScanner scanString:@"##XUNITS=" intoString:NULL]) {
            scannedString = @"";
			[theScanner scanUpToString:@"##" intoString:&scannedString];
			xUnits = [[scannedString stringByTrimmingCharactersInSet:whiteCharacters] retain];
		} else {
            xUnits = [[NSString alloc] init];
        }
		
		// YUNITS
		// Back to start of entry as order of entries is undefined
		[theScanner setScanLocation:0];
		[theScanner scanUpToString:@"##YUNITS=" intoString:NULL];
		if ([theScanner scanString:@"##YUNITS=" intoString:NULL]) {
            scannedString = @"";
			[theScanner scanUpToString:@"##" intoString:&scannedString];
			yUnits = [[scannedString stringByTrimmingCharactersInSet:whiteCharacters] retain];
		} else {
            yUnits = [[NSString alloc] init];
        }
		
		// XFACTOR
		// Back to start of entry as order of entries is undefined
		[theScanner setScanLocation:0];
		[theScanner scanUpToString:@"##XFACTOR=" intoString:NULL];
		if ([theScanner scanString:@"##XFACTOR=" intoString:NULL]) {
			if ([theScanner scanFloat:&scannedFloat]) {
				xFactor = [[NSNumber numberWithFloat:scannedFloat] retain];
			}
		} else {
            xFactor = [[NSNumber alloc] initWithFloat:1.0f];
        }
		
		// YFACTOR
		// Back to start of entry as order of entries is undefined
		[theScanner setScanLocation:0];
		[theScanner scanUpToString:@"##YFACTOR=" intoString:NULL];
		if ([theScanner scanString:@"##YFACTOR=" intoString:NULL]) {
			if ([theScanner scanFloat:&scannedFloat]) {
				yFactor = [[NSNumber numberWithFloat:scannedFloat] retain];
			}
		} else {
            yFactor = [[NSNumber alloc] initWithFloat:1.0f];
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
				numberOfPoints = 0;
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
            [self setPeakTable:xyData];            
        }
		
		[theScanner release];
    }
    return self;
}

- (void) dealloc {
    if (_synonymsArray) {
        [_synonymsArray release];
    }
	[name release];	
	[origin release];
	[owner release];	
	[CASNumber release];
	[epaMassSpecNo release];
    [formula release];
    [massWeight release];        
    [nistSource release];
    [ionizationEnergy release];
    [xUnits release];	
    [yUnits release];
    [xFactor release];	
    [yFactor release];		
    [retentionIndex release]; 
    [source release];	        
    [synonyms release];		
    [comment release];		
    [molString release];	
    [symbol release];		
    [group release];     
    [super dealloc];
}

- (NSString *)jcampString{
	NSMutableString *outStr = [[[NSMutableString alloc] init] autorelease];
    
    if (([[self name] isEqualToString:@""]) || (![self name])) {
        [outStr appendString:@"##TITLE= Untitled Entry\r\n"];	
    } else {
        [outStr appendFormat:@"##TITLE= %@\r\n", [self name]];	        
    }
	[outStr appendString:@"##JCAMP-DX= 4.24 $$ Peacock 0.26\r\n"];	
	[outStr appendString:@"##DATA TYPE= MASS SPECTRUM\r\n"];	
	[outStr appendString:@"##DATA CLASS= PEAK TABLE\r\n"];	
	if ([[self CASNumber] isNotEqualTo:@""]) {
		[outStr appendFormat:@"##ORIGIN= %@\r\n", [self origin]];	
	} else {
		[outStr appendString:@"##ORIGIN=\r\n"];		
	}
	if ([[self CASNumber] isNotEqualTo:@""]) {
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
	if ([[self library] isNotEqualTo:@""])
		[outStr appendFormat:@"##$LIBRARY= %@\r\n", [self library]];

	[outStr appendFormat:@"##NPOINTS= %i\r\n##XYDATA= (XY..XY)\r\n%@\r\n", [self numberOfPoints], [self peakTable]];
	[outStr appendString:@"##END= \r\n"];
	return outStr;
}

- (NSUndoManager *)undoManager {
//    JKLogDebug(@"undoManager %@ document %@", [[self document] undoManager], [self document]);
	return [[self document] undoManager];
}

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
     
    if (CreateSymbolTable([[[[NSBundle mainBundle] resourcePath] stringByAppendingString:@"/periodic.table"] cStringUsingEncoding:NSASCIIStringEncoding]) != 0) {
        printf("Unable to read periodic table.\n");
        return nil;
    }
	atom = [[CFragment alloc] initFromString:[inString cStringUsingEncoding:NSASCIIStringEncoding]:NULL];
	float result = [atom calculateWeight];
  //[atom release];
	return [NSNumber numberWithFloat:result];
}

- (NSString *)legendEntry {
    return [NSString stringWithFormat:NSLocalizedString(@"Library Entry %@",@""),[self name]];
}
#pragma mark -

#pragma mark Accessors
#pragma mark (macrostyle)
idUndoAccessor(name, setName, @"Change Name")
idUndoAccessor(origin, setOrigin, @"Change Origin")
idUndoAccessor(owner, setOwner, @"Change Owner")

idUndoAccessor(CASNumber, setCASNumber, @"Change CAS Number")
idUndoAccessor(epaMassSpecNo, setEpaMassSpecNo, @"Change EPA Mass Spec No")
idUndoAccessor(formula, setFormula, @"Change Molecule Formula")
idUndoAccessor(massWeight, setMassWeight, @"Change Mass Weight")
idUndoAccessor(nistSource, setNISTSource, @"Change NIST Source")
idUndoAccessor(ionizationEnergy, setIonizationEnergy, @"Change Ionization Energy")
idUndoAccessor(xUnits, setXUnits, @"Change Mass Units")
idUndoAccessor(yUnits, setYUnits, @"Change Intensity Units")
idAccessor(xFactor, setXFactor)
idAccessor(yFactor, setYFactor)
idUndoAccessor(retentionIndex, setRetentionIndex, @"Change Retention Index")
idUndoAccessor(source, setSource, @"Change Source")

idUndoAccessor(comment, setComment, @"Change Comment")
idUndoAccessor(molString, setMolString, @"Change Mol String")
idUndoAccessor(symbol, setSymbol, @"Change Symbol")
idUndoAccessor(model, setModel, @"Change Model")
idUndoAccessor(group, setGroup, @"Change Group")
//idUndoAccessor(synonyms, setSynonyms, @"Change Synonyms")
idAccessor(library, setLibrary)

- (id)synonyms {	
    return synonyms;			
}

- (void)setSynonyms:(id)newVar { 
    if ( newVar!=synonyms) {  
        if ( newVar!=(id)self ) 
            [newVar retain]; 
        [[self undoManager] registerUndoWithTarget:self 
                                          selector:@selector(setSynonyms:) 
                                            object:synonyms]; 
        [[self undoManager] setActionName:NSLocalizedString(@"Change Synonyms",@"Change Synonyms")]; 
        if ( synonyms && synonyms!=(id)self) 
            [synonyms release]; 
        synonyms = newVar; 
        if (_synonymsArray)
            [_synonymsArray release];
        _synonymsArray = nil;
    } 
} 

#pragma mark -

#pragma mark Helper functions
- (BOOL)isCompound:(NSString *)compoundString
{
    NSArray *synonymsArray = [self synonymsArray];
    NSString *synonym;
 //   compoundString = [compoundString lowercaseString];
    
    for (synonym in synonymsArray) {
        if ([synonym isEqualToString:compoundString]) {
            return YES;
        }
    }
    return NO;
}

- (NSArray *)synonymsArray {
    if (_synonymsArray) {
        return _synonymsArray;
    }
    if (![self synonyms]) {
        _synonymsArray = [[NSArray arrayWithObject:[self name]] retain];
    } else {
        _synonymsArray = [[[[self synonyms] componentsSeparatedByString:@"; "] arrayByAddingObject:[self name]] retain];
    }
    return _synonymsArray;
}

- (NSString *)peakTable{
	NSMutableString *outStr = [[[NSMutableString alloc] init] autorelease];
	int j;
	for (j=0; j < numberOfPoints; j++) {
		[outStr appendFormat:@"%.0f, %.0f ", masses[j], intensities[j]];
		if (fmod(j,8) == 7 && j != numberOfPoints-1){
			[outStr appendString:@"\r\n"];
		}
	}
	return outStr;
}

- (void)setPeakTable:(NSString *)inString {
    if ((inString == nil) || (![inString isKindOfClass:[NSString class]])) {
        return;
    }

 	// Add the inverse action to the undo stack
	NSUndoManager *undo = [self undoManager];
	[[undo prepareWithInvocationTarget:self] setPeakTable:[self peakTable]];
	
	if (![undo isUndoing]) {
		[undo setActionName:NSLocalizedString(@"Change Peak Table",@"")];
	}
    
	NSScanner *theScanner2 = [[NSScanner alloc] initWithString:inString];
	int j, massInt, intensityInt;

    // Check for silly HP JCAMP file
    if ([inString rangeOfString:@","].location == NSNotFound) {
        numberOfPoints = [[inString componentsSeparatedByString:@"\n"] count]-1;
    } else {
        numberOfPoints = [[inString componentsSeparatedByString:@","] count]-1;
    }

    masses = (float *) realloc(masses, numberOfPoints*sizeof(float));
	intensities = (float *) realloc(intensities, numberOfPoints*sizeof(float));
	
	for (j=0; j < numberOfPoints; j++){
		if (![theScanner2 scanInt:&massInt]) JKLogError(@"Error during reading library (masses).");
		//				NSAssert(massInt > 0, @"massInt");
		masses[j] = massInt*1.0f;
		[theScanner2 scanUpToCharactersFromSet:[NSCharacterSet decimalDigitCharacterSet] intoString:NULL];
		if (![theScanner2 scanInt:&intensityInt]) JKLogError(@"Error during reading library (intensities).");
		//				NSAssert(intensityInt > 0, @"intensityInt");
		intensities[j] = intensityInt*1.0f;
	}

	[theScanner2 release];	
}

- (IBAction)viewOnline{
	[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://webbook.nist.gov/cgi/cbook.cgi?ID=%@&Units=SI",[self CASNumber]]]];
}

- (IBAction)downloadMolFile{
	[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://webbook.nist.gov/cgi/cbook.cgi/%@-2d.mol?Str2File=C%@",[self CASNumber],[self CASNumber]]]];
}

- (IBAction)downloadMassSpectrum{
	[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://webbook.nist.gov/cgi/cbook.cgi/%@-Mass.jdx?JCAMP=C%@&Index=0&Type=Mass",[self CASNumber],[self CASNumber]]]];
}
#pragma mark -

#pragma mark Scanned Mass Range
- (BOOL)hasScannedMassRange {
    return NO;
}
- (float)minScannedMassRange {
    return -1000.0f; // bogus values, should be ignored
}
- (float)maxScannedMassRange {
    return 1000.0f; // bogus values, should be ignored
}
- (float)maxIntensity {
    return jk_stats_float_max([self intensities], [self numberOfPoints]);
}

#pragma mark -

#pragma mark Encoding
- (void)encodeWithCoder:(NSCoder *)coder{
    if ( [coder allowsKeyedCoding] ) { // Assuming 10.2 is quite safe!!
        [super encodeWithCoder:coder];
//        [coder encodeInt:3 forKey:@"version"]; => set in super!
        [coder encodeObject:[self name] forKey:@"name"];
        [coder encodeObject:[self origin] forKey:@"origin"];
        [coder encodeObject:[self owner] forKey:@"owner"];
        [coder encodeObject:[self formula] forKey:@"formula"];
        [coder encodeObject:[self CASNumber] forKey:@"CASNumber"];
        [coder encodeObject:[self epaMassSpecNo] forKey:@"epaMassSpecNo"];
        [coder encodeObject:[self nistSource] forKey:@"nistSource"];
        [coder encodeObject:[self source] forKey:@"source"];
        [coder encodeObject:[self comment] forKey:@"comment"];
        [coder encodeObject:[self molString] forKey:@"molString"];
        [coder encodeObject:[self symbol] forKey:@"symbol"];
        [coder encodeObject:[self massWeight] forKey:@"massWeight"];
        [coder encodeObject:[self ionizationEnergy] forKey:@"ionizationEnergy"];
        [coder encodeObject:[self xUnits] forKey:@"xUnits"];
        [coder encodeObject:[self yUnits] forKey:@"yUnits"];
        [coder encodeObject:[self xFactor] forKey:@"xFactor"];
        [coder encodeObject:[self yFactor] forKey:@"yFactor"];
        [coder encodeObject:[self retentionIndex] forKey:@"retentionIndex"];
        [coder encodeObject:[self synonyms] forKey:@"synonyms"];
        [coder encodeObject:[self group] forKey:@"group"];
        [coder encodeObject:[self library] forKey:@"library"];
    } 
    return;
}

- (id)initWithCoder:(NSCoder *)coder{
    if ( [coder allowsKeyedCoding] ) {
		int version;
		
		version = [coder decodeIntForKey:@"version"];
		if (version >= 3) {
            self = [super initWithCoder:coder];
            if (self != nil) {
                name = [[coder decodeObjectForKey:@"name"] retain];
                origin = [[coder decodeObjectForKey:@"origin"] retain];
                owner = [[coder decodeObjectForKey:@"owner"] retain];
                formula = [[coder decodeObjectForKey:@"formula"] retain];
                CASNumber = [[coder decodeObjectForKey:@"CASNumber"] retain];
                epaMassSpecNo = [[coder decodeObjectForKey:@"epaMassSpecNo"] retain];
                nistSource = [[coder decodeObjectForKey:@"nistSource"] retain];
                source = [[coder decodeObjectForKey:@"source"] retain];
                comment = [[coder decodeObjectForKey:@"comment"] retain];
                molString = [[coder decodeObjectForKey:@"molString"] retain];
                symbol = [[coder decodeObjectForKey:@"symbol"] retain];
                massWeight = [[coder decodeObjectForKey:@"massWeight"] retain];
                ionizationEnergy = [[coder decodeObjectForKey:@"ionizationEnergy"] retain];
                xUnits = [[coder decodeObjectForKey:@"xUnits"] retain];
                yUnits = [[coder decodeObjectForKey:@"yUnits"] retain];
                xFactor = [[coder decodeObjectForKey:@"xFactor"] retain];
                yFactor = [[coder decodeObjectForKey:@"yFactor"] retain];
                retentionIndex = [[coder decodeObjectForKey:@"retentionIndex"] retain];
                synonyms = [[coder decodeObjectForKey:@"synonyms"] retain];
                group = [[coder decodeObjectForKey:@"group"] retain];
                library = [[coder decodeObjectForKey:@"library"] retain];
            }
            return self;
         } else if (version == 1) {
			return [self initWithJCAMPString:[coder decodeObjectForKey:@"jcampString"]];
		} else {
			// Can decode keys in any order
			name = [[coder decodeObjectForKey:@"name"] retain];
			formula = [[coder decodeObjectForKey:@"formula"] retain];
			CASNumber = [[coder decodeObjectForKey:@"CASNumber"] retain];
			source = [[coder decodeObjectForKey:@"source"] retain];
			comment = [[coder decodeObjectForKey:@"comment"] retain];
			molString = [[coder decodeObjectForKey:@"molString"] retain];
			symbol = [[coder decodeObjectForKey:@"symbol"] retain];
			massWeight = [[coder decodeObjectForKey:@"massWeight"] retain];
            if (![massWeight isKindOfClass:[NSNumber class]]) {
                massWeight = [[NSNumber numberWithFloat:[massWeight floatValue]] retain];
            }
            // these values weren't stored in version 1
            xFactor = [[NSNumber numberWithFloat:0.0] retain];
            yFactor = [[NSNumber numberWithFloat:0.0] retain];
            retentionIndex = [[NSNumber numberWithFloat:0.0] retain];

			numberOfPoints = [coder decodeIntForKey:@"numberOfPoints"];
			
			const uint8_t *temporary = NULL; //pointer to a temporary buffer returned by the decoder.
			unsigned int length;
			masses = (float *) malloc(1*sizeof(float));
			intensities = (float *) malloc(1*sizeof(float));
			
			temporary	= [coder decodeBytesForKey:@"masses" returnedLength:&length];
			[self setMasses:(float *)temporary withCount:numberOfPoints];
			
			temporary	= [coder decodeBytesForKey:@"intensities" returnedLength:&length];
			[self setIntensities:(float *)temporary withCount:numberOfPoints];			
		}
     } 
    return self;
}

@end
