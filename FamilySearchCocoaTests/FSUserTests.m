//
//  FSUserTests.m
//  FamilySearchCocoa
//
//  Created by Adam Kirk on 8/2/12.
//  Copyright (c) 2012 FamilySearch.org. All rights reserved.
//

#import "FSUserTests.h"
#import "FSUser.h"
#import "FSPerson.h"
#import "FSURL.h"
#import "constants.h"


@implementation FSUserTests

- (void)testGetSessionID
{
	[FSURL setSandboxed:YES];
	
	FSUser *user = [[FSUser alloc] initWithUsername:SANDBOXED_USERNAME password:SANDBOXED_PASSWORD developerKey:SANDBOXED_DEV_KEY];
	MTPocketResponse *response = [user login];

	STAssertNotNil(response.body, @"sessionID was nil");
}

- (void)testLogout
{
	FSUser *user = [[FSUser alloc] initWithUsername:SANDBOXED_USERNAME password:SANDBOXED_PASSWORD developerKey:SANDBOXED_DEV_KEY];
	MTPocketResponse *response = [user login];
    STAssertTrue(response.success, nil);

    response = [user logout];
	STAssertTrue(response.success, nil);
}

- (void)testFetch
{
    FSUser *user = [[FSUser alloc] initWithUsername:SANDBOXED_USERNAME password:SANDBOXED_PASSWORD developerKey:SANDBOXED_DEV_KEY];
    MTPocketResponse *response = [user login];
    STAssertTrue(response.success, nil);

    response = [user fetch];

    STAssertTrue(response.success, nil);
    STAssertNotNil(user.displayName, nil);
    STAssertNotNil(user.email, nil);
    STAssertNotNil(user.identifier, nil);
    STAssertNotNil(user.username, nil);
    STAssertNotNil(user.birthDate, nil);
    STAssertNotNil(user.country, nil);
    STAssertNotNil(user.familyName, nil);
    STAssertNotNil(user.gender, nil);
    STAssertNotNil(user.givenName, nil);
    STAssertNotNil(user.membershipNumber, nil);
    STAssertNotNil(user.preferredLanguage, nil);
    STAssertNotNil(user.ward, nil);

    STAssertTrue([user.permissions[FSUserPermissionAccess] boolValue], nil);
    STAssertTrue([user.permissions[FSUserPermissionView] boolValue], nil);
    STAssertTrue([user.permissions[FSUserPermissionModify] boolValue], nil);
    STAssertTrue([user.permissions[FSUserPermissionViewLDSInformation] boolValue], nil);
    STAssertTrue([user.permissions[FSUserPermissionModifyLDSInformation] boolValue], nil);
    STAssertTrue([user.permissions[FSUserPermissionAccessLDSInterface] boolValue], nil);
    STAssertTrue([user.permissions[FSUserPermissionAccessDiscussionForums] boolValue], nil);
}

@end
