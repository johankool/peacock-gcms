//
//  This file is part of the application with the working name:
//  Peacock
//
//  Created by Johan Kool.
//  Copyright (c) 2003-2005 Johan Kool. All rights reserved.
//

@interface JKLibraryEntry : NSObject <NSCoding> {
	NSString *name;
	NSString *formula;
	NSString *CASNumber;
	NSString *source;
	NSString *comment;	
	NSString *molString;
	NSString *symbol;
	
	float massWeight;
	
	float retentionIndex;
	float retentionTime;
		
	int numberOfPoints;
	float *masses;
	float *intensities;
	float maximumIntensity;
}

-(JKLibraryEntry *)normalizedLibraryEntry;
-(JKLibraryEntry *)negativeLibraryEntry;
-(JKLibraryEntry *)negativeNormalizedLibraryEntry;

idAccessor_h(name, setName);
idAccessor_h(formula, setFormula);
idAccessor_h(CASNumber, setCASNumber);
idAccessor_h(source, setSource);
idAccessor_h(comment, setComment);
idAccessor_h(molString, setMolString);
idAccessor_h(symbol, setSymbol);

floatAccessor_h(massWeight, setMassWeight);

floatAccessor_h(retentionIndex, setRetentionIndex);
floatAccessor_h(retentionTime, setRetentionTime);

intAccessor_h(numberOfPoints, setNumberOfPoints);
- (void)setMasses:(float *)inArray withCount:(int)inValue;
- (float *)masses;

- (void)setIntensities:(float *)inArray withCount:(int)inValue;
- (float *)intensities;
- (float)maximumIntensity;

@end
