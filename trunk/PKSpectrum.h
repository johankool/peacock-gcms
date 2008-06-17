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

#import "PKModelObject.h"
#import "PKComparableProtocol.h"
#import "PKTargetObjectProtocol.h"

@class PKLibraryEntry;
@class PKGCMSDocument;
@class PKPeakRecord;
@class PKSpectrumDataSeries;

@interface PKSpectrum : PKModelObject <NSCoding, PKComparableProtocol, PKTargetObjectProtocol> {
	PKPeakRecord *peak;
	NSString *model;
    	
	int numberOfPoints;
	float *masses;
	float *intensities;
    BOOL combined;
}

- (id)initWithModel:(NSString *)modelString;

#pragma mark ACTIONS

- (PKSpectrum *)spectrumBySubtractingSpectrum:(PKSpectrum *)inSpectrum;
- (PKSpectrum *)spectrumByAveragingWithSpectrum:(PKSpectrum *)inSpectrum;
- (PKSpectrum *)spectrumByAveragingWithSpectrum:(PKSpectrum *)inSpectrum  withWeight:(float)weight;
- (PKSpectrum *)normalizedSpectrum;

- (float)scoreComparedTo:(id <PKComparableProtocol>)inSpectrum;
- (float)scoreComparedTo:(id <PKComparableProtocol>)libraryEntry usingMethod:(int)scoreBasis penalizingForRententionIndex:(BOOL)penalizeForRetentionIndex;
- (float)oldScoreComparedTo:(id <PKComparableProtocol>)libraryEntry usingMethod:(int)scoreBasis penalizingForRententionIndex:(BOOL)penalizeForRetentionIndex;
- (NSNumber *)retentionIndex;
- (NSString *)peakTable;
- (NSString *)legendEntry;
    
#pragma mark ACCESSORS
- (PKGCMSDocument *)document;
- (void)setPeak:(PKPeakRecord *)inValue;
- (PKPeakRecord *)peak;
- (NSString *)model;
- (void)setModel:(NSString *)aString;
- (int)numberOfPoints;
- (void)setMasses:(float *)inArray withCount:(int)inValue;
- (float *)masses;
- (void)setIntensities:(float *)inArray withCount:(int)inValue;
- (float *)intensities;
- (BOOL)combined;
- (void)setCombined:(BOOL)inValue;

@property (getter=masses) float *masses;
@property (assign,getter=peak,setter=setPeak:) PKPeakRecord *peak;
@property (getter=numberOfPoints) int numberOfPoints;
@property (getter=intensities) float *intensities;
@end
