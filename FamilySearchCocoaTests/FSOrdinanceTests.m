//
//  FSOrdinanceTests.m
//  FamilySearchCocoa
//
//  Created by Adam Kirk on 9/10/12.
//  Copyright (c) 2012 FamilySearch. All rights reserved.
//

#import "FSOrdinanceTests.h"
#import <NSDate+MTDates.h>
#import <NSDateComponents+MTDates.h>
#import "FSURL.h"
#import "FSAgent.h"
#import "FSPerson.h"
#import "FSEvent.h"
#import "FSMarriage.h"
#import "constants.h"


@interface FSOrdinanceTests ()
@property (strong, nonatomic) FSPerson *person;
@end


@implementation FSOrdinanceTests


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

- (void)tearDown
{
    MTPocketRequest *request = nil;
    NSArray *people = [FSOrdinance peopleReservedByCurrentUserWithResponse:&response];
	STAssertTrue(response.success, nil);

    if (people && people.count > 0) {
        response = [FSOrdinance unreserveOrdinances:[FSOrdinance ordinanceTypes] forPeople:people];
        STAssertTrue(response.success, nil);
    }
}

- (void)testFetchGetsOrdinances
{
	MTPocketRequest *request = nil;

	FSPerson *father = [FSPerson personWithIdentifier:nil];
	father.name = @"Nathan Kirk";
	father.gender = @"Male";
	father.deathDate = [NSDateComponents componentsFromString:@"11 November 1970"];

	STAssertTrue(_person.ordinances.count == 0, nil);

	[father addUnofficialOrdinanceWithType:FSOrdinanceTypeEndowment date:[NSDate dateFromYear:1998 month:2 day:3] templeCode:@"SLAKE"];

	[_person addParent:father withLineage:FSLineageTypeBiological];
	response = [_person save];
	STAssertTrue(response.success, nil);

	response = [father fetch];
	STAssertTrue(response.success, nil);
	STAssertTrue(father.ordinances.count == 1, nil);
}

- (void)testFetchingAllOrdinances
{
	MTPocketRequest *request = nil;

	FSPerson *father = [FSPerson personWithIdentifier:nil];
	father.name			= @"Nathan Kirk";
	father.gender		= @"Male";
	father.deathDate	= [NSDateComponents componentsFromString:@"11 November 1970"];
	father.deathPlace	= @"Pasco, Franklin, Washington, United States";
	[_person addParent:father withLineage:FSLineageTypeBiological];
	response = [_person save];
	STAssertTrue(response.success, nil);

	response = [father fetch];
	STAssertTrue(response.success, nil);

	NSUInteger startOrdinances = father.ordinances.count;

	response = [FSOrdinance fetchOrdinancesForPeople:@[father]];
	STAssertTrue(response.success, nil);
	STAssertTrue(father.ordinances.count == startOrdinances + 4, nil);
}

- (void)testReserveAndUnreserveOrdinances
{
	MTPocketRequest *request = nil;

	FSPerson *father    = [FSPerson personWithIdentifier:nil];
	father.name			= @"Nathan Kirk";
	father.gender		= @"Male";
	father.deathDate	= [NSDateComponents componentsFromString:@"11 November 1970"];
	father.deathPlace	= @"Pasco, Franklin, Washington, United States";
	[_person addParent:father withLineage:FSLineageTypeBiological];
	response = [_person save];
	STAssertTrue(response.success, nil);

	FSPerson *gFather	= [FSPerson personWithIdentifier:nil];
	gFather.name		= @"Nathan Kirk";
	gFather.gender		= @"Male";
	gFather.deathDate	= [NSDateComponents componentsFromString:@"11 November 1910"];
	gFather.deathPlace	= @"Pasco, Franklin, Washington, United States";
	[father addParent:gFather withLineage:FSLineageTypeBiological];
	response = [father save];
	STAssertTrue(response.success, nil);

	FSPerson *spouse = [FSPerson personWithIdentifier:nil];
	spouse.name = @"She Kirk";
	spouse.gender = @"Female";
	spouse.deathDate	= [NSDateComponents componentsFromString:@"11 November 1909"];
	spouse.deathPlace	= @"Pasco, Franklin, Washington, United States";
	[father addMarriage:[FSMarriage marriageWithHusband:father wife:spouse]];
	response = [father save];
	STAssertTrue(response.success, nil);

	response = [father fetch];
	STAssertTrue(response.success, nil);

	response = [FSOrdinance fetchOrdinancesForPeople:@[father]];
	STAssertTrue(response.success, nil);

	response = [FSOrdinance reserveOrdinances:[FSOrdinance ordinanceTypes] forPeople:@[ father ] inventory:FSOrdinanceInventoryTypePersonal];
	STAssertTrue(response.success, nil);

	response = [FSOrdinance fetchOrdinancesForPeople:@[father]];
	STAssertTrue(response.success, nil);

	NSMutableArray *reservedOrdinances = [NSMutableArray array];
	for (FSOrdinance *ordinance in father.ordinances) {
		if ([ordinance.status isEqualToString:FSOrdinanceStatusReserved]) [reservedOrdinances addObject:ordinance];
	}
	STAssertTrue(reservedOrdinances.count > 0, nil);

	response = [FSOrdinance unreserveOrdinances:[FSOrdinance ordinanceTypes] forPeople: @[ father ] ];
	STAssertTrue(response.success, nil);

	response = [FSOrdinance fetchOrdinancesForPeople: @[ father ] ];
	STAssertTrue(response.success, nil);

	reservedOrdinances = [NSMutableArray array];
	for (FSOrdinance *ordinance in father.ordinances) {
		if ([ordinance.status isEqualToString:FSOrdinanceStatusReserved]) [reservedOrdinances addObject:ordinance];
	}
	STAssertTrue(reservedOrdinances.count == 0, nil);
}

- (void)testFetchListOfReservedPeopleByCurrentUser
{
	MTPocketRequest *request = nil;

    FSPerson *father    = [FSPerson personWithIdentifier:nil];
	father.name			= @"Nathan Kirk";
	father.gender		= @"Male";
	father.deathDate	= [NSDateComponents componentsFromString:@"11 November 1970"];
	father.deathPlace	= @"Pasco, Franklin, Washington, United States";
	[_person addParent:father withLineage:FSLineageTypeBiological];
	response = [_person save];
	STAssertTrue(response.success, nil);

	response = [FSOrdinance reserveOrdinances:@[FSOrdinanceTypeBaptism] forPeople:@[ father ] inventory:FSOrdinanceInventoryTypePersonal];
	STAssertTrue(response.success, nil);

    NSArray *people = [FSOrdinance peopleReservedByCurrentUserWithResponse:&response];
	STAssertTrue(response.success, nil);
	STAssertNotNil(people, nil);
	STAssertTrue(people.count > 0, nil);

	response = [FSOrdinance fetchOrdinancesForPeople:people];
	STAssertTrue(response.success, nil);

	FSPerson *anyPerson = [people lastObject];
	STAssertTrue(anyPerson.ordinances > 0, nil);
}

- (void)testFetchFamilyOrdinanceRequestPDFURL
{
	MTPocketRequest *request = nil;

    FSPerson *father    = [FSPerson personWithIdentifier:nil];
	father.name			= @"Nathan Kirk";
	father.gender		= @"Male";
	father.deathDate	= [NSDateComponents componentsFromString:@"11 November 1970"];
	father.deathPlace	= @"Pasco, Franklin, Washington, United States";
	[_person addParent:father withLineage:FSLineageTypeBiological];
	response = [_person save];
	STAssertTrue(response.success, nil);

	response = [FSOrdinance reserveOrdinances:[FSOrdinance ordinanceTypes] forPeople:@[ father ] inventory:FSOrdinanceInventoryTypePersonal];
	STAssertTrue(response.success, nil);

    NSArray *people = [FSOrdinance peopleReservedByCurrentUserWithResponse:&response];
	STAssertTrue(response.success, nil);

	NSURL *url = [FSOrdinance familyOrdinanceRequestPDFURLForPeople:people response:&response];

	STAssertTrue(response.success, nil);
	STAssertNotNil(url, nil);
}


@end




