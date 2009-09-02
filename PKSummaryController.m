//
//  JKSummaryController.m
//  Peacock
//
//  Created by Johan Kool on 01-10-07.
//  Copyright 2007-2008 Johan Kool.
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

#import "PKSummaryController.h"

#import "PKAppDelegate.h"
#import "PKChromatogram.h"
#import "PKCombinedPeak.h"
#import "PKDocumentController.h"
#import "PKGCMSDocument.h"
#import "PKLibrary.h"
#import "PKLibraryWindowController.h"
#import "PKMainWindowController.h"
#import "PKPeakRecord.h"
#import "PKSummarizer.h"
//#import "JKSynchroScrollView.h"

#define JKLibraryEntryTableViewDataType @"JKLibraryEntryTableViewDataType"

@implementation PKSummaryController
- (id)init {
    self = [super initWithWindowNibName:@"PKSummary"];
    if (self) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(documentLoaded:) name:@"JKGCMSDocument_DocumentLoadedNotification" object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(documentUnloaded:) name:@"JKGCMSDocument_DocumentUnloadedNotification" object:nil];
        indexOfKeyForValue = 0;
        indexOfSortKey = 0;
        sortDirection = YES;
        keys = [[NSArray arrayWithObjects:[NSDictionary dictionaryWithObjectsAndKeys:@"topTime", @"key", NSLocalizedString(@"Top Time", @""), @"localized", [NSNumber numberWithInt:0], @"format", nil], 
            [NSDictionary dictionaryWithObjectsAndKeys:@"surface", @"key", NSLocalizedString(@"Surface", @""), @"localized", [NSNumber numberWithInt:0], @"format", nil], 
            [NSDictionary dictionaryWithObjectsAndKeys:@"normalizedSurface", @"key", NSLocalizedString(@"Normalized Surface (largest peak)", @""), @"localized", [NSNumber numberWithInt:0], @"format", nil], 
            [NSDictionary dictionaryWithObjectsAndKeys:@"normalizedSurface2", @"key", NSLocalizedString(@"Normalized Surface (confirmed peaks)", @""), @"localized", [NSNumber numberWithInt:0], @"format", nil], 
            [NSDictionary dictionaryWithObjectsAndKeys:@"retentionIndex", @"key", NSLocalizedString(@"Retention Index", @""), @"localized", [NSNumber numberWithInt:0], @"format", nil], 
            [NSDictionary dictionaryWithObjectsAndKeys:@"model", @"key", NSLocalizedString(@"Model", @""), @"localized", [NSNumber numberWithInt:1], @"format", nil], 
            [NSDictionary dictionaryWithObjectsAndKeys:@"height", @"key", NSLocalizedString(@"Height", @""), @"localized", [NSNumber numberWithInt:0], @"format", nil], 
            [NSDictionary dictionaryWithObjectsAndKeys:@"score", @"key", NSLocalizedString(@"Score", @""), @"localized", [NSNumber numberWithInt:0], @"format", nil], 
            [NSDictionary dictionaryWithObjectsAndKeys:@"flagged", @"key", NSLocalizedString(@"Flagged", @""), @"localized", [NSNumber numberWithInt:2], @"format", nil], 
            [NSDictionary dictionaryWithObjectsAndKeys:@"symbol", @"key", NSLocalizedString(@"Symbol", @""), @"localized", [NSNumber numberWithInt:1], @"format", nil], 
            [NSDictionary dictionaryWithObjectsAndKeys:@"deltaRetentionIndex", @"key", NSLocalizedString(@"Delta Retention Index", @""), @"localized", [NSNumber numberWithInt:0], @"format", nil], 
            [NSDictionary dictionaryWithObjectsAndKeys:@"top", @"key", NSLocalizedString(@"Top Scan", @""), @"localized", [NSNumber numberWithInt:2], @"format", nil], 
            [NSDictionary dictionaryWithObjectsAndKeys:@"start", @"key", NSLocalizedString(@"Start Scan", @""), @"localized", [NSNumber numberWithInt:2], @"format", nil], 
            [NSDictionary dictionaryWithObjectsAndKeys:@"end", @"key", NSLocalizedString(@"End Scan", @""), @"localized", [NSNumber numberWithInt:2], @"format", nil], 
            [NSDictionary dictionaryWithObjectsAndKeys:@"width", @"key", NSLocalizedString(@"Width", @""), @"localized", [NSNumber numberWithInt:2], @"format", nil], 
            [NSDictionary dictionaryWithObjectsAndKeys:@"library", @"key", NSLocalizedString(@"Library", @""), @"localized", [NSNumber numberWithInt:1], @"format", nil], 
            [NSDictionary dictionaryWithObjectsAndKeys:@"baselineLeft", @"key", NSLocalizedString(@"Baseline Left", @""), @"localized", [NSNumber numberWithInt:0], @"format", nil], 
            [NSDictionary dictionaryWithObjectsAndKeys:@"baselineRight", @"key", NSLocalizedString(@"Baseline Right", @""), @"localized", [NSNumber numberWithInt:0], @"format", nil], 
            [NSDictionary dictionaryWithObjectsAndKeys:@"peakID", @"key", NSLocalizedString(@"Peak Number", @""), @"localized", [NSNumber numberWithInt:2], @"format", nil], 
            [NSDictionary dictionaryWithObjectsAndKeys:@"uuid", @"key", NSLocalizedString(@"Unique ID", @""), @"localized", [NSNumber numberWithInt:1], @"format", nil], 
            nil] retain];
        sortKeys = [[NSArray arrayWithObjects:[NSDictionary dictionaryWithObjectsAndKeys:@"label", @"key", NSLocalizedString(@"Compound name", @""), @"localized", nil], 
            [NSDictionary dictionaryWithObjectsAndKeys:@"averageRetentionIndex", @"key", NSLocalizedString(@"Retention Index", @""), @"localized", nil], 
            [NSDictionary dictionaryWithObjectsAndKeys:@"symbol", @"key", NSLocalizedString(@"Symbol", @""), @"localized", nil], 
            [NSDictionary dictionaryWithObjectsAndKeys:@"group", @"key", NSLocalizedString(@"Group", @""), @"localized", nil], 
            [NSDictionary dictionaryWithObjectsAndKeys:@"averageSurface", @"key", NSLocalizedString(@"Surface", @""), @"localized", nil], 
            [NSDictionary dictionaryWithObjectsAndKeys:@"averageHeight", @"key", NSLocalizedString(@"Height", @""), @"localized", nil], 
            [NSDictionary dictionaryWithObjectsAndKeys:@"countOfPeaks", @"key", NSLocalizedString(@"Number of Peaks", @""), @"localized", nil], 
            nil] retain];
        
    }
    return self;
}

- (void)windowDidLoad {
    // Drag and drop
	[tableView registerForDraggedTypes:[NSArray arrayWithObjects:@"JKManagedLibraryEntryURIType", nil]];
	[tableView setDataSource:self];
	[tableView setDelegate:self];
    
    [tableView setTarget:self];
    [tableView setDoubleAction:@selector(doubleClickAction:)];
    [combinedPeaksController bind:@"contentArray" toObject:[(PKAppDelegate *)[NSApp delegate] summarizer] withKeyPath:@"combinedPeaks" options:nil];
}


- (BOOL)writeToURL:(NSURL *)absoluteURL ofType:(NSString *)typeName error:(NSError **)outError {
    if ([typeName isEqualToString:@"public.text"]) {
        NSMutableString *outString = [NSMutableString string];
        PKGCMSDocument* document;
        
        // File name
        [outString appendString:@"Filename"];
        for (document in [[PKDocumentController sharedDocumentController] managedDocuments]) {
            [outString appendFormat:@"\t%@", [document displayName]];
        }
        [outString appendString:@"\n"];
        
        // Sample code
        [outString appendString:@"Code"];
        for (document in [[PKDocumentController sharedDocumentController] managedDocuments]) {
            [outString appendFormat:@"\t%@", [document sampleCode]];
        }
        [outString appendString:@"\n"];
 
        // Sample description
        [outString appendString:@"Description"];
        for (document in [[PKDocumentController sharedDocumentController] managedDocuments]) {
            [outString appendFormat:@"\t%@", [document sampleDescription]];
        }
        [outString appendString:@"\n"];
        
        // Values
        PKCombinedPeak *combinedPeak;
        NSString *keyForValue = [self keyForValue];
        NSString *format;
        switch ([self formatForValue]) {
            case 0:
                format = @"\t%@";
                break;
            case 1:
                format = @"\t%@";
                break;
            default:
                format = @"\t%@";
                break;
        }
        id value;
        for (combinedPeak in [combinedPeaksController arrangedObjects]) {
            [outString appendFormat:@"%@ [%@]", [combinedPeak label], [combinedPeak symbol]];
            for (document in [[PKDocumentController sharedDocumentController] managedDocuments]) {
                value = [[combinedPeak valueForKey:[document uuid]] valueForKey:keyForValue];
                if (value) {
                    [outString appendFormat:format, [[combinedPeak valueForKey:[document uuid]] valueForKey:keyForValue]];
                } else {
                    [outString appendString:@"\t"];
                }
             }
            [outString appendString:@"\n"];
        }
        
        return [outString writeToURL:absoluteURL atomically:YES encoding:NSUTF8StringEncoding error:outError];
    }
    
    if (outError != NULL)
        *outError = [[[NSError alloc] initWithDomain:NSCocoaErrorDomain
                                                code:NSFileWriteUnknownError userInfo:nil] autorelease];
    
    return NO;
}

- (IBAction)export:(id)sender {
    NSSavePanel *sp = [NSSavePanel savePanel];
    [sp setMessage:NSLocalizedString(@"Choose a location for exporting the current summary.", @"")];
    NSArray *docs = [[PKDocumentController sharedDocumentController] managedDocuments];
    NSString *fileName;
    NSString *firstDoc;
    NSString *lastDoc;
    if ([docs count] == 0) {
        NSBeep();
        return;
    } else if ([docs count] == 1) {
        firstDoc = [[docs objectAtIndex:0] displayName];
         
        fileName = [NSString stringWithFormat:NSLocalizedString(@"Exported Summary (by %@) for %@.txt", @""), [[keys objectAtIndex:indexOfKeyForValue] valueForKey:@"localized"], firstDoc];        
    } else {
        firstDoc = [[docs objectAtIndex:0] displayName];
        lastDoc = [[docs lastObject] displayName];
        
        fileName = [NSString stringWithFormat:NSLocalizedString(@"Exported Summary (by %@) for %@ to %@.txt", @""), [[keys objectAtIndex:indexOfKeyForValue] valueForKey:@"localized"], firstDoc, lastDoc];
    }
    
    [sp beginSheetForDirectory:nil file:fileName modalForWindow:[self window] modalDelegate:self didEndSelector:@selector(savePanelDidEnd:returnCode:contextInfo:) contextInfo:nil];
}

- (void)savePanelDidEnd:(NSSavePanel *)sheet returnCode:(int)returnCode contextInfo:(void  *)contextInfo {
    if (returnCode == NSOKButton) {
        NSError *error = nil;
        if (![self writeToURL:[sheet URL] ofType:@"public.text" error:&error]) {
            [self presentError:error];
        }
     }
}

- (void)documentLoaded:(NSNotification *)aNotification {
    id document = [aNotification object];
    PKLogDebug(@"Document loaded notification received for %@", [document description]);
    if ([document isKindOfClass:[PKGCMSDocument class]]) {
        if ([tableView columnWithIdentifier:document] == -1)
            [self addTableColumForDocument:document];
    }
}

- (void)documentUnloaded:(NSNotification *)aNotification {
    id object = [aNotification object];
    [tableView removeTableColumn:[tableView tableColumnWithIdentifier:object]];
}

- (void)addTableColumForDocument:(PKGCMSDocument *)document {
    // Setup bindings for Combined peaks
    NSTableColumn *tableColumn = [[NSTableColumn alloc] init];
    [tableColumn setIdentifier:document];
    [[tableColumn headerCell] setStringValue:[document displayName]];
    NSString *keyPath = [NSString stringWithFormat:@"arrangedObjects.%@.%@",[(PKGCMSDocument *)document uuid],[self keyForValue]];
    [[tableColumn headerCell] setStringValue:[document displayName]];
    [tableColumn bind:@"value" toObject:combinedPeaksController withKeyPath:keyPath options:nil];
    [[tableColumn dataCell] setFont:[NSFont systemFontOfSize:[NSFont systemFontSizeForControlSize:NSSmallControlSize]]];
    NSNumberFormatter *formatter;
    switch ([self formatForValue]) {
    case 0:
        formatter = [[[NSNumberFormatter alloc] init] autorelease];
        [formatter setFormatterBehavior:NSNumberFormatterDecimalStyle];
        [formatter setPositiveFormat:@"#0.0"];
        [formatter setLocalizesFormat:YES]; 
        [[tableColumn dataCell] setFormatter:formatter];
        [[tableColumn dataCell] setAlignment:NSRightTextAlignment];
        break;
    case 2:
        formatter = [[[NSNumberFormatter alloc] init] autorelease];
        [formatter setFormatterBehavior:NSNumberFormatterDecimalStyle];
        [formatter setPositiveFormat:@"#0"];
        [formatter setLocalizesFormat:YES]; 
        [[tableColumn dataCell] setFormatter:formatter];
        [[tableColumn dataCell] setAlignment:NSRightTextAlignment];
        break;
    case 1:
    default:
        [[tableColumn dataCell] setFormatter:nil];
        [[tableColumn dataCell] setAlignment:NSLeftTextAlignment];
         break;
    }
    [tableColumn setEditable:NO];
    [tableView addTableColumn:tableColumn];
    [tableColumn release];    
}

- (void)updateTableColumnBindings {
    for (NSTableColumn *tableColumn in [tableView tableColumns]) {
        if ([[tableColumn identifier] isKindOfClass:[PKGCMSDocument class]]) {
            NSString *keyPath = [NSString stringWithFormat:@"arrangedObjects.%@.%@",[[tableColumn identifier] uuid],[self keyForValue]];
            [tableColumn bind:@"value" toObject:combinedPeaksController withKeyPath:keyPath options:nil];
            NSNumberFormatter *formatter;
            switch ([self formatForValue]) {
                case 0:
                    formatter = [[[NSNumberFormatter alloc] init] autorelease];
                    [formatter setFormatterBehavior:NSNumberFormatterDecimalStyle];
                    [formatter setPositiveFormat:@"#0.0"];
                    [formatter setLocalizesFormat:YES]; 
                    [[tableColumn dataCell] setFormatter:formatter];
                    [[tableColumn dataCell] setAlignment:NSRightTextAlignment];
                    break;
                case 2:
                    formatter = [[[NSNumberFormatter alloc] init] autorelease];
                    [formatter setFormatterBehavior:NSNumberFormatterDecimalStyle];
                    [formatter setPositiveFormat:@"#0"];
                    [formatter setLocalizesFormat:YES]; 
                    [[tableColumn dataCell] setFormatter:formatter];
                    [[tableColumn dataCell] setAlignment:NSRightTextAlignment];
                    break;
                case 1:
                default:
                    [[tableColumn dataCell] setFormatter:nil];
                    [[tableColumn dataCell] setAlignment:NSLeftTextAlignment];
                    break;
            }
            
        }
    }
    
}

- (NSString *)keyForValue {
    return [[keys objectAtIndex:indexOfKeyForValue] valueForKey:@"key"];
}

- (int)formatForValue {
    return [[[keys objectAtIndex:indexOfKeyForValue] valueForKey:@"format"] intValue];
}

- (NSArray *)localizedKeysForValue {
    return [keys valueForKey:@"localized"];
}

- (int)indexOfKeyForValue {
    return indexOfKeyForValue;
}

- (void)setIndexOfKeyForValue:(int)index {
    indexOfKeyForValue = index;
    [self updateTableColumnBindings];
}

- (IBAction)doubleClickAction:(id)sender {
	if (([sender clickedRow] == -1) && ([sender clickedColumn] == -1)) {
		return;
	} else if ([sender clickedColumn] == 0) {
        // Show the library window
        [(PKAppDelegate *)[NSApp delegate] editLibrary:self];
        
        // We should wait until window is displayed, but how?!
        // Everything signals to early that the window is done and loaded
     
        // See which library entry is associated with the double clicked cell
        id lookedForLibEntry = [[[combinedPeaksController arrangedObjects] objectAtIndex:[sender clickedRow]] valueForKey:@"libraryEntry"];
        // PKLogDebug(@"libEntry = %@ with mocID %@", lookedForLibEntry, [lookedForLibEntry objectID]);
        
        // Select the library entry in the library's array controller
        NSArrayController *libraryArrayController = [[[(PKAppDelegate *)[NSApp delegate] library] libraryWindowController] libraryController];
        NSArray *libEntries = [libraryArrayController arrangedObjects];
        if ([libEntries containsObject:lookedForLibEntry]) {
            [libraryArrayController setSelectedObjects:[NSArray arrayWithObject:lookedForLibEntry]];
            NSTableView *libraryTableView = [[[(PKAppDelegate *)[NSApp delegate] library] libraryWindowController] tableView];
            [libraryTableView scrollRowToVisible:[libraryTableView selectedRow]];
        } else {
            // Race condition causes this failure. Can't change the selection when the arraycontroller is being inited. Waiting doesn't work?!
            PKLogError(@"Library Entry not found. Try again... ");
        }

		return;
    } else if ([sender clickedRow] == -1) {
        // A column was double clicked
        // Bring forward the associated file
        PKGCMSDocument *document = [[[tableView tableColumns] objectAtIndex:[sender clickedColumn]] identifier];
        [[PKDocumentController sharedDocumentController] showDocument:document];
    } else {
        // A cell was double clicked
        // Bring forwars associated file and
        // select associated peak
        PKGCMSDocument *document = [[[tableView tableColumns] objectAtIndex:[sender clickedColumn]] identifier];
        [[PKDocumentController sharedDocumentController] showDocument:document];
        
        PKCombinedPeak *combinedPeak = [[combinedPeaksController arrangedObjects] objectAtIndex:[sender clickedRow]];
        PKPeakRecord *peak = [combinedPeak valueForKey:[document uuid]];
        NSArrayController *chromatogramsController = [[document mainWindowController] chromatogramsController];
        if (peak) {
            if (![[chromatogramsController selectedObjects] containsObject:[document chromatogramForModel:[peak model]]]) {
                if ([[chromatogramsController selectedObjects] count] > 1) {
                    [chromatogramsController addSelectedObjects:[NSArray arrayWithObject:[document chromatogramForModel:[peak model]]]];
                } else {             
                    [chromatogramsController setSelectedObjects:[NSArray arrayWithObject:[document chromatogramForModel:[peak model]]]];
                }
            }
            [[[document mainWindowController] peakController] setSelectedObjects:[NSArray arrayWithObject:peak]];
        } else {
            // Attempt to find the peak!       
#warning Should check if there is an identified peak with this libraryHit first
            
            NSString *model = nil;
            if ([[combinedPeak libraryEntry] model]) {
                model = [[combinedPeak libraryEntry] model];
            } else {
                // If no model is set for the library entry, fetch it elsewhere...
                model = [[[[combinedPeak peaks] allValues] objectAtIndex:0] model];
            }
            [document addChromatogramForModel:model];
            PKChromatogram *chromatogram = [document chromatogramForModel:model];
            NSAssert(chromatogram, @"No chromatogram for requested model returned.");
            NSError *error = nil;
            if ([chromatogram countOfBaselinePoints] < 2) {
                [chromatogram detectBaselineAndReturnError:&error];
            }
            if (error) {
                [self presentError:error];
                return;
            }
            [chromatogram detectPeaksAndReturnError:&error];
            if (error) {
                [self presentError:error];
                return;
            }
            [chromatogramsController setSelectedObjects:[NSArray arrayWithObject:chromatogram]];
            // Find peak closest to averageRetentionTime
            float retTime = [[combinedPeak averageRetentionIndex] floatValue];
            float smallestDifference = fabsf([[[[chromatogram peaks] objectAtIndex:0] retentionIndex] floatValue] - retTime);
            unsigned int i, iout, count = [[chromatogram peaks] count];
            if (count > 0) {
                iout = 0;
                for (i = 0; i < count; i++) {
                      PKPeakRecord *peak = [[chromatogram peaks] objectAtIndex:i];
                      if (fabsf([[peak retentionIndex] floatValue] - retTime) < smallestDifference) {
                          smallestDifference = fabsf([[peak retentionIndex] floatValue] - retTime);
                          iout = i;
                      }
                }
                [(PKPeakRecord *)[[chromatogram peaks] objectAtIndex:iout] addSearchResultForLibraryEntry:(PKManagedLibraryEntry *)[combinedPeak libraryEntry]];
                [[[document mainWindowController] peakController] setSelectedObjects:[NSArray arrayWithObject:[[chromatogram peaks] objectAtIndex:iout]]];
            } else {
                PKLogError(@"No peak found in chromatogram. Check baseline and peak detection settings.");
            }
        }
 	}
}

- (IBAction)sortArrangedObjects:(id)sender
{
    [combinedPeaksController setSortDescriptors:[NSArray arrayWithObject:[[[NSSortDescriptor alloc] initWithKey:[self sortKey] ascending:[self sortDirection]] autorelease]]];
}


- (NSString *)sortKey
{
    return [[sortKeys objectAtIndex:indexOfSortKey] valueForKey:@"key"];
}

- (NSArray *)localizedSortKeys
{
    return [sortKeys valueForKey:@"localized"];
}

- (int)indexOfSortKey {
    return indexOfSortKey;
}


- (BOOL)sortDirection {
    return sortDirection;
}

- (void)setIndexOfSortKey:(int)index {
    sortDirection = (index != indexOfSortKey);
    indexOfSortKey = index;
    [self sortArrangedObjects:self];
}

- (IBAction)setUniqueSymbols:(id)sender {
    [[(PKAppDelegate *)[NSApp delegate] summarizer] setUniqueSymbols];
}

- (void)tableView:(NSTableView *)aTableView willDisplayCell:(id)aCell forTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex {
    PKCombinedPeak *combinedPeak = [[combinedPeaksController arrangedObjects] objectAtIndex:rowIndex];
    if (![[aTableColumn identifier] isKindOfClass:[PKGCMSDocument class]]) {
        [aCell setTextColor:[NSColor blackColor]];
		return;
   	}
    PKPeakRecord *peak = [combinedPeak valueForKey:[[aTableColumn identifier] uuid]];
    if ([peak flagged]) {
        [aCell setTextColor:[NSColor redColor]];   
    } else {
        [aCell setTextColor:[NSColor blackColor]];
    }
}

#pragma mark Tableview Delegate Methods
- (BOOL)tableView:(NSTableView *)tv acceptDrop:(id <NSDraggingInfo>)info row:(int)row dropOperation:(NSTableViewDropOperation)operation {
    if (tv == tableView) {
        if ([[info draggingPasteboard] availableTypeFromArray:[NSArray arrayWithObject:@"JKManagedLibraryEntryURIType"]]) {
            // Add the library entry to the peak
            PKCombinedPeak *combinedPeak = [[combinedPeaksController arrangedObjects] objectAtIndex:row];
            
            NSString *stringURI = [[info draggingPasteboard] stringForType:@"JKManagedLibraryEntryURIType"];
            NSURL *libraryHitURI = [NSURL URLWithString:stringURI];
            NSManagedObjectContext *moc = [[[NSApp delegate] library] managedObjectContext];
            NSManagedObjectID *mid = [[moc persistentStoreCoordinator] managedObjectIDForURIRepresentation:libraryHitURI];
           
            if (!mid)
                return NO;
            PKManagedLibraryEntry *managedLibraryEntry = (PKManagedLibraryEntry *)[moc objectWithID:mid];
            [combinedPeak setLibraryEntry:(PKLibraryEntry *)managedLibraryEntry];
            return YES;
  		}	
    }
    return NO;    
}

- (NSDragOperation)tableView:(NSTableView*)tv validateDrop:(id <NSDraggingInfo>)info proposedRow:(int)row proposedDropOperation:(NSTableViewDropOperation)op {
    if (tv == tableView) {
        if ([[info draggingPasteboard] availableTypeFromArray:[NSArray arrayWithObject:@"JKManagedLibraryEntryURIType"]]) {
            if (row < [[combinedPeaksController arrangedObjects] count]) {
                [tv setDropRow:row dropOperation:NSTableViewDropOn];
                return NSDragOperationMove;
            }
		}
	} 
    return NSDragOperationNone;    
}
#pragma mark -

#pragma mark Properties
@synthesize sortDirection;
@synthesize combinedPeaksController;
@synthesize sortKeys;
@synthesize keys;
@synthesize tableView;
#pragma mark -

@end
