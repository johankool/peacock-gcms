//
//  JKSearchResult.m
//  Peacock
//
//  Created by Johan Kool on 24-1-07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "JKSearchResult.h"

#import "JKAppDelegate.h"
#import "JKLibraryEntry.h"
#import "JKPeakRecord.h"
#import "JKLibrary.h"
#import "JKManagedLibraryEntry.h"

@implementation JKSearchResult

- (id)init {
    self = [super init];
    if (self != nil) {
        _libraryHit = nil;
//        spectrumType = 0;
        jcampString = [@"" retain];
    }
    return self;
}

- (void)dealloc {
    [jcampString release];
    [_libraryHit release];
    [super dealloc];
}


- (NSNumber *)deltaRetentionIndex {
    return [NSNumber numberWithFloat:[[peak retentionIndex] floatValue] - [[[self libraryHit] retentionIndex] floatValue]];
}

- (id)libraryHit {
    if (_libraryHit) {
        return _libraryHit;
    }
    
    if (libraryHitURI) {
        @try {
        NSManagedObjectContext *moc = [[[NSApp delegate] library] managedObjectContext];
        NSManagedObjectID *mid = [[moc persistentStoreCoordinator] managedObjectIDForURIRepresentation:libraryHitURI];
        if (mid) {
            _libraryHit = [[moc objectWithID:mid] retain];
            if (_libraryHit) {
                [_libraryHit willAccessValueForKey:nil];
                return _libraryHit;
            }
            JKLogDebug(@"Library entry for '%@' not found in current libraries.", [libraryHitURI description]);
        }
        }
        @catch ( NSException *e ) {
            libraryHitURI = nil;
            JKLogDebug(@"Catched exception.");
            NSMutableDictionary *errorDict = [NSMutableDictionary dictionary];
            [errorDict setObject:[e reason] forKey:NSLocalizedDescriptionKey];
            NSError *error = [NSError errorWithDomain:@"Peacock" code:1 userInfo:errorDict];
            [[[self peak] document] presentError:error];
        }
        
        @finally {
         }
    } 
    
    if (jcampString) {
        // The library entry was not found, fall back on the jcamp string representation
        _libraryHit = [[JKLibraryEntry alloc] initWithJCAMPString:jcampString];
        JKLogDebug(@"Library entry for '%@' not found. Falling back to using JCAMP.", [_libraryHit name]);
        return _libraryHit;
    }

	return nil;
}

- (NSURL *)libraryHitURI {
    if (!libraryHitURI && [_libraryHit isKindOfClass:[JKManagedLibraryEntry class]]) {
        if (![[_libraryHit objectID] isTemporaryID]) {
            [libraryHitURI autorelease];
            libraryHitURI = [[[_libraryHit objectID] URIRepresentation] retain];
        }            
    }
    return libraryHitURI;
}

- (void)setLibraryHit:(id)aLibraryHit {
    if (_libraryHit != aLibraryHit) {
        if ([aLibraryHit isKindOfClass:[JKManagedLibraryEntry class]]) {
            if (![[aLibraryHit objectID] isTemporaryID]) {
                [libraryHitURI autorelease];
                libraryHitURI = [[[aLibraryHit objectID] URIRepresentation] retain];
            }
        }
        if (jcampString)
            [jcampString autorelease];
        jcampString = [[aLibraryHit jcampString] retain];
        if (_libraryHit)
            [_libraryHit autorelease];
        _libraryHit = [aLibraryHit retain];
    }
}


#pragma mark Encoding

- (void)encodeWithCoder:(NSCoder *)coder {
    if ([coder allowsKeyedCoding]) {
        [coder encodeInt:2 forKey:@"version"];
		[coder encodeObject:score forKey:@"score"]; 
		[coder encodeObject:[[self libraryHit] jcampString] forKey:@"jcampString"]; 
        // If the library entry has gained a permanentID in between the assignment, we want to get it and use it.
        if (!libraryHitURI && [_libraryHit isKindOfClass:[JKManagedLibraryEntry class]]) {
            if (![[_libraryHit objectID] isTemporaryID]) {
                [libraryHitURI autorelease];
                libraryHitURI = [[[_libraryHit objectID] URIRepresentation] retain];
            }            
        }
		[coder encodeObject:libraryHitURI forKey:@"libraryHitURI"]; 
		[coder encodeObject:peak forKey:@"peak"];         
    } 
    return;
}

- (id)initWithCoder:(NSCoder *)coder {
    if ([coder allowsKeyedCoding]) {
        int version = [coder decodeIntForKey:@"version"];
        if (version < 2) {
            score = [[coder decodeObjectForKey:@"score"] retain]; 
            peak = [[coder decodeObjectForKey:@"peak"] retain]; 
            // See if we can find the library entry in the current library and get hold of the URI
            JKLibraryEntry *someLibraryHit = [coder decodeObjectForKey:@"libraryHit"]; 
            id matchedLibraryHit = [(JKAppDelegate *)[NSApp delegate] libraryEntryForName:[someLibraryHit name]];
            if (matchedLibraryHit) {
                [self setLibraryHit:matchedLibraryHit];
            } else {
                jcampString = [[someLibraryHit jcampString] retain];
            }
         } else {
            score = [[coder decodeObjectForKey:@"score"] retain]; 
            jcampString = [[coder decodeObjectForKey:@"jcampString"] retain]; 
            peak = [[coder decodeObjectForKey:@"peak"] retain];
            libraryHitURI = [[coder decodeObjectForKey:@"libraryHitURI"] retain];
            [self libraryHit]; // Causes faults to fire, which we want...
        }
    } 
    return self;
}
@synthesize score;
@synthesize peak;
             
//@synthesize spectrumType;
@end
