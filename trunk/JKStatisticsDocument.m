//
//  JKStatisticsDocument.m
//  Peacock
//
//  Created by Johan Kool on 19-3-06.
//  Copyright 2006-2007 Johan Kool. All rights reserved.
//

// #import "JKStatisticsDocument.h"

#import "BDAlias.h"
#import "JKCombinedPeak.h"
#import "JKLibrary.h"
#import "JKPeakRecord.h"
#import "JKStatisticsWindowController.h"
#import "JKGCMSDocument.h"
#import "MyGraphDataSerie.h"
#import "JKStatisticsPrintView.h"

NSString *const JKStatisticsDocument_DocumentDeactivateNotification = @"JKStatisticsDocument_DocumentDeactivateNotification";
NSString *const JKStatisticsDocument_DocumentActivateNotification   = @"JKStatisticsDocument_DocumentActivateNotification";
NSString *const JKStatisticsDocument_DocumentLoadedNotification     = @"JKStatisticsDocument_DocumentLoadedNotification";

@implementation JKStatisticsDocument

#pragma mark INITIALIZATION

- (id)init {
	self = [super init];
    if (self != nil) {
        _documentProxy = [[NSDictionary alloc] initWithObjectsAndKeys:@"_documentProxy", @"_documentProxy",nil];
        numberOfFactors = 4;
        scores = 1;
        rotation = 1;
        groupSymbols = [[[[NSUserDefaultsController sharedUserDefaultsController] values] valueForKey:@"groupSymbols"] intValue];
        [[self undoManager] disableUndoRegistration];
        [self setPrintInfo:[NSPrintInfo sharedPrintInfo]];
        [[self printInfo] setOrientation:NSLandscapeOrientation];
        printView = [[JKStatisticsPrintView alloc] initWithDocument:self];
        [[self undoManager] enableUndoRegistration];
        
    }
    return self;
}

- (void)dealloc {
    [_documentProxy release];
    if (statisticsWindowController) {
        [statisticsWindowController release];
    }
    [super dealloc];
}

#pragma mark WINDOW MANAGEMENT

- (void)makeWindowControllers {
    if (!statisticsWindowController) {
        statisticsWindowController = [[JKStatisticsWindowController alloc] init];
    }
	[self addWindowController:statisticsWindowController];
}

#pragma mark FILE ACCESS MANAGEMENT

- (NSFileWrapper *)fileWrapperRepresentationOfType:(NSString *)aType {
	if ([aType isEqualToString:@"Peacock Statistics File"] || [aType isEqualToString:@"nl.johankool.peacock.statistics"]) {
		
		NSMutableData *data;
		NSKeyedArchiver *archiver;
		data = [NSMutableData data];
		archiver = [[NSKeyedArchiver alloc] initForWritingWithMutableData:data];
        [archiver setDelegate:self];
		[archiver encodeInt:2 forKey:@"version"];
		[archiver encodeObject:[statisticsWindowController combinedPeaks] forKey:@"combinedPeaks"];
		[archiver encodeObject:[statisticsWindowController ratioValues] forKey:@"ratioValues"];
		[archiver encodeObject:[statisticsWindowController metadata] forKey:@"metadata"];
		[archiver encodeObject:[statisticsWindowController files] forKey:@"files"];
		[archiver encodeObject:[statisticsWindowController logMessages] forKey:@"logMessages"];
		[archiver encodeInt:[statisticsWindowController peaksToUse] forKey:@"peaksToUse"];
        [archiver encodeInt:[statisticsWindowController columnSorting] forKey:@"columnSorting"];
        [archiver encodeBool:[statisticsWindowController penalizeForRetentionIndex] forKey:@"penalizeForRetentionIndex"];
        [archiver encodeBool:[statisticsWindowController setPeakSymbolToNumber] forKey:@"setPeakSymbolToNumber"];
        [archiver encodeObject:[statisticsWindowController matchThreshold] forKey:@"matchThreshold"];
        [archiver encodeInt:[statisticsWindowController scoreBasis] forKey:@"scoreBasis"];
        [archiver encodeInt:[statisticsWindowController valueToUse] forKey:@"valueToUse"];
        [archiver encodeBool:[statisticsWindowController closeDocuments] forKey:@"closeDocuments"];
        [archiver encodeBool:[statisticsWindowController calculateRatios] forKey:@"calculateRatios"];
        [archiver encodeObject:[self loadingsDataSeries] forKey:@"loadingsDataSeries"];       
        [archiver encodeObject:[self scoresDataSeries] forKey:@"scoresDataSeries"];       
        [archiver encodeInt:[self numberOfFactors] forKey:@"numberOfFactors"];
        [archiver encodeInt:[self scores] forKey:@"scores"];
        [archiver encodeInt:[self rotation] forKey:@"rotation"];
        
		[archiver finishEncoding];
		[archiver release];
		
		NSFileWrapper *fileWrapperForData = [[[NSFileWrapper alloc] initRegularFileWithContents:data] autorelease];
			
		return fileWrapperForData;
	} else {
		return nil;
	}
}

- (BOOL)readFromURL:(NSURL *)absoluteURL ofType:(NSString *)typeName error:(NSError **)outError {
	if ([typeName isEqualToString:@"Peacock Statistics File"] || [typeName isEqualToString:@"nl.johankool.peacock.statistics"]) {
        int i;
		NSFileWrapper *wrapper = [[NSFileWrapper alloc] initWithPath:[absoluteURL path]];
		NSData *data;
		NSKeyedUnarchiver *unarchiver;
		data = [wrapper regularFileContents];
		unarchiver = [[NSKeyedUnarchiver alloc] initForReadingWithData:data];
        [unarchiver setDelegate:self];
#warning [BUG] Early init of statisticsWindowController
        // Bit of a hack, these values should after all reside in the document and not in the window controller
        // but moving all the methods from the window controller is a lot of work and I don't have the time for that now.
        if (!statisticsWindowController) {
            statisticsWindowController = [[JKStatisticsWindowController alloc] init];
        }        
        
        [statisticsWindowController willChangeValueForKey:@"combinedPeaks"];
        int version = [unarchiver decodeIntForKey:@"version"];
        // open files first so we are ready to find peaks contained in combinedpeaks
		[statisticsWindowController setFiles:[unarchiver decodeObjectForKey:@"files"]];
        // Update the path to reflect changes in locations of aliases
        NSEnumerator *enumerator = [[statisticsWindowController files] objectEnumerator];
        NSMutableDictionary *dict;
        while ((dict = [enumerator nextObject]) != nil) {
        	[dict setValue:[[dict valueForKey:@"alias"] fileName] forKey:@"path"];
        }
        [statisticsWindowController setRatioValues:[unarchiver decodeObjectForKey:@"ratioValues"]];
		[statisticsWindowController setMetadata:[unarchiver decodeObjectForKey:@"metadata"]];
        // Update the metadata to reflect changes in locations of aliases etc.
        for (i = 0; i < [[statisticsWindowController files] count]; i++) {
            [statisticsWindowController collectMetadataForDocument:[[[statisticsWindowController files] objectAtIndex:i] valueForKey:@"alias"] atIndex:i];
        }
        
		[statisticsWindowController setLogMessages:[unarchiver decodeObjectForKey:@"logMessages"]];
        [statisticsWindowController setPeaksToUse:[unarchiver decodeIntForKey:@"peaksToUse"]];
        [statisticsWindowController setColumnSorting:[unarchiver decodeIntForKey:@"columnSorting"]];
        [statisticsWindowController setPenalizeForRetentionIndex:[unarchiver decodeBoolForKey:@"penalizeForRetentionIndex"]];
        [statisticsWindowController setSetPeakSymbolToNumber:[unarchiver decodeBoolForKey:@"setPeakSymbolToNumber"]];
		[statisticsWindowController setMatchThreshold:[unarchiver decodeObjectForKey:@"matchThreshold"]];
        [statisticsWindowController setScoreBasis:[unarchiver decodeIntForKey:@"scoreBasis"]];
        [statisticsWindowController setValueToUse:[unarchiver decodeIntForKey:@"valueToUse"]];
        [statisticsWindowController setCloseDocuments:[unarchiver decodeBoolForKey:@"closeDocuments"]];
        [statisticsWindowController setCalculateRatios:[unarchiver decodeBoolForKey:@"calculateRatios"]];
		[statisticsWindowController setCombinedPeaks:[unarchiver decodeObjectForKey:@"combinedPeaks"]];
        [statisticsWindowController didChangeValueForKey:@"combinedPeaks"];
        
        if (version > 1){
            [self setNumberOfFactors:[unarchiver decodeIntForKey:@"numberOfFactors"]];
            [self setScores:[unarchiver decodeIntForKey:@"scores"]];
            [self setRotation:[unarchiver decodeIntForKey:@"rotation"]];
            [self setLoadingsDataSeries:[unarchiver decodeObjectForKey:@"loadingsDataSeries"]];
            [self setScoresDataSeries:[unarchiver decodeObjectForKey:@"scoresDataSeries"]];            
        }
        JKLogDebug(@"retaincount = %d",[self retainCount]);
        [self retain];
		[unarchiver finishDecoding];
		[unarchiver release];
		[wrapper release];
		return YES;	
	} else {
		return NO;
	}	
}
		
- (id)archiver:(NSKeyedArchiver *)archiver willEncodeObject:(id)object {
    if (object == self) {
        return _documentProxy;
    } else if ([object isKindOfClass:[JKGCMSDocument class]]) {
        return [BDAlias aliasWithPath:[object fileName]];
    } else if ([object isKindOfClass:[JKLibrary class]]) {
        return [BDAlias aliasWithPath:[object fileName]];
    } else if ([object isKindOfClass:[JKPeakRecord class]]) {
        return [NSDictionary dictionaryWithObject:[object uuid] forKey:@"_peakUuid"];
    }
    return object;
}

- (id)unarchiver:(NSKeyedUnarchiver *)unarchiver didDecodeObject:(id)object {
    if ([object isKindOfClass:[NSDictionary class]]) {
        if ([[object valueForKey:@"_documentProxy"] isEqualToString:@"_documentProxy"]) {
            return self;
        } else if ([object valueForKey:@"_peakUuid"]) {
            NSString *uuid = [object valueForKey:@"_peakUuid"];
            NSEnumerator *docEnum = [[[NSDocumentController sharedDocumentController] documents] objectEnumerator];
            id document;

            while ((document = [docEnum nextObject]) != nil) {
                if ([document isKindOfClass:[JKGCMSDocument class]]) {
                    NSEnumerator *peakEnum = [[(JKGCMSDocument *)document peaks] objectEnumerator];
                    JKPeakRecord *peak;
                    
                    while ((peak = [peakEnum nextObject]) != nil) {
                        if ([[peak uuid] isEqualToString:uuid]) {
                            return peak;
                        }
                    }                    
                }
            }
            JKLogError(@"Could not find peak with uuid %@", uuid);
            return [[NSObject alloc] init]; // no autorelease?
        }
    } else if ([object isKindOfClass:[BDAlias class]]) {
        id document;
        NSError *error = [[NSError alloc] init];
        NSAssert(object, @"decoding nil BDAlias?!");
        if (![object fullPath]) {
            JKLogDebug(@"Could not resolve alias stored in document.");
            int result;
            NSArray *fileTypes = [NSArray arrayWithObject:@"peacock"];
            NSOpenPanel *oPanel = [NSOpenPanel openPanel];
            [oPanel setMessage:[NSString stringWithFormat:@"Select missing file '%@'",[object originalPath]]];
            [oPanel setPrompt:NSLocalizedString(@"Select",@"Resolving missing alias prompt")];
            [oPanel setTitle:NSLocalizedString(@"Resolve Missing File",@"Resolving missing alias title")];
            [oPanel setAllowsMultipleSelection:NO];
            result = [oPanel runModalForDirectory:nil
                                             file:nil types:fileTypes];
            if (result == NSOKButton) {
                NSArray *filesToOpen = [oPanel filenames];
                object = [BDAlias aliasWithPath:[filesToOpen objectAtIndex:0]];
            } else {
                JKLogError(@"Could not resolve alias stored in document!!! This is a big problem!");
                
                return object;                
            }
        }
        JKLogDebug(@"BDAlias at path: %@",[object fullPath]);
		document = [[NSDocumentController sharedDocumentController] documentForURL:[NSURL fileURLWithPath:[object fullPath]]];
        if (!document) {
            document = [[NSDocumentController sharedDocumentController] openDocumentWithContentsOfURL:[NSURL fileURLWithPath:[object fullPath]] display:NO error:&error];
            if (!document) {
                // maybe try to determine cause of error and recover first
                NSAlert *theAlert = [NSAlert alertWithError:error];
                [theAlert runModal]; // ignore return value                
            }
        }
        [document retain];
        return document;
    }
    return object;
}

- (void)setUniqueSymbols 
{
    int j;
    int compoundCount;
    NSNumber *countForGroup;
    JKCombinedPeak *compound;
    NSMutableDictionary *uniqueDict = [NSMutableDictionary dictionary];
    NSMutableArray *uniqueSymbolArray = [NSMutableArray array];
    NSMutableArray *peaks = [[statisticsWindowController combinedPeaks] mutableCopy];

    // Sort array on retention index
    NSSortDescriptor *retentionIndexDescriptor =[[NSSortDescriptor alloc] initWithKey:@"averageRetentionIndex" 
                                                                            ascending:YES];
    NSArray *sortDescriptors=[NSArray arrayWithObjects:retentionIndexDescriptor,nil];
    [peaks sortUsingDescriptors:sortDescriptors];
    [retentionIndexDescriptor release];
    
    compoundCount = [peaks count];
    
    if (groupSymbols) {
        // Compound symbol
        for (j=0; j < compoundCount; j++) {
            compound = [peaks objectAtIndex:j];
            // ensure symbol is set
            if (![compound group] || [[compound group] isEqualToString:@""]) {
                [compound setGroup:@"X"];
            }
            if (([compound symbol]) && (![[compound symbol] isEqualToString:@""]) && ([uniqueSymbolArray indexOfObjectIdenticalTo:[compound symbol]] == NSNotFound)) {
                [compound setSymbol:[compound symbol]];
                [uniqueSymbolArray addObject:[compound symbol]];
                continue;
            }
            // replace odd characters
            // ensure symbol starts with letter
            //        if ([[compound group] rangeOfCharacterFromSet:[NSCharacterSet decimalDigitCharacterSet]].location == 0) {
            //            NSString *newGroup = [NSString stringWithFormat:@"X%@", [compound group]];
            //            [compound setGroup:newGroup];
            //        }
            // get countForSymbol 
            countForGroup = [uniqueDict valueForKey:[compound group]];
            if (!countForGroup) {
                countForGroup = [NSNumber numberWithInt:1];
            } else if (countForGroup) {
                countForGroup = [NSNumber numberWithInt:[countForGroup intValue]+1];
            }
            [uniqueDict setValue:countForGroup forKey:[compound group]];
            if ([[[compound group] substringFromIndex:[[compound group] length]-1] rangeOfCharacterFromSet:[NSCharacterSet decimalDigitCharacterSet]].length == 1) { // group ends with a number
                if ([countForGroup intValue] == 1) {
                    [compound setSymbol:[NSString stringWithFormat:@"%@", [compound group]]];              
                } else {
                    [compound setSymbol:[NSString stringWithFormat:@"%@-%d", [compound group], [countForGroup intValue]]];            
                }
            } else {
                // must be unique (note that a few cases are missed here, e.g. when a group is named X (and gets count 11 and another X1 and gets count 1)
                [compound setSymbol:[NSString stringWithFormat:@"%@%d", [compound group], [countForGroup intValue]]];            
        }
            [uniqueSymbolArray addObject:[compound symbol]];
        }
        
    } else {
        // Compound symbol
        for (j=0; j < compoundCount; j++) {
            compound = [peaks objectAtIndex:j];
            [compound setSymbol:[NSString stringWithFormat:@"%d", j+1]];            
        }
    }
        
    
}

- (NSString *)exportForFactorAnalysis
{
    NSMutableString *outStr = [[NSMutableString alloc] init]; 
    int i,j;
    int fileCount = [[statisticsWindowController files] count];
    int compoundCount;
    float surface, totalSurface, normalizedSurface;
    JKCombinedPeak *compound;
    id file;
    
    // Make sure that the count is higher than 1
    NSPredicate *filterPredicate = [NSPredicate predicateWithFormat:@"countOfPeaks > 1"];
    NSMutableArray *filteredPeaks = [[[statisticsWindowController combinedPeaks] filteredArrayUsingPredicate:filterPredicate] mutableCopy];
    
    // Sort array on retention index
    NSSortDescriptor *retentionIndexDescriptor =[[NSSortDescriptor alloc] initWithKey:@"averageRetentionIndex" 
                                                                            ascending:YES];
    NSArray *sortDescriptors=[NSArray arrayWithObjects:retentionIndexDescriptor,nil];
    [filteredPeaks sortUsingDescriptors:sortDescriptors];
    [retentionIndexDescriptor release];
    
    compoundCount = [filteredPeaks count];
    
    [outStr appendString:@"Sample"];
    
    // Compound symbol
    for (j=0; j < compoundCount; j++) {
        compound = [filteredPeaks objectAtIndex:j];
        [outStr appendFormat:@",%@", [compound symbol]];
    }
    [outStr appendString:@"\n"];

    for (i=0; i < fileCount; i++) {
        file = [[statisticsWindowController files] objectAtIndex:i];
        // File sample code
        // ensure code is set
        // ensure code starts with letter
        // must be unique
        [outStr appendFormat:@"%@", [[[statisticsWindowController metadata] objectAtIndex:0] valueForKey:[NSString stringWithFormat:@"file_%d",i]] ];

        // For each file calculated total surface
        totalSurface = 0.0;
        for (j=0; j < compoundCount; j++) {
            compound = [filteredPeaks objectAtIndex:j];
            surface = [[[compound valueForKey:[NSString stringWithFormat:@"file_%d",i]] valueForKey:@"surface"] floatValue];
            totalSurface = totalSurface + surface;
        }
        // Surface values
        for (j=0; j < compoundCount; j++) {
            compound = [filteredPeaks objectAtIndex:j];
//            normalizedSurface = nil;
            surface = [[[compound valueForKey:[NSString stringWithFormat:@"file_%d",i]] valueForKey:@"surface"] floatValue];
            normalizedSurface = surface * 100 / totalSurface;
//            if (normalizedSurface != nil) {
                [outStr appendFormat:@",%g", normalizedSurface];					
//            } else {
//                [outStr appendString:@",0"];										
//            }
        }
        [outStr appendString:@"\n"];
    }
    
    return outStr;
}

- (BOOL)performFactorAnalysis
{
     // Get temporary directory
    NSString *tempDir = [NSTemporaryDirectory() stringByAppendingPathComponent:@"Peacock"];
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    [fileManager removeFileAtPath:tempDir handler:nil];
    if (![fileManager createDirectoryAtPath:tempDir attributes:nil]) {
        JKLogError(@"Could not create temporary directory at %@.", tempDir);
        return NO;
    }
    
    if (![fileManager fileExistsAtPath:@"/usr/bin/R"]) {
        [self setLoadingsDataSeries:nil];
        [self setScoresDataSeries:nil];
        NSRunAlertPanel(@"Factor Analysis Failed",@"The factor analysis could not be run because R doesn't seem to be installed on this computer. You can obtain this software from http://www.r-project.org",@"OK",nil,nil);    
        return NO;        
    }
    
    // Export data
    [[self exportForFactorAnalysis] writeToFile:[tempDir stringByAppendingPathComponent:@"data.csv"] atomically:NO encoding:NSASCIIStringEncoding error:NULL];
    
    // Create R run file
    NSString *rCommandPath;
    NSMutableString *rCommand;
    if (rCommandPath = [[NSBundle mainBundle] pathForResource:@"factoranalysis" ofType:@"R"])  {
        rCommand = [NSMutableString stringWithContentsOfFile:rCommandPath encoding:NSASCIIStringEncoding error:NULL];
        [rCommand replaceOccurrencesOfString:@"{TEMP_DIR}" withString:tempDir options:0 range:NSMakeRange(0, [rCommand length])];
        [rCommand replaceOccurrencesOfString:@"{NUMBER_OF_FACTORS}" withString:[NSString stringWithFormat:@"%d",[self numberOfFactors]] options:0 range:NSMakeRange(0, [rCommand length])];
        switch ([self scores]) {
            case 0:
            default:
                [rCommand replaceOccurrencesOfString:@"{SCORES}" withString:@"none" options:0 range:NSMakeRange(0, [rCommand length])];
                break;
            case 1:
                [rCommand replaceOccurrencesOfString:@"{SCORES}" withString:@"regression" options:0 range:NSMakeRange(0, [rCommand length])];
                break;
            case 2:
                [rCommand replaceOccurrencesOfString:@"{SCORES}" withString:@"Bartlettt" options:0 range:NSMakeRange(0, [rCommand length])];
                break;
        }
        switch ([self rotation]) {
            case 0:
            default:
                [rCommand replaceOccurrencesOfString:@"{ROTATION}" withString:@"none" options:0 range:NSMakeRange(0, [rCommand length])];
                break;
            case 1:
                [rCommand replaceOccurrencesOfString:@"{ROTATION}" withString:@"varimax" options:0 range:NSMakeRange(0, [rCommand length])];
                break;
            case 2:
                [rCommand replaceOccurrencesOfString:@"{ROTATION}" withString:@"optimax" options:0 range:NSMakeRange(0, [rCommand length])];
                break;
        }
    } else {
        JKLogError(@"Resource file 'factoranalysis.R' not found.");
        return NO;
    }
    
//    JKLogDebug(rCommand);
    
    [rCommand writeToFile:[tempDir stringByAppendingPathComponent:@"input.R"] atomically:NO encoding:NSASCIIStringEncoding error:NULL];
    
    // Create task
    NSTask *aTask = [[NSTask alloc] init];
    NSMutableArray *args = [NSMutableArray array];
    
    // Set arguments
    [args addObject:@"--vanilla"];
    [args addObject:@"--silent"];
    [args addObject:@"--slave"];
    [args addObject:@"--file=input.R"];
    [aTask setCurrentDirectoryPath:tempDir];
    [aTask setLaunchPath:@"/usr/bin/R"];
//    [fileManager createFileAtPath:[tempDir stringByAppendingPathComponent:@"output.txt"] contents:[@"" dataUsingEncoding:NSASCIIStringEncoding] attributes:nil];
//    [aTask setStandardOutput:[NSFileHandle fileHandleForWritingAtPath:[tempDir stringByAppendingPathComponent:@"output.txt"]]];
//    [fileManager createFileAtPath:[tempDir stringByAppendingPathComponent:@"error.txt"] contents:[@"" dataUsingEncoding:NSASCIIStringEncoding] attributes:nil];
//    [aTask setStandardError:[NSFileHandle fileHandleForWritingAtPath:[tempDir stringByAppendingPathComponent:@"error.txt"]]];
    [aTask setArguments:args];
    
    // Run task
    [aTask launch];
    
    // Have a little patience
    [aTask waitUntilExit];
    
    int status = [aTask terminationStatus];
    if (status == 0) {
        JKLogInfo(@"Task succeeded.");
    } else {
        [self setLoadingsDataSeries:nil];
        [self setScoresDataSeries:nil];
        NSRunAlertPanel(@"Factor Analysis Failed",@"The factor analysis could not be run successfully.",@"OK",nil,nil);    
        return NO;
    }

    NSRunAlertPanel(@"Factor Analysis Paused",@"You can now edit the factor analysis results before they get load back into Peacock.",@"Continue",nil,nil);    

    // Read Loadings
    if ([fileManager fileExistsAtPath:[tempDir stringByAppendingPathComponent:@"loadings.csv"]]) {
        NSMutableArray *loadings = [NSMutableArray array];
        NSString *resultString = [NSString stringWithContentsOfFile:[tempDir stringByAppendingPathComponent:@"loadings.csv"] encoding:NSASCIIStringEncoding error:NULL];
        NSArray *linesArray = [resultString componentsSeparatedByString:@"\n"];
        if ([linesArray count] > 2) {
            NSMutableArray *keyArray = [[[linesArray objectAtIndex:0] componentsSeparatedByString:@","] mutableCopy];
            [keyArray replaceObjectAtIndex:0 withObject:@"Compound"];
            int i,j;
            for (i = 0; i < [keyArray count]; i++) {
                if ([[keyArray objectAtIndex:i] hasPrefix:@"Factor"]) {
                    [keyArray replaceObjectAtIndex:i withObject:[NSString stringWithFormat:@"Factor %@", [[keyArray objectAtIndex:i] substringFromIndex:6]]];
                }
            }
            int linesCount = [linesArray count]-1; // last line is empty
            int keyCount = [keyArray count];
            for (i=1; i < linesCount; i++) {
                NSArray *lineArray = [[linesArray objectAtIndex:i] componentsSeparatedByString:@","];
                NSMutableDictionary *loading = [NSMutableDictionary dictionary];
                [loading setValue:[lineArray objectAtIndex:0] forKey:[keyArray objectAtIndex:0]];
                for (j=1; j < keyCount; j++) {
                    [loading setValue:[NSNumber numberWithFloat:[[lineArray objectAtIndex:j] floatValue]] forKey:[keyArray objectAtIndex:j]];
                }
                [loadings addObject:loading];
            }
//            if ([[[self statisticsWindowController] combinedPeaks] count] != linesCount-1) {
//                JKLogWarning(@"There might be a mismatch between loadings and metadata!");
//            }
//            
            MyGraphDataSerie *loadingsDataSerie = [[MyGraphDataSerie alloc] init];
            [loadingsDataSerie setKeyForLabel:[keyArray objectAtIndex:0]];
            [loadingsDataSerie setAcceptableKeysForLabel:[NSArray arrayWithObject:[keyArray objectAtIndex:0]]];
            [loadingsDataSerie setKeyForXValue:[keyArray objectAtIndex:1]];
            [loadingsDataSerie setKeyForYValue:[keyArray objectAtIndex:2]];
            [loadingsDataSerie setAcceptableKeysForXValue:[keyArray objectsAtIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(1,[keyArray count]-1)]]];
            [loadingsDataSerie setAcceptableKeysForYValue:[keyArray objectsAtIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(1,[keyArray count]-1)]]];
            [loadingsDataSerie setDataArray:loadings];
            [loadingsDataSerie setSeriesTitle:@"Loadings"];
            [self setLoadingsDataSeries:[NSArray arrayWithObject:loadingsDataSerie]];
            [loadingsDataSerie release];                    
        } else {
            [self setLoadingsDataSeries:nil];
        }
     } else {
        [self setLoadingsDataSeries:nil];
    }

    // Read scores
    if ([fileManager fileExistsAtPath:[tempDir stringByAppendingPathComponent:@"scores.csv"]]) {
        NSMutableArray *scoresArray = [NSMutableArray array];
        NSString *resultString = [NSString stringWithContentsOfFile:[tempDir stringByAppendingPathComponent:@"scores.csv"] encoding:NSASCIIStringEncoding error:NULL];
        NSArray *linesArray = [resultString componentsSeparatedByString:@"\n"];
        if ([linesArray count] > 2) {
            NSMutableArray *keyArray = [[[linesArray objectAtIndex:0] componentsSeparatedByString:@","] mutableCopy];
            [keyArray replaceObjectAtIndex:0 withObject:@"Sample"];
            int i,j;
            for (i = 0; i < [keyArray count]; i++) {
                if ([[keyArray objectAtIndex:i] hasPrefix:@"Factor"]) {
                    [keyArray replaceObjectAtIndex:i withObject:[NSString stringWithFormat:@"Factor %@", [[keyArray objectAtIndex:i] substringFromIndex:6]]];
                }
            }
            int linesCount = [linesArray count]-1; // last line is empty
            int keyCount = [keyArray count];
            for (i=1; i < linesCount; i++) {
                NSArray *lineArray = [[linesArray objectAtIndex:i] componentsSeparatedByString:@","];
                NSMutableDictionary *score = [NSMutableDictionary dictionary];
                [score setValue:[lineArray objectAtIndex:0] forKey:[keyArray objectAtIndex:0]];
                for (j=1; j < keyCount; j++) {
                    [score setValue:[NSNumber numberWithFloat:[[lineArray objectAtIndex:j] floatValue]] forKey:[keyArray objectAtIndex:j]];
                }
                [score setValue:[[[[self statisticsWindowController] metadata] objectAtIndex:0] valueForKey:[NSString stringWithFormat:@"file_%d",i-1]] forKey:@"Sample Code"];
                [score setValue:[[[[self statisticsWindowController] metadata] objectAtIndex:1] valueForKey:[NSString stringWithFormat:@"file_%d",i-1]] forKey:@"Sample Description"];
                [score setValue:[[[[self statisticsWindowController] metadata] objectAtIndex:2] valueForKey:[NSString stringWithFormat:@"file_%d",i-1]] forKey:@"Path"];
                [score setValue:[[[[self statisticsWindowController] metadata] objectAtIndex:3] valueForKey:[NSString stringWithFormat:@"file_%d",i-1]] forKey:@"Filename"];
                [scoresArray addObject:score];
            }

            if ([[[self statisticsWindowController] files] count] != linesCount-1) {
                JKLogWarning(@"There might be a mismatch between scores and metadata!");
            }
            
            MyGraphDataSerie *scoresDataSerie = [[MyGraphDataSerie alloc] init];
            [scoresDataSerie setKeyForLabel:[keyArray objectAtIndex:0]];
            [scoresDataSerie setAcceptableKeysForLabel:[NSArray arrayWithObjects:[keyArray objectAtIndex:0],@"Sample Code", @"Sample Description", @"Path", @"Filename",nil]];
            [scoresDataSerie setKeyForXValue:[keyArray objectAtIndex:1]];
            [scoresDataSerie setKeyForYValue:[keyArray objectAtIndex:2]];
            [scoresDataSerie setAcceptableKeysForXValue:[keyArray objectsAtIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(1,[keyArray count]-1)]]];
            [scoresDataSerie setAcceptableKeysForYValue:[keyArray objectsAtIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(1,[keyArray count]-1)]]];
            [scoresDataSerie setDataArray:scores];
            [scoresDataSerie setSeriesTitle:@"Scores"];
            [self setScoresDataSeries:[NSArray arrayWithObject:scoresDataSerie]];
            [scoresDataSerie release];                    
        } else {
            [self setScoresDataSeries:nil];
        }        
    } else {
        [self setScoresDataSeries:nil];
    }
    
//    if (![fileManager removeFileAtPath:tempDir handler:nil]) {
//        JKLogWarning(@"Could not remove temporary directory at %@.", tempDir);
//    }
    return YES;
}

#pragma mark Printing
- (BOOL)shouldChangePrintInfo:(NSPrintInfo *)newPrintInfo {
    [self setPrintInfo:newPrintInfo];
    return YES;
}
- (void)printShowingPrintPanel:(BOOL)showPanels {
    // Prepare the custom view that will be printed
    [printView preparePDFRepresentations];
    
    // Construct the print operation and setup Print panel
    NSPrintOperation *op = [NSPrintOperation
                printOperationWithView:printView
							 printInfo:[self printInfo]];
    [op setShowPanels:showPanels];
    if (showPanels) {
        // Add accessory view, if needed
		[op setAccessoryView:[statisticsWindowController printAccessoryView]];
    }
	
    // Run operation, which shows the Print panel if showPanels was YES
    [self runModalPrintOperation:op
						delegate:nil
				  didRunSelector:@selector(documentDidRunModalPrintOperation:success:contextInfo:)
					 contextInfo:NULL];
}
- (void)documentDidRunModalPrintOperation:(NSDocument *)document  success:(BOOL)success  contextInfo:(void *)contextInfo {
    //    [printView release];
}
#pragma mark -


#pragma mark Notifications
- (void)postNotification:(NSString *)notificationName
{
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    
    [center postNotificationName:notificationName object:self];
}

- (void)windowDidBecomeMain:(NSNotification *)notification
{
    [self postNotification:JKStatisticsDocument_DocumentActivateNotification];
}

- (void) windowDidResignMain: (NSNotification *) notification
{
    [self postNotification:JKStatisticsDocument_DocumentDeactivateNotification];
}

- (void) windowWillClose: (NSNotification *) notification
{
    [self postNotification:JKStatisticsDocument_DocumentDeactivateNotification];
}
#pragma mark -


#pragma mark ACCESSORS

- (JKStatisticsWindowController *)statisticsWindowController {
    return statisticsWindowController;
}

- (NSArray *)loadingsDataSeries {
	return loadingsDataSeries;
}
- (void)setLoadingsDataSeries:(NSArray *)aLoadingsDataSeries {
	[loadingsDataSeries autorelease];
	loadingsDataSeries = [aLoadingsDataSeries retain];
}

- (NSArray *)scoresDataSeries {
	return scoresDataSeries;
}
- (void)setScoresDataSeries:(NSArray *)aScoresDataSeries {
	[scoresDataSeries autorelease];
	scoresDataSeries = [aScoresDataSeries retain];
}

- (int)numberOfFactors {
	return numberOfFactors;
}
- (void)setNumberOfFactors:(int)aNumberOfFactors {
	numberOfFactors = aNumberOfFactors;
}

- (int)rotation {
	return rotation;
}
- (void)setRotation:(int)aRotation {
	rotation = aRotation;
}
- (int)scores {
	return scores;
}
- (void)setScores:(int)aScores {
	scores = aScores;
}
@end