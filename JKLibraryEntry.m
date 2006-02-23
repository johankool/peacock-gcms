//
//  This file is part of the application with the working name:
//  Peacock
//
//  Created by Johan Kool.
//  Copyright (c) 2003-2005 Johan Kool. All rights reserved.
//

#import "JKLibraryEntry.h"

@implementation JKLibraryEntry

-(id)init {
    if (self = [super init]) {
		masses = (float *) malloc(1*sizeof(float));
		intensities = (float *) malloc(1*sizeof(float));
		name = @"";
		formula = @"";
		symbol = @"";
    }
    return self;
}

- (void) dealloc {
	free(masses);
	free(intensities);
	[super dealloc];
}


idAccessor(name, setName);
idAccessor(formula, setFormula);
idAccessor(CASNumber, setCASNumber);
idAccessor(source, setSource);
idAccessor(comment, setComment);
idAccessor(molString, setMolString);
idAccessor(symbol, setSymbol);

floatAccessor(massWeight, setMassWeight);

floatAccessor(retentionIndex, setRetentionIndex);
floatAccessor(retentionTime, setRetentionTime);

intAccessor(numberOfPoints, setNumberOfPoints);
-(void)setMasses:(float *)inArray withCount:(int)inValue {
    numberOfPoints = inValue;
    masses = (float *) realloc(masses, numberOfPoints*sizeof(float));
    memcpy(masses, inArray, numberOfPoints*sizeof(float));
}

-(float *)masses {
    return masses;
}

-(void)setIntensities:(float *)inArray withCount:(int)inValue {
    numberOfPoints = inValue;
    intensities = (float *) realloc(intensities, numberOfPoints*sizeof(float));
    memcpy(intensities, inArray, numberOfPoints*sizeof(float));
	int i;
	maximumIntensity = intensities[0];
	for (i=1; i < numberOfPoints; i++) {
		if (intensities[i] > maximumIntensity) {
			maximumIntensity = intensities[i];
		}
	}
}
-(float)maximumIntensity {
    return maximumIntensity;
}
-(float *)intensities {
    return intensities;
}

-(JKLibraryEntry *)normalizedLibraryEntry {
	int i;
	JKLibraryEntry *outLibraryEntry = [[JKLibraryEntry alloc] init];
	float intensitiesOut[numberOfPoints];
	
	for (i = 0; i < numberOfPoints; i++) {
		intensitiesOut[i] = intensities[i]/maximumIntensity;
	}
	
	[outLibraryEntry setMasses:masses withCount:numberOfPoints];
	[outLibraryEntry setIntensities:intensitiesOut withCount:numberOfPoints];
	
	// Copy other attributes
	[outLibraryEntry setRetentionTime:retentionTime];
	[outLibraryEntry setName:name];
	[outLibraryEntry setFormula:formula];
	[outLibraryEntry setCASNumber:CASNumber];
	[outLibraryEntry setSource:source];
	[outLibraryEntry setComment:comment];
	[outLibraryEntry setMolString:molString];
	[outLibraryEntry setSymbol:symbol];
	[outLibraryEntry setMassWeight:massWeight];
	[outLibraryEntry setRetentionIndex:retentionIndex];
	[outLibraryEntry setRetentionTime:retentionTime];
	[outLibraryEntry autorelease];
	return outLibraryEntry;
}

-(JKLibraryEntry *)negativeLibraryEntry {
	int i;
	JKLibraryEntry *outLibraryEntry = [[JKLibraryEntry alloc] init];
	float intensitiesOut[numberOfPoints];
	
	for (i = 0; i < numberOfPoints; i++) {
		intensitiesOut[i] = -intensities[i];
	}
	
	[outLibraryEntry setMasses:masses withCount:numberOfPoints];
	[outLibraryEntry setIntensities:intensitiesOut withCount:numberOfPoints];
	
	// Copy other attributes
	[outLibraryEntry setRetentionTime:retentionTime];
	[outLibraryEntry setName:name];
	[outLibraryEntry setFormula:formula];
	[outLibraryEntry setCASNumber:CASNumber];
	[outLibraryEntry setSource:source];
	[outLibraryEntry setComment:comment];
	[outLibraryEntry setMolString:molString];
	[outLibraryEntry setSymbol:symbol];
	[outLibraryEntry setMassWeight:massWeight];
	[outLibraryEntry setRetentionIndex:retentionIndex];
	[outLibraryEntry setRetentionTime:retentionTime];
	[outLibraryEntry autorelease];
	return outLibraryEntry;
}

-(JKLibraryEntry *)negativeNormalizedLibraryEntry {
	int i;
	JKLibraryEntry *outLibraryEntry = [[JKLibraryEntry alloc] init];
	float intensitiesOut[numberOfPoints];
	
	for (i = 0; i < numberOfPoints; i++) {
		intensitiesOut[i] = -intensities[i]/maximumIntensity;
	}
	
	[outLibraryEntry setMasses:masses withCount:numberOfPoints];
	[outLibraryEntry setIntensities:intensitiesOut withCount:numberOfPoints];
	
	// Copy other attributes
	[outLibraryEntry setRetentionTime:retentionTime];
	[outLibraryEntry setName:name];
	[outLibraryEntry setFormula:formula];
	[outLibraryEntry setCASNumber:CASNumber];
	[outLibraryEntry setSource:source];
	[outLibraryEntry setComment:comment];
	[outLibraryEntry setMolString:molString];
	[outLibraryEntry setSymbol:symbol];
	[outLibraryEntry setMassWeight:massWeight];
	[outLibraryEntry setRetentionIndex:retentionIndex];
	[outLibraryEntry setRetentionTime:retentionTime];
	[outLibraryEntry autorelease];
	return outLibraryEntry;
}


#pragma mark Encoding

-(void)encodeWithCoder:(NSCoder *)coder
{
    if ( [coder allowsKeyedCoding] ) { // Assuming 10.2 is quite safe!!
        [coder encodeInt:1 forKey:@"version"];
		[coder encodeObject:name forKey:@"name"];
		[coder encodeObject:formula forKey:@"formula"];
        [coder encodeObject:CASNumber forKey:@"CASNumber"];
        [coder encodeObject:source forKey:@"source"];
        [coder encodeObject:comment forKey:@"comment"];
        [coder encodeObject:molString forKey:@"molString"];
        [coder encodeObject:symbol forKey:@"symbol"];
        [coder encodeFloat:massWeight forKey:@"massWeight"];
        [coder encodeFloat:retentionIndex forKey:@"retentionIndex"];
        [coder encodeFloat:retentionTime forKey:@"retentionTime"];
        [coder encodeInt:numberOfPoints forKey:@"numberOfPoints"];
		[coder encodeBytes:(void *)masses length:numberOfPoints*sizeof(float) forKey:@"masses"];
		[coder encodeBytes:(void *)intensities length:numberOfPoints*sizeof(float) forKey:@"intensities"];
    } 
    return;
}

- (id)initWithCoder:(NSCoder *)coder
{
    if ( [coder allowsKeyedCoding] ) {
        // Can decode keys in any order
		name = [[coder decodeObjectForKey:@"name"] retain];
		formula = [[coder decodeObjectForKey:@"formula"] retain];
        CASNumber = [[coder decodeObjectForKey:@"CASNumber"] retain];
        source = [[coder decodeObjectForKey:@"source"] retain];
        comment = [[coder decodeObjectForKey:@"comment"] retain];
        molString = [[coder decodeObjectForKey:@"molString"] retain];
        symbol = [[coder decodeObjectForKey:@"symbol"] retain];
        massWeight = [coder decodeFloatForKey:@"massWeight"];
        retentionIndex = [coder decodeFloatForKey:@"retentionIndex"];
        retentionTime = [coder decodeFloatForKey:@"retentionTime"];
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
    return self;
}

@end
