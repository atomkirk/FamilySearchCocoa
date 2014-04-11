//
//  FSSearchTests.m
//  FamilySearchCocoa
//
//  Created by Adam Kirk on 9/6/12.
//  Copyright (c) 2012 FamilySearch. All rights reserved.
//

#import "FSSearchTests.h"
#import "private.h"
#import "FSSearch.h"
#import "constants.h"
#import <objc/runtime.h> // TEMPORARY


@interface FSSearchTests ()
@property (strong, nonatomic) FSPerson *person;
@end


@implementation FSSearchTests

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

- (void)testSearch
{
	MTPocketResponse *response;

	FSSearch *search = [[FSSearch alloc] init];
	[search addValue:@"Nathan" forCriteria:FSSearchCriteriaName onRelative:FSSearchRelativeTypeSelf matchingExactly:NO];
	FSSearchResults *results = [search results];

	response = [results next];
	STAssertTrue(response.success, nil);
	STAssertTrue(results.count == 10 || results.count == results.numberOfResults % 10, nil);
	FSPerson *lastPerson = [results lastObject];
	STAssertNotNil(lastPerson.name, nil);

	response = [results next];
	STAssertTrue(response.success, nil);
	STAssertTrue(results.count == 10 || results.count == results.numberOfResults % 10, nil);
	FSPerson *lastPerson2 = [results lastObject];
	STAssertNotNil(lastPerson2.name, nil);
}



@end
