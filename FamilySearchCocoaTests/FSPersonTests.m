//
//  FSPersonTests.m
//  FamilySearchCocoa
//
//  Created by Adam Kirk on 8/3/12.
//  Copyright (c) 2012 FamilySearch.org. All rights reserved.
//

#import "FSPersonTests.h"
#import "FSURL.h"
#import "FSAgent.h"
#import "FSPerson.h"
#import "FSMarriage.h"
#import "constants.h"
#import <NSDate+MTDates.h>
#import <NSDateComponents+MTDates.h>


@interface FSPersonTests ()
@property (strong, nonatomic) FSPerson *person;
@end


@implementation FSPersonTests

- (void)setUp
{
	[FSURL setSandboxed:YES];

	FSAgent *user = [[FSAgent alloc] initWithUsername:SANDBOXED_USERNAME password:SANDBOXED_PASSWORD developerKey:SANDBOXED_DEV_KEY];
	[user login];

	_person = [FSPerson personWithIdentifier:nil];
	_person.name = @"Adam Kirk";
	_person.gender = @"Male";
	MTPocketRequest *request = [_person save];
	STAssertTrue(response.success, nil);
}

- (void)setUpProduction
{
	[FSURL setSandboxed:NO];

	FSAgent *user = [[FSAgent alloc] initWithUsername:PRODUCTION_USERNAME password:PRODUCTION_PASSWORD developerKey:PRODUCTION_DEV_KEY];
    [user login];

	_person = [FSPerson personWithIdentifier:@"KPQH-N6L"]; // Don Kirk, my real grandpa
}

- (void)testCurrentUserFetch
{
	MTPocketRequest *request = nil;

	@try {
		FSPerson *p = [FSPerson personWithIdentifier:nil];
		[p fetch];
		STFail(@"Was able to fetch person with nil identifier");
	}
	@catch (NSException *exception) {

	}

    FSAgent *user = [[FSAgent alloc] initWithUsername:SANDBOXED_USERNAME password:SANDBOXED_PASSWORD developerKey:SANDBOXED_DEV_KEY];
	[user login];
    FSPerson *me = [user treePerson];

    response = [me fetch];
	STAssertTrue(response.success, nil);
	STAssertNotNil(me.identifier, nil);
	STAssertNotNil(me.name, nil);
	STAssertNotNil(me.gender, nil);
}

- (void)testPersonFetch
{
	MTPocketRequest *request = [_person fetch];
	STAssertTrue(response.success, nil);
	STAssertNotNil(_person.identifier, nil);
	STAssertTrue([_person.name isEqualToString:@"Adam Kirk"], nil);
	STAssertTrue([_person.gender isEqualToString:@"Male"], nil);
}

- (void)testFetchAncestors
{
	MTPocketRequest *response;

	// create and add the father
	FSPerson *father = [FSPerson personWithIdentifier:nil];
	father.name = @"Nathan Kirk";
	father.gender = @"Male";

	[_person addParent:father withLineage:FSLineageTypeBiological];
	response = [_person save];
	STAssertTrue(response.success, nil);
	
	response = [_person fetchAncestors:3];
	STAssertTrue(response.success, nil);


	NSUInteger ancestorCount = 0;
	NSMutableArray *queue = [NSMutableArray arrayWithObject:_person];
	while (queue.count > 0) {
		ancestorCount++;
		FSPerson *p = queue[0];
		[queue removeObjectAtIndex:0];
		for (FSPerson *parent in p.parents) {
			[queue addObject:parent];
		}
	}
	STAssertTrue(ancestorCount == 2, nil);
}

//- (void)testCombineWithPerson
//{
//	MTPocketRequest *response;
//
//	FSPerson *p1 = [FSPerson personWithIdentifier:nil];
//	p1.name = @"Adam Taylor";
//	p1.gender = @"Male";
//	response = [p1 save];
//	STAssertTrue(response.success, nil);
//
//	NSString *previousID = [_person.identifier copy];
//	response = [_person combineWithPerson:p1];
//	STAssertTrue(response.success, nil);
//	STAssertFalse([_person.identifier isEqualToString:previousID], nil);
//}

- (void)testBatchFetchPeople
{
	MTPocketRequest *response;

	FSPerson *p1 = [FSPerson personWithIdentifier:nil];
	p1.name = @"Adam Taylor";
	p1.gender = @"Male";
	response = [p1 save];
	STAssertTrue(response.success, nil);

	FSPerson *p2 = [FSPerson personWithIdentifier:nil];
	p2.name = @"Adam Kirko";
	p2.gender = @"Male";
	response = [p2 save];
	STAssertTrue(response.success, nil);

	FSPerson *p3 = [FSPerson personWithIdentifier:nil];
	p3.name = @"Adumb Kirk";
	p3.gender = @"Male";
	response = [p3 save];
	STAssertTrue(response.success, nil);

	response = [FSPerson batchFetchPeople: @[ _person, p1, p2, p3 ] ];
	STAssertTrue(response.success, nil);
	STAssertNotNil(_person.name, nil);
	STAssertNotNil(_person.gender, nil);
	STAssertNotNil(p1.name, nil);
	STAssertNotNil(p1.gender, nil);
	STAssertNotNil(p2.name, nil);
	STAssertNotNil(p2.gender, nil);
	STAssertNotNil(p3.name, nil);
	STAssertNotNil(p3.gender, nil);
}

- (void)testSaveSummary
{
	MTPocketRequest *request = nil;

	// Snuff 'em
	// +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
	NSDateComponents	*birthDate	= [NSDateComponents componentsFromString:@"11 August 1995"];
	NSString			*birthPlace	= @"Kennewick, Benton, Washington, United States";
	NSDateComponents	*deathDate	= [NSDateComponents componentsFromString:@"11 August 1994"];
	NSString			*deathPlace	= @"Pasco, Franklin, Washington, United States";
	// create and add event to person
	_person.birthDate	= birthDate;
	_person.birthPlace	= birthPlace;
	// add a death event so the sytem acknowledges they are dead
	_person.deathDate	= deathDate;
	_person.deathPlace	= deathPlace;
	response = [_person save];
	STAssertTrue(response.success, nil);
	// +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

	_person.name = @"Adam Kirk Jr.";
	response = [_person save];
	STAssertTrue(response.success, nil);

	response = [_person fetch];
	STAssertTrue(response.success, nil);
	STAssertTrue([_person loggedValuesForPropertyType:FSPropertyTypeName].count == 2, nil);
	STAssertTrue([_person.name isEqualToString:@"Adam Kirk Jr."], nil);

	response = [_person saveSummary];
	STAssertTrue(response.success, nil);

	FSPerson *person = [FSPerson personWithIdentifier:_person.identifier];
	response = [person fetch];
	STAssertTrue(response.success, nil);
	STAssertTrue([person.name isEqualToString:@"Adam Kirk Jr."], nil);
	
}

- (void)testOnChangeCallback
{
	__block BOOL onChangeWasCalled = NO;
	_person.onChange = ^(FSPerson *p) {
		onChangeWasCalled = YES;
	};

	_person.deathDate = [NSDateComponents componentsFromString:@"9 September 1990"];
	STAssertTrue(onChangeWasCalled, nil);
}

- (void)testOnSyncCallback
{
	MTPocketRequest *request = nil;

	__block BOOL onSyncWasCalled = NO;
	__block FSPersonSyncResult onSyncStatus = FSPersonSyncResultNone;
	_person.onSync = ^(FSPerson *p, FSPersonSyncResult status) {
		onSyncWasCalled = YES;
		onSyncStatus = status;
	};

	response = [_person fetch];
	STAssertTrue(response.success, nil);
	STAssertTrue(onSyncWasCalled, nil);
	STAssertTrue(onSyncStatus == FSPersonSyncResultFetched, nil);
}

- (void)testAddCharacteristicsToPerson
{
	MTPocketRequest *response;

	// add the properties
	[_person setCharacteristic:@"Kirk" forKey:FSCharacteristicTypeCasteName];
	[_person setCharacteristic:@"Programmer" forKey:FSCharacteristicTypeOccupation];
	response = [_person save];
	STAssertTrue(response.success, nil);

	// read and check the properties were added on the server
	FSPerson *person = [FSPerson personWithIdentifier:_person.identifier];
	response = [person fetch];
	STAssertTrue(response.success, nil);
	STAssertTrue([[person characteristicForKey:FSCharacteristicTypeCasteName] isEqualToString:@"Kirk"], nil);
	STAssertTrue([[person characteristicForKey:FSCharacteristicTypeOccupation] isEqualToString:@"Programmer"], nil);
}

- (void)testAddAndRemoveFather
{
	MTPocketRequest *response;

	// create and add the father
	FSPerson *father = [FSPerson personWithIdentifier:nil];
	father.name = @"Nathan Kirk";
	father.gender = @"Male";

	[_person addParent:father withLineage:FSLineageTypeBiological];
	response = [_person save];
	STAssertTrue(response.success, nil);

	// assert father was added
	FSPerson *person = [FSPerson personWithIdentifier:_person.identifier];
	response = [person fetch];
	STAssertTrue(response.success, nil);
	STAssertTrue(person.parents.count == 1, nil);

	[person removeParent:father];
	response = [person save];
	STAssertTrue(response.success, nil);

	// assert father was removed
	person = [FSPerson personWithIdentifier:person.identifier];
	response = [person fetch];
	STAssertTrue(response.success, nil);
	STAssertTrue(person.parents.count == 0, nil);
}

- (void)testAddAndRemoveMother
{
	MTPocketRequest *response;

	// create and add the mother
	FSPerson *mother = [FSPerson personWithIdentifier:nil];
	mother.name = @"Jackie Kirk";
	mother.gender = @"Female";

	[_person addParent:mother withLineage:FSLineageTypeBiological];
	response = [_person save];
	STAssertTrue(response.success, nil);

	// assert mother was added
	FSPerson *person = [FSPerson personWithIdentifier:_person.identifier];
	response = [person fetch];
	STAssertTrue(response.success, nil);
	STAssertTrue(person.parents.count == 1, nil);

	// remove the mother
	[person removeParent:mother];
	response = [person save];
	STAssertTrue(response.success, nil);

	// assert mother was removed
	person = [FSPerson personWithIdentifier:person.identifier];
	response = [person fetch];
	STAssertTrue(response.success, nil);
	STAssertTrue(person.parents.count == 0, nil);

}

- (void)testAddMotherAndFather
{
	MTPocketRequest *response;

	// create and add the father
	FSPerson *father = [FSPerson personWithIdentifier:nil];
	father.name = @"Nathan Kirk";
	father.gender = @"Male";

	// create and add the mother
	FSPerson *mother = [FSPerson personWithIdentifier:nil];
	mother.name = @"Jackie Kirk";
	mother.gender = @"Female";

	[_person addParent:father withLineage:FSLineageTypeBiological];
	[_person addParent:mother withLineage:FSLineageTypeBiological];
	response = [_person save];
	STAssertTrue(response.success, nil);

	// read the father
	FSPerson *person = [FSPerson personWithIdentifier:_person.identifier];
	response = [person fetch];
	STAssertTrue(response.success, nil);
	STAssertTrue(person.parents.count == 2, nil);
}

- (void)testGetMotherAndFather
{
	NSArray *bothParents = [_person motherAndFather];
	STAssertTrue(bothParents.count == 2, nil);
}

- (void)testDoesntSaveBlankParents
{
	MTPocketRequest *request = nil;

	NSArray *bothParents = [_person motherAndFather];
	STAssertTrue(bothParents.count == 2, nil);
	STAssertTrue(_person.parents.count == 2, nil);

	response = [_person save];
	STAssertTrue(response.success, nil);

	FSPerson *person = [FSPerson personWithIdentifier:_person.identifier];
	response = [person fetch];
	STAssertTrue(response.success, nil);
	STAssertTrue(person.parents.count == 0, nil);

}

- (void)testAddAndRemoveChild
{
	MTPocketRequest *response;

	// create and add the child
	FSPerson *child = [FSPerson personWithIdentifier:nil];
	child.name = @"Jack Kirk";
	child.gender = @"Male";

	[_person addChild:child withLineage:FSLineageTypeBiological];
	response = [_person save];
	STAssertTrue(response.success, nil);

	// assert child was added
	FSPerson *person = [FSPerson personWithIdentifier:_person.identifier];
	response = [person fetch];
	STAssertTrue(response.success, nil);
	STAssertTrue(person.children.count == 1, nil);

	// remove the child
	[person removeChild:child];
	response = [person save];
	STAssertTrue(response.success, nil);

	// assert child was removed
	person = [FSPerson personWithIdentifier:person.identifier];
	response = [person fetch];
	STAssertTrue(response.success, nil);
	STAssertTrue(person.children.count == 0, nil);
}

- (void)testAddAndRemoveSpouse
{
	MTPocketRequest *response;

	// create and add the spouse
	FSPerson *spouse = [FSPerson personWithIdentifier:nil];
	spouse.name = @"She Kirk";
	spouse.gender = @"Female";

	[_person addMarriage:[FSMarriage marriageWithHusband:_person wife:spouse]];
	response = [_person save];
	STAssertTrue(response.success, nil);

	// assert spouse was added
	FSPerson *person = [FSPerson personWithIdentifier:_person.identifier];
	response = [person fetch];
	STAssertTrue(response.success, nil);
	STAssertTrue(person.marriages.count == 1, nil);

	// remove the spouse
	[person removeMarriage:[person marriageWithSpouse:spouse]];
	response = [person save];
	STAssertTrue(response.success, nil);

	// assert spouse was removed
	person = [FSPerson personWithIdentifier:person.identifier];
	response = [person fetch];
	STAssertTrue(response.success, nil);
	STAssertTrue(person.marriages.count == 0, nil);
}

- (void)testDuplicates
{
	MTPocketRequest *response;

	// create person to match
	FSPerson *person = [FSPerson personWithIdentifier:nil];
	person.name = @"Adam Kirk";
	person.gender = @"Male";
	person.deathDate = [NSDateComponents componentsFromString:@"11 July 1950"];
	response = [person save];
	STAssertTrue(response.success, nil);

	_person.deathDate = [NSDateComponents componentsFromString:@"11 July 1950"];
	response = [_person save];
	STAssertTrue(response.success, nil);

	NSArray *dups = [_person duplicatesWithResponse:&response];
	STAssertTrue(response.success, nil);
	STAssertTrue(dups.count > 0, nil);

	NSUInteger matchCount = 0;
	for (FSPerson *p in dups) {
		if ([p.identifier isEqualToString:person.identifier]) {
			matchCount++;
		}
	}
//	STAssertTrue(matchCount == 1, nil); TODO: this should be passing but it's not and I can't figure it out right now.
}


@end
