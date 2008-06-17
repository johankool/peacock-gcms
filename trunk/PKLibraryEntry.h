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

#import "PKSpectrum.h"

@interface PKLibraryEntry : PKSpectrum <PKComparableProtocol, NSCoding> {	
	// Required in JCAMP-DX
	NSString *name;			// ##TITLE=
							// ##JCAMP-DX= (string) 5.00 $$ (Name and version number of the JCAMP-DX program) 
							// ##DATA TYPE= (string) e.g., MASS SPECTRUM 
							// ##DATA CLASS= (string) e.g., PEAK TABLE 
	NSString *origin;		// ##ORIGIN=
	NSString *owner;		// ##OWNER=
	
	// Optional in JCAMP-DX
	NSString *CASNumber;	// ##CAS REGISTRY NO=
	NSString *epaMassSpecNo;// ##$EPA MASS SPEC NO=
	NSString *formula;		// ##MOLFORM=
	NSNumber *massWeight;	// ##MW=
	NSString *nistSource;	// ##$NIST SOURCE=
	NSString *ionizationEnergy; // ##.IONIZATION ENERGY=
	NSString *xUnits;		// ##XUNITS=
	NSString *yUnits;		// ##YUNITS=
	NSNumber *xFactor;		// ##XFACTOR=
	NSNumber *yFactor;		// ##YFACTOR=
	NSNumber *retentionIndex; // ##RI=
	NSString *source;		// ##SOURCE=
	
	// Peacock additions
	NSString *synonyms;		// ##$SYNONYMS=
	NSString *comment;		// ##$COMMENT=
	NSString *molString;	// ##$MOLSTRING=
	NSString *symbol;		// ##$SYMBOL=
//	NSString *model;		// ##$MODEL=
	NSString *group;        // ##$GROUP=
    NSString *library;       // ##$LIBRARY=
	//int numberOfPoints;		// ##NPOINTS=
    NSArray *_synonymsArray;
}

+ (id)libraryEntryWithJCAMPString:(NSString *)inString;
- (id)initWithJCAMPString:(NSString *)inString;
- (NSString *)jcampString;
- (NSNumber *)calculateMassWeight:(NSString *)inString;
- (BOOL)validateCASNumber:(id *)ioValue error:(NSError **)outError;
- (NSUndoManager *)undoManager;

- (BOOL)isCompound:(NSString *)compoundString;
- (NSArray *)synonymsArray;

idAccessor_h(name, setName)
idAccessor_h(origin, setOrigin)
idAccessor_h(owner, setOwner)

idAccessor_h(CASNumber, setCASNumber)
idAccessor_h(epaMassSpecNo, setEpaMassSpecNo)
idAccessor_h(formula, setFormula)
idAccessor_h(massWeight, setMassWeight)
idAccessor_h(nistSource, setNISTSource)
idAccessor_h(ionizationEnergy, setIonizationEnergy)
idAccessor_h(xUnits, setXUnits)
idAccessor_h(yUnits, setYUnits)
idAccessor_h(xFactor, setXFactor)
idAccessor_h(yFactor, setYFactor)
idAccessor_h(retentionIndex, setRetentionIndex)
idAccessor_h(source, setSource)

idAccessor_h(comment, setComment)
idAccessor_h(molString, setMolString)
idAccessor_h(symbol, setSymbol)
idAccessor_h(model, setModel)
idAccessor_h(group, setGroup)
idAccessor_h(synonyms, setSynonyms)
idAccessor_h(library, setLibrary)

- (NSString *)peakTable;
- (void)setPeakTable:(NSString *)inString;

@end
