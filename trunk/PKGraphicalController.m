//
//  PKGraphicalController.m
//  Peacock
//
//  Created by Johan Kool on 20-11-07.
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

#import "PKGraphicalController.h"

#import "PKGraphView.h"
#import "PKGCMSDocument.h"
#import "PKChromatogramDataSeries.h"
#import "PKChromatogram.h"

@implementation PKGraphicalController
- (id)init {
    self = [super initWithWindowNibName:@"PKGraphical"];
    if (self) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(documentLoaded:) name:@"JKGCMSDocument_DocumentLoadedNotification" object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(documentUnloaded:) name:@"JKGCMSDocument_DocumentUnloadedNotification" object:nil];
        chromatogramDataSeries = [[NSMutableArray alloc] init];
        peaks = [[NSMutableArray alloc] init];
        
    }
    return self;
}

- (void) dealloc
{
    [chromatogramDataSeries release];
    [peaks release];
    [super dealloc];
}

#pragma mark -

#pragma mark Window Management
- (void)windowDidLoad {
    [self sharedPrintInfoUpdated];
    
    [graphView bind:@"dataSeries" toObject:chromatogramDataSeriesController
           withKeyPath:@"arrangedObjects" options:nil];
    [graphView bind:@"peaks" toObject:peaksController
           withKeyPath:@"arrangedObjects" options:nil];

    [graphView setKeyForXValue:@"Time"];
    [graphView setKeyForYValue:@"Total Intensity"];
    
    [graphView showAll:self];
    
    [scrollView setHasHorizontalRuler:YES];
    [scrollView setHasVerticalRuler:YES];
    [[scrollView horizontalRulerView] setMeasurementUnits:@"Centimeters"];
    [[scrollView verticalRulerView] setMeasurementUnits:@"Centimeters"];
    [scrollView setRulersVisible:YES];
}

- (void)sharedPrintInfoUpdated {
    NSSize paperSize = [[NSPrintInfo sharedPrintInfo] paperSize];
    NSRect paperRect = NSMakeRect(0.0f, 0.0f, paperSize.width, paperSize.height);
    [[scrollView documentView] setFrame:paperRect];
    [graphView setFrame:paperRect];
    
}


- (void)documentLoaded:(NSNotification *)aNotification
{
    // Present graphdataseries in colors
    NSColorList *peakColors = [NSColorList colorListNamed:@"Peacock Series"];
    if (peakColors == nil) {
        peakColors = [NSColorList colorListNamed:@"Crayons"]; // Crayons should always be there, as it can't be removed through the GUI
    }
    NSArray *peakColorsArray = [peakColors allKeys];
    int peakColorsArrayCount = [peakColorsArray count];

    id document = [aNotification object];
    if ([document isKindOfClass:[PKGCMSDocument class]]) {
        PKChromatogram *chromatogram = [document ticChromatogram];
        PKChromatogramDataSeries *cgds = [[[PKChromatogramDataSeries alloc] initWithChromatogram:chromatogram] autorelease];
        // sets title to "filename: code - description (model)"
        [cgds setSeriesTitle:[NSString stringWithFormat:@"%@: %@ - %@ (%@)", [document displayName], [document sampleCode],[document sampleDescription],[chromatogram model]]];
        [cgds setSeriesColor:[peakColors colorWithKey:[peakColorsArray objectAtIndex:[chromatogramDataSeries count]%peakColorsArrayCount]]];
        //       [cgds setFilterPredicate:[self filterPredicate]];
        [cgds setAcceptableKeysForXValue:[NSArray arrayWithObjects:NSLocalizedString(@"Retention Index", @""), NSLocalizedString(@"Scan", @""), NSLocalizedString(@"Time", @""), nil]];
        [cgds setAcceptableKeysForYValue:[NSArray arrayWithObjects:NSLocalizedString(@"Total Intensity", @""), nil]];                    
        [cgds setFilterPredicate:[NSPredicate predicateWithFormat:@"confirmed == YES"]];
        [chromatogramDataSeriesController addObject:cgds];
        [peaksController addObjects:[document peaks]];
        [graphView showAll:self];
     }
}

- (void)documentUnloaded:(NSNotification *)aNotification
{
    id object = [aNotification object];
    NSMutableArray *objectsToRemove = [NSMutableArray array];
    for (PKChromatogramDataSeries *cgds in [chromatogramDataSeriesController arrangedObjects]) {
        if ([cgds chromatogram] == [object ticChromatogram]) {
            [objectsToRemove addObject:cgds];
        }
    }
    [chromatogramDataSeriesController removeObjects:objectsToRemove];
}
- (PKGraphView *)graphView {
    return graphView;
}

@synthesize chromatogramDataSeries;
@synthesize peaks;
@end
