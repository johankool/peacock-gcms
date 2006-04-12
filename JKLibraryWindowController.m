//
//  This file is part of the application with the working name:
//  Peacock
//
//  Created by Johan Kool.
//  Copyright (c) 2003-2005 Johan Kool. All rights reserved.
//

#import "JKLibraryWindowController.h"
#import "SpectrumGraphDataSerie.h"
#import "JKLibrary.h"
#import "MyGraphView.h"
#import "JKLibraryEntry.h"

@implementation JKLibraryWindowController

-(id)init {
	self = [super initWithWindowNibName:@"JKLibrary"];
    if (self != nil) {
        [self setShouldCloseDocument:YES];
    }
    return self;
}

-(void)windowDidLoad {
	[spectrumView setShouldDrawLabels:NO];
	[spectrumView setShouldDrawLegend:NO];
	[spectrumView setPlottingArea:NSMakeRect(30,20,[spectrumView bounds].size.width-40,[spectrumView bounds].size.height-30)];
	[spectrumView setBackColor:[NSColor clearColor]];
	
	[[self libraryController] setContent:[[self document] libraryArray]];
	
	[[self libraryController] addObserver:self forKeyPath:@"selection" options:nil context:nil];
}


- (void)observeValueForKeyPath:(NSString *)keyPath
					  ofObject:(id)object
						change:(NSDictionary *)change
					   context:(void *)context {
	[self displaySpectrum:[[[self libraryController] selectedObjects] objectAtIndex:0]];
}

-(void)displaySpectrum:(JKLibraryEntry *)spectrum {
	SpectrumGraphDataSerie *spectrumDataSerie;
	
	spectrumDataSerie = [[SpectrumGraphDataSerie alloc] init];
	[spectrumDataSerie loadDataPoints:[spectrum numberOfPoints] withXValues:[spectrum masses] andYValues:[spectrum intensities]];
	
	[(NSArrayController*)[spectrumView dataSeriesContainer] addObject:spectrumDataSerie];
	
	[spectrumDataSerie setSeriesType:2]; // Spectrum kind of plot
	
	[spectrumView setKeyForXValue:@"Mass"];
	[spectrumView setKeyForYValue:@"Intensity"];
	
	[spectrumDataSerie setSeriesTitle:NSLocalizedString(@"Library Entry",@"")];
	[spectrumDataSerie setSeriesColor:[NSColor blueColor]];
	[spectrumDataSerie setKeyForXValue:[spectrumView keyForXValue]];
	[spectrumDataSerie setKeyForYValue:[spectrumView keyForYValue]];
	
	[spectrumView setNeedsDisplay:YES];	
	[spectrumDataSerie release];
}

//-(void)displaySpectrum:(JKLibraryEntry *)spectrum {
//	SpectrumGraphDataSerie *spectrumDataSerie;
//	
//	// Clear current content
//	[[spectrumView dataSeries] removeAllObjects];
//	
//	spectrumDataSerie = [[SpectrumGraphDataSerie alloc] init];
//	//[spectrumDataSerie setDataArray:[spectrum points]];
//	[spectrumDataSerie loadDataPoints:[spectrum numberOfPoints] withXValues:[spectrum masses] andYValues:[spectrum intensities]];
//	
//	[[spectrumView dataSeries] addObject:spectrumDataSerie];
//	
//	[spectrumDataSerie setSeriesType:2]; // Spectrum kind of plot
//	
//	[spectrumView setKeyForXValue:@"Mass"];
//	[spectrumView setKeyForYValue:@"Intensity"];
//	
//	[spectrumDataSerie setKeyForXValue:[spectrumView keyForXValue]];
//	[spectrumDataSerie setKeyForYValue:[spectrumView keyForYValue]];
//	
//	
//    //set plot properties object  
//	//	[spectrum setSeriesTitle:[peak valueForKey:@"label"]]; BAD!!! because seriestitle expects attributed string?!
//	[spectrumView showAll:self];
//	[spectrumView setNeedsDisplay:YES];	
//	[spectrumDataSerie release];
//}

#pragma mark ACCESSORS

-(NSArrayController *)libraryController {
	return libraryController;
}

-(BOOL)isLoading {
	return isLoading;
}

-(void)setIsLoading:(BOOL)inValue {
	isLoading = inValue;
}

@end
