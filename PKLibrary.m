//
//  This file is part of the application with the working name:
//  Peacock
//
//  Created by Johan Kool.
//  Copyright 2003-2008 Johan Kool.
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program.  If not, see <http://www.gnu.org/licenses/>.
//

#import "PKLibrary.h"

#import "PKLibraryWindowController.h"
#import "PKManagedLibraryEntry.h"
#import "PKTargetObjectProtocol.h"
#import "PKAppDelegate.h"

@implementation PKLibrary

#pragma mark INITIALIZATION

- (id)init {
	self = [super init];
    if (self != nil) {

    }
    return self;
}

- (void)makeWindowControllers {
    if (!libraryWindowController) {
        libraryWindowController = [[PKLibraryWindowController alloc] init];        
    }
    [self addWindowController:libraryWindowController];
}

- (void)dealloc {
    if (libraryWindowController) {
        [libraryWindowController release];
    }    
    [super dealloc];
}
#pragma mark -

#pragma mark OPEN/SAVE DOCUMENT

- (BOOL)isDocumentEdited {
    // The main library will get saved on exit anyway
    if ([self isMainLibrary]) {
        return NO;
    } else {
        return [super isDocumentEdited];
    }
}
- (BOOL)isSuperDocumentEdited {
    return [super isDocumentEdited];  
}

- (BOOL)isMainLibrary {
    return ([(PKAppDelegate *)[NSApp delegate] library] == self);
}

- (BOOL)writeToURL:(NSURL *)absoluteURL ofType:(NSString *)typeName forSaveOperation:(NSSaveOperationType)saveOperation originalContentsURL:(NSURL *)absoluteOriginalContentsURL error:(NSError **)error 
{
    if ([typeName isEqualToString:@"Peacock Library"] || [typeName isEqualToString:@"nl.johankool.peacock.library"]) {
        if ([(PKAppDelegate *)[NSApp delegate] library] == self) {
			if (error != NULL)
				*error = [[[NSError alloc] initWithDomain:@"Peacock" code:200 userInfo:[NSDictionary dictionaryWithObjectsAndKeys:@"Library cannot be relocated", NSLocalizedDescriptionKey, @"This library is a representation of the main library used throughout Peacock.", NSLocalizedFailureReasonErrorKey, @"Changes made to this library will automatically be saved on exiting Peacock. It is also possible to export this library as a JCAMP library.", NSLocalizedRecoverySuggestionErrorKey, nil]] autorelease];
            return NO;
        }    
        // Check if a persistent store is available
        if ([[[[self managedObjectContext] persistentStoreCoordinator] persistentStores] count] == 0) {
            // Add persistent store if needed
            NSPersistentStoreCoordinator *psc = [[self managedObjectContext] persistentStoreCoordinator];
            if (![psc addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:absoluteURL options:nil error:error]) {
                // No persistent store could be created, so we fail here
                return NO;
            }
            
//            
//            if (saveOperation == NSSaveOperation) {
//                saveOperation = NSSaveAsOperation;
//            }
            
            // Call super, but set absoluteOriginalContentsURL to nil to avoid exception that there is none at that url
            return [super writeToURL:absoluteURL ofType:typeName forSaveOperation:saveOperation originalContentsURL:nil error:error];
        }
        // If persistent persistent store is present simply call super
         return [super writeToURL:absoluteURL ofType:typeName forSaveOperation:saveOperation originalContentsURL:absoluteOriginalContentsURL error:error ];
	} else if ([typeName isEqualToString:@"JCAMP Library"] || [typeName isEqualToString:@"org.jcamp"]) {
		return [self exportJCAMPToFile:[absoluteURL path]];
	}
    return NO;
}

- (BOOL)readFromURL:(NSURL *)absoluteURL ofType:(NSString *)typeName error:(NSError **)outError
{
	if ([typeName isEqualToString:@"Peacock Library"] || [typeName isEqualToString:@"nl.johankool.peacock.library"]) {
        return [super readFromURL:absoluteURL ofType:typeName error:outError];
    } else if ([typeName isEqualToString:@"JCAMP Library"] || [typeName isEqualToString:@"org.jcamp"]) {
        unsigned int usedEncoding;
        NSString *inString = [NSString stringWithContentsOfURL:absoluteURL usedEncoding:&usedEncoding error:outError];
		if (!inString) {
			PKLogWarning(@"Library encoding is not recognized, trying as UTF8.");
			inString = [NSString stringWithContentsOfURL:absoluteURL encoding:NSUTF8StringEncoding error:outError];
		}
		if (!inString) {
			PKLogWarning(@"Library is not readable as UTF8, perhaps as ASCII?");
			inString = [NSString stringWithContentsOfURL:absoluteURL encoding:NSASCIIStringEncoding error:outError];
		}
		if (!inString) {
			return NO;
		}
        [self readJCAMPString:inString];
        // To avoid undo registration for this insertion we removeAllActions on the undoManager. We first call processPendingChanges
        // on the managed object context to force the undo registration for this insertion, then call removeAllActions.
        [[self managedObjectContext] processPendingChanges];
        [[[self managedObjectContext] undoManager] removeAllActions];
        [self updateChangeCount:NSChangeCleared];
 		return YES;
	}
    return NO;
}
#pragma mark -

#pragma mark KEY VALUE CODING/OBSERVING

//- (void)changeKeyPath:(NSString *)keyPath ofObject:(id)object toValue:(id)newValue{
//	[object setValue:newValue forKeyPath:keyPath];
//}
//
//- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context{
//	NSUndoManager *undo = [self undoManager];
//	id oldValue = [change objectForKey:NSKeyValueChangeOldKey];
//	[[undo prepareWithInvocationTarget:self] changeKeyPath:keyPath ofObject:object toValue:oldValue];
//	
//	[undo setActionName:@"Edit"];
//}

#pragma mark IMPORT/EXPORT ACTIONS

- (void)readJCAMPString:(NSString *)inString {
	int count,i;
    BOOL sillyHPJCAMP;
    NSArray *array;
	NSCharacterSet *whiteCharacters = [NSCharacterSet whitespaceAndNewlineCharacterSet];
    // Check for silly HP JCAMP file
    if ([inString rangeOfString:@"##END="].location == NSNotFound) {
        array = [inString componentsSeparatedByString:@"##TITLE="];
        sillyHPJCAMP = YES;
    } else {
        array = [inString componentsSeparatedByString:@"##END="];
        sillyHPJCAMP = NO;
    }
    
	PKManagedLibraryEntry *libEntry;
	
	count = [array count];
	
	// We *could* ignore the last entry in the array, because it likely isn't complete 
	// NOTE: we now require at least a return after the last entry in the file or we won't read that entry
	for (i=0; i < count; i++) {
		// If we are dealing with an empty string, bail out
		if ((![[[array objectAtIndex:i] stringByTrimmingCharactersInSet:whiteCharacters] isEqualToString:@""]) && (![[array objectAtIndex:i] isEqualToString:@""])) {
            libEntry = [NSEntityDescription insertNewObjectForEntityForName:@"JKManagedLibraryEntry" inManagedObjectContext:[self managedObjectContext]];
            if (sillyHPJCAMP) {
                [libEntry setJCAMPString:[[NSString stringWithString:@"##TITLE="] stringByAppendingString:[array objectAtIndex:i]]];
                //libEntry = [[JKManagedLibraryEntry alloc] initWithJCAMPString:[[NSString stringWithString:@"##TITLE="] stringByAppendingString:[array objectAtIndex:i]]];
            } else {
                [libEntry setJCAMPString:[array objectAtIndex:i]];
            }
		}
    }
}

- (BOOL)importJCAMPFromFile:(NSString *)fileName {
	NSString *inString = [NSString stringWithContentsOfFile:fileName encoding:NSUTF8StringEncoding error:NULL];
	[self readJCAMPString:inString];
	return YES;		
}

- (BOOL)exportJCAMPToFile:(NSString *)fileName {
	NSMutableString *outStr = [[[NSMutableString alloc] init] autorelease]; 
    NSArray *libraryEntries = [self libraryEntries];
	
	for (id loopItem in libraryEntries) {
		[outStr appendString:[loopItem jcampString]];
	}
	
	if ([outStr writeToFile:fileName atomically:NO encoding:NSASCIIStringEncoding error:nil]) {
		return YES;
	} else {
		NSRunInformationalAlertPanel(NSLocalizedString(@"File saved using UTF-8 encoding",@""),NSLocalizedString(@"Probably non-ASCII characters are used in entries of the library. Peacock will save the library in UTF-8 encoding instead of the prescribed ASCII encoding. In order to use this library in other applications the non-ASCII characters should probably be removed.",@""),NSLocalizedString(@"OK",@""),nil,nil);
		return [outStr writeToFile:fileName atomically:NO encoding:NSUTF8StringEncoding error:nil];		
	}
}

//- (BOOL)importAMDISFromFile:(NSString *)fileName {
//	int count,i,j;
//	NSString *inStr = [NSString stringWithContentsOfFile:fileName];
//	NSArray *array = [inStr componentsSeparatedByString:@"\r\n\r\n"];
//		
//    NSString *CASNAME = @"NAME:";
//    NSString *name = @"";
//    NSString *MOLFORM = @"FORM:";
//    NSString *formula = @"";
//    NSString *CASNO = @"CASNO:";
//    NSString *CASNumber = @"";
//    NSString *RETINDEX = @"RI:";
//    float retentionIndex = 0.0;
//	NSString *RETWIDTH = @"RW:";
//	float retentionWidth = 0.0;
//    NSString *RETTIME = @"RT:";
//    float retentionTime;
//    NSString *SRC = @"SOURCE:";
//    NSString *sourceStr = @"";
//    NSString *CMT = @"COMMENT:";
//    NSString *comment = @"";	
//    NSString *XY = @"NUM PEAKS:";
//	int numPeaks = 0;
//    NSString *xyData;
//	float mass, intensity;
//
//	count = [array count];
//	for (i=0; i < count; i++) {
//		NSScanner *theScanner = [NSScanner scannerWithString:[array objectAtIndex:i]];
//		NSMutableDictionary *mutDict = [[NSMutableDictionary alloc] init];
//
//		// Reset
//		name = @"";
//		formula = @"";
//		CASNumber = @"";
//		retentionIndex = 0.0;
//		retentionWidth = 0.0;
//		retentionTime = 0.0;
//		sourceStr = @"";
//		comment = @"";	
//		numPeaks = 0;
//		xyData = @"";
//		mass = 0.0;
//		intensity = 0.0;
//		
//		
//		// Name
//		[theScanner setScanLocation:0];
//		if ([theScanner scanUpToString:CASNAME intoString:NULL] || [theScanner scanString:CASNAME intoString:NULL]) {
//			[theScanner scanString:CASNAME intoString:NULL]; 
//			[theScanner scanUpToString:@"\r\n" intoString:&name];
//			[mutDict setValue:name forKey:@"name"];
//		}
//		
//		// Formula
//		[theScanner setScanLocation:0];
//		if([theScanner scanUpToString:MOLFORM intoString:NULL]) {
//			[theScanner scanString:MOLFORM intoString:NULL]; 
//			[theScanner scanUpToString:@"\r\n" intoString:&formula];
//			[mutDict setValue:formula forKey:@"formula"];
//		}
//		
//		// CAS Number
//		[theScanner setScanLocation:0];
//		if ([theScanner scanUpToString:CASNO intoString:NULL]) {
//			[theScanner scanString:CASNO intoString:NULL]; 
//			[theScanner scanUpToString:@"\r\n" intoString:&CASNumber];
//			[mutDict setValue:CASNumber forKey:@"CASNumber"];			
//		}
//		
//		// Mass weight
//		[theScanner setScanLocation:0];
//		if ([theScanner scanUpToString:@"MW:" intoString:NULL]) {
//			[theScanner scanString:@"MW:" intoString:NULL]; 
//			[theScanner scanFloat:&retentionIndex];
//			[mutDict setValue:[NSNumber numberWithFloat:retentionIndex] forKey:@"massWeight"];			
//		}
//		
//		// Retention Index
//		[theScanner setScanLocation:0];
//		if ([theScanner scanUpToString:RETINDEX intoString:NULL]) {
//			[theScanner scanString:RETINDEX intoString:NULL]; 
//			[theScanner scanFloat:&retentionIndex];
//			[mutDict setValue:[NSNumber numberWithFloat:retentionIndex] forKey:@"retentionIndex"];			
//		}
//		
//		// Retention Width
//		[theScanner setScanLocation:0];
//		if ([theScanner scanUpToString:RETWIDTH intoString:NULL]) {
//			[theScanner scanString:RETWIDTH intoString:NULL]; 
//			[theScanner scanFloat:&retentionWidth];
//			[mutDict setValue:[NSNumber numberWithFloat:retentionWidth] forKey:@"retentionWidth"];
//		}
//		
//		// Retention Time
//		[theScanner setScanLocation:0];
//		if ([theScanner scanUpToString:RETTIME intoString:NULL]) {
//			[theScanner scanString:RETTIME intoString:NULL]; 
//			[theScanner scanFloat:&retentionTime];
//			[mutDict setValue:[NSNumber numberWithFloat:retentionTime] forKey:@"retentionTime"];			
//		}
//		
//		// Comment
//		[theScanner setScanLocation:0];
//		if ([theScanner scanUpToString:CMT intoString:NULL]) {
//			[theScanner scanString:CMT intoString:NULL]; 
//			[theScanner scanUpToString:@"\r\n" intoString:&comment];
//			[mutDict setValue:comment forKey:@"comment"];
//		}
//		
//		// Source
//		[theScanner setScanLocation:0];
//		if ([theScanner scanUpToString:SRC intoString:NULL]) {
//			[theScanner scanString:SRC intoString:NULL]; 
//			[theScanner scanUpToString:@"\r\n" intoString:&sourceStr];
//			[mutDict setValue:sourceStr forKey:@"source"];
//		}
//		
//		// Spectrum data
//		[theScanner setScanLocation:0];
//		if ([theScanner scanUpToString:XY intoString:NULL]) {
//			[theScanner scanString:XY intoString:NULL]; 
//			[theScanner scanInt:&numPeaks];
//			[theScanner scanUpToCharactersFromSet:[NSCharacterSet letterCharacterSet] intoString:&xyData];
//			
//			NSScanner *theScannerXY = [NSScanner scannerWithString:xyData];
//			NSMutableArray *arrayOut = [[NSMutableArray alloc] init];
//			for (j=0; j <  numPeaks; j++) {
//				[theScannerXY scanUpToString:@"(" intoString:NULL];
//				[theScannerXY scanString:@"(" intoString:NULL];
//				[theScannerXY scanFloat:&mass];
//				[theScannerXY scanString:@"," intoString:NULL]; // occurs sometimes in msl files and can trip the scanfloat function
//				[theScannerXY scanFloat:&intensity];
//				[theScannerXY scanUpToString:@")" intoString:NULL];
//				
//				NSMutableDictionary *mutDict2 = [[NSMutableDictionary alloc] init];
//				[mutDict2 setValue:[NSNumber numberWithFloat:mass] forKey:@"Mass"];
//				[mutDict2 setValue:[NSNumber numberWithFloat:intensity] forKey:@"Intensity"];
//				[arrayOut addObject:mutDict2];
//				[mutDict2 release];
//			}
//			//[theScannerXY release];
//			
//			[mutDict setObject:arrayOut forKey:@"points"];
//			//[arrayOut release];			
//		}
//
//		// Add data to Library
//		[libraryEntries addObject:mutDict];
//		[mutDict release];
////		[theScanner release];
//    }
//
//    return YES;
//}
//
//- (BOOL)exportAMDISToFile:(NSString *)fileName {
//	NSMutableString *outStr = [[NSMutableString alloc] init]; 
//	NSArray *array;
//	int i,j,count2;
//	int count = [libraryEntries count];
////	float retentionTime, retentionIndex;
//	
//	for (i=0; i < count; i++) {
//		if ([[[libraryEntries objectAtIndex:i] valueForKey:@"name"] isNotEqualTo:@""]) [outStr appendFormat:@"NAME: %@\r\n", [[libraryEntries objectAtIndex:i] valueForKey:@"name"]];
//		if ([[[libraryEntries objectAtIndex:i] valueForKey:@"formula"] isNotEqualTo:@""])[outStr appendFormat:@"FORM: %@\r\n", [[libraryEntries objectAtIndex:i] valueForKey:@"formula"]];
//		if ([[[libraryEntries objectAtIndex:i] valueForKey:@"CASNumber"] isNotEqualTo:@""])[outStr appendFormat:@"CASNO: %@\r\n", [[libraryEntries objectAtIndex:i] valueForKey:@"CASNumber"]];
//		if (![[[libraryEntries objectAtIndex:i] valueForKey:@"retentionIndex"] isEqualToNumber:[NSNumber numberWithFloat:0.0]])[outStr appendFormat:@"RI: %.3f\r\n", [[[libraryEntries objectAtIndex:i] valueForKey:@"retentionIndex"] floatValue]];
////		if (![[[libraryEntries objectAtIndex:i] valueForKey:@"retentionTime"] isEqualToNumber:[NSNumber numberWithFloat:0.0]]) {
////			retentionTime = [[[libraryEntries objectAtIndex:i] valueForKey:@"retentionTime"] floatValue];
////			retentionIndex = 0.0119 * pow(retentionTime,2) + 0.1337 * retentionTime + 8.1505;
////			[outStr appendFormat:@"RI: %.3f\r\n", retentionIndex*100];
////		}
//		if (![[[libraryEntries objectAtIndex:i] valueForKey:@"massWeight"] isEqualToNumber:[NSNumber numberWithFloat:0.0]])[outStr appendFormat:@"MW: %.0f\r\n", [[[libraryEntries objectAtIndex:i] valueForKey:@"massWeight"] floatValue]];
//		if (![[[libraryEntries objectAtIndex:i] valueForKey:@"retentionWidth"] isEqualToNumber:[NSNumber numberWithFloat:0.0]])[outStr appendFormat:@"RW: %.3f\r\n", [[[libraryEntries objectAtIndex:i] valueForKey:@"retentionWidth"] floatValue]];
//		if (![[[libraryEntries objectAtIndex:i] valueForKey:@"retentionTime"] isEqualToNumber:[NSNumber numberWithFloat:0.0]])[outStr appendFormat:@"RT: %.3f\r\n", [[[libraryEntries objectAtIndex:i] valueForKey:@"retentionTime"] floatValue]];
//		if ([[[libraryEntries objectAtIndex:i] valueForKey:@"comment"] isNotEqualTo:@""])[outStr appendFormat:@"COMMENT: %@\r\n", [[libraryEntries objectAtIndex:i] valueForKey:@"comment"]];
//		if ([[[libraryEntries objectAtIndex:i] valueForKey:@"source"] isNotEqualTo:@""])[outStr appendFormat:@"SOURCE: %@\r\n", [[libraryEntries objectAtIndex:i] valueForKey:@"source"]];
//		array = [[libraryEntries objectAtIndex:i] valueForKey:@"points"];
//		count2 = [array count];
//		[outStr appendFormat:@"NUM PEAKS: %i\r\n", count2];
//		for (j=0; j < count2; j++) {
//			[outStr appendFormat:@"(%4.f, %4.f) ", [[[array objectAtIndex:j] valueForKey:@"Mass"] floatValue], [[[array objectAtIndex:j] valueForKey:@"Intensity"] floatValue]];
//			if (fmod(j,5) == 4 && j != count2-1){
//				[outStr appendString:@"\r\n"];
//			}
//		}
//		[outStr appendString:@"\r\n\r\n"];
//	}
//	
//	if ([outStr writeToFile:fileName atomically:NO encoding:NSASCIIStringEncoding error:nil]) {
//		return YES;
//	} else {
//		NSRunInformationalAlertPanel(NSLocalizedString(@"File saved using UTF-8 encoding",@""),NSLocalizedString(@"Probably non-ASCII characters are used in entries of the library. Peacock will save the library in UTF-8 encoding instead of the prescribed ASCII encoding. In order to use this library in other applications the non-ASCII characters should probably be removed.",@""),NSLocalizedString(@"OK",@""),nil,nil);
//		return [outStr writeToFile:fileName atomically:NO];
//		
//	}
//}

//#pragma mark ACCESSORS
- (BOOL)requiresObjectForPredicateForSearchTemplate:(NSString *)searchTemplateName
{
    // Get search template
    NSArray *searchTemplates = [[[NSUserDefaultsController sharedUserDefaultsController] values] valueForKey:@"searchTemplates"];
    NSDictionary *searchTemplateDict;
    
    for (searchTemplateDict in searchTemplates) {
    	if ([[searchTemplateDict valueForKey:@"name"] isEqualToString:searchTemplateName]) {
            break;
        }
    }
    
    NSString *searchTemplateString = [searchTemplateDict valueForKey:@"searchTemplate"];
    if (!searchTemplateString) {
        return NO;
    }
    if ([searchTemplateString rangeOfString:@"$"].location == NSNotFound) {
        return NO;
    } else {
        return YES;
    }
    
}
- (NSPredicate *)predicateForSearchTemplate:(NSString *)searchTemplateName andObject:(id <PKTargetObjectProtocol>)targetObject {    
    // Get search template
    NSArray *searchTemplates = [[[NSUserDefaultsController sharedUserDefaultsController] values] valueForKey:@"searchTemplates"];
    NSDictionary *searchTemplate;

    for (searchTemplate in searchTemplates) {
    	if ([[searchTemplate valueForKey:@"name"] isEqualToString:searchTemplateName]) {
            break;
        }
    }
    if (!searchTemplate)
        return nil;
    
    NSString *searchTemplateString = [searchTemplate valueForKey:@"searchTemplate"];
    // PKLogDebug(@"%@: %@",searchTemplateName, searchTemplateString);
    
    // Substitute values for targetSpectrum
    NSPredicate *predicate = [NSPredicate predicateWithFormat:searchTemplateString];
    NSDictionary *substitutionDictionary = nil;
    if (!targetObject) {
        substitutionDictionary = [NSDictionary dictionary];
    } else {
        substitutionDictionary = [targetObject substitutionVariables];
    }
    return [predicate predicateWithSubstitutionVariables:substitutionDictionary];
}

- (NSArray *)libraryEntriesWithPredicate:(NSPredicate *)predicate {
	NSManagedObjectContext *moc = [self managedObjectContext];
    NSEntityDescription *entityDescription = [NSEntityDescription entityForName:@"JKManagedLibraryEntry" inManagedObjectContext:moc];
    NSFetchRequest *request = [[[NSFetchRequest alloc] init] autorelease];
    [request setEntity:entityDescription];
        
    if (predicate)
        [request setPredicate:predicate];
       
    NSError *error = nil;

   // PKLogInfo(@"Fetching %d library entries", [moc countForFetchRequest:request error:&error]);

    NSArray *array = [moc executeFetchRequest:request error:&error];
    if (error) {
        // Deal with error...
        PKLogError(@"No library entries were found.");
        [self willPresentError:error];
    }
    [error release];
    return array;
    
}

- (NSArray *)libraryEntries {
    return [self libraryEntriesWithPredicate:nil];
}

- (PKLibraryWindowController *)libraryWindowController {
	return libraryWindowController;
}

// Intercept validation errors with willPresentError: so that we can handle their display
- (NSError *)willPresentError:(NSError *)inError 
{
	// The error is a Core Data validation error if its domain is NSCocoaErrorDomain and it is between
	// the minimum and maximum for Core Data validation error codes.
	if ([[inError domain] isEqualToString:NSCocoaErrorDomain]) {
		int errorCode = [inError code];
		if ( errorCode >= NSValidationErrorMinimum && errorCode <= NSValidationErrorMaximum) {
            
			// If there are multiple validation errors, inError will be a NSValidationMultipleErrorsError
			// and all the validation errors will be in an array in the userInfo dictionary for key NSDetailedErrorsKey
			id detailedErrors = [[inError userInfo] objectForKey:NSDetailedErrorsKey];
			if (detailedErrors != nil) {
                
				// For this example we are only presenting the error messages for up to 3 validation errors at a time.
				// We are simply passing the NSLocalizedDescription for each error to the user, but one could instead
				// construct a customized, user-friendly error here. The error codes and userInfo dictionary
				// keys for validation errors are listed in <CoreData/CoreDataErrors.h>.
				
				unsigned numErrors = [detailedErrors count];							
				NSMutableString *errorString = [NSMutableString stringWithFormat:@"%u validation errors have occurred", numErrors];
				if (numErrors > 3)
					[errorString appendFormat:@". The first 3 are:\n"];
				else
					[errorString appendFormat:@":\n"];
				
				unsigned i;
				for (i = 0; i < (numErrors > 3 ? 3 : numErrors); ++i) {
					[errorString appendFormat:@"%@\n", [[detailedErrors objectAtIndex:i] localizedDescription]];
				}
				
				NSMutableDictionary *userInfo = [NSMutableDictionary dictionaryWithDictionary:[inError userInfo]];
				[userInfo setObject:errorString forKey:NSLocalizedRecoverySuggestionErrorKey];
				
				return [NSError errorWithDomain:[inError domain] code:[inError code] userInfo:userInfo];
				
			} else {
				// As there is only one validation error, we are returning it verbatim to the user.
				return inError;
			}
		}
	}
	return inError;
}

@synthesize libraryWindowController;
@end
