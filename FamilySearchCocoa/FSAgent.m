//
//  FSUser.m
//  FSUser
//
//  Created by Adam Kirk on 8/2/12.
//  Copyright (c) 2012 FamilySearch.org. All rights reserved.
//

#import "FSAgent.h"
#import "private.h"





@interface FSAgent ()
@property (strong, nonatomic) NSString *password;
@property (strong, nonatomic) NSString *devKey;
@property (strong, nonatomic) FSPerson *treePerson;
@end







@implementation FSAgent

static FSAgent *__currentUser = nil;

+ (FSAgent *)currentUser
{
    return __currentUser;
}

- (id)initWithUsername:(NSString *)username password:(NSString *)password developerKey:(NSString *)devKey
{
    self = [super init];
    if (self) {
        _username   = username;
        _password   = password;
        _devKey     = devKey;
        _loggedIn   = NO;
    }
    return self;
}

- (MTPocketRequest *)login
{
    _treePerson = nil;
    _sessionID = nil;

    MTPocketRequest *request = [FSClient requestToIdentityResource:@"login" method:MTPocketMethodGET body:nil params:@{@"key" : _devKey}];

    [request addSuccess:^(MTPocketResponse *response) {
        _loggedIn       = YES;
        __currentUser   = self;
        _sessionID      = NILL([response.body valueForKeyPath:@"session.id"]);

    }];

	return request;
}

- (FSPerson *)treePerson
{
    if (!_treePerson) _treePerson = [FSPerson personWithIdentifier:@"me"];
    return _treePerson;
}

- (MTPocketRequest *)fetch
{
    NSString *URLString = [NSString stringWithFormat:@"https://ident.familysearch.org/cis-public-api/v4/user?sessionId=%@", _sessionID];
	NSURL *url = [NSURL URLWithString:URLString];

    MTPocketRequest *request = [MTPocketRequest requestWithURL:<#(NSURL *)#> method:<#(MTPocketMethod)#> body:<#(id)#> requestForURL:url method:MTPocketMethodGET format:MTPocketFormatJSON body:nil];

    [request addSuccess:^(MTPocketRequest *response) {
        NSDictionary *userDict  = [response.body[@"users"] lastObject];
        _displayName            = NILL(userDict[@"displayName"]);
        _email                  = NILL(userDict[@"email"]);
        _identifier             = NILL(userDict[@"id"]);
        _username               = NILL(userDict[@"username"]);
        _birthDate              = NILL(userDict[@"birthDate"]);
        _country                = NILL(userDict[@"country"]);
        _familyName             = NILL(userDict[@"familyName"]);
        _gender                 = NILL(userDict[@"gender"]);
        _givenName              = NILL(userDict[@"givenName"]);
        _membershipNumber       = NILL(userDict[@"membershipNumber"]);
        _preferredLanguage      = NILL(userDict[@"preferredLanguage"]);
        _ward                   = NILL(userDict[@"ward"]);
    }];

    else return request;

    request = [FSClient requestToIdentityResource:@"permission" method:MTPocketMethodGET body:nil params:@{@"product" : @"FamilyTree"}];

    [request addSuccess:^(MTPocketRequest *response) {
        NSArray *permissions = response.body[@"permissions"];
        NSMutableDictionary *permissionsDict = [NSMutableDictionary dictionary];
        permissionsDict[FSUserPermissionAccess]                 = @NO;
        permissionsDict[FSUserPermissionView]                   = @NO;
        permissionsDict[FSUserPermissionModify]                 = @NO;
        permissionsDict[FSUserPermissionViewLDSInformation]     = @NO;
        permissionsDict[FSUserPermissionModifyLDSInformation]   = @NO;
        permissionsDict[FSUserPermissionAccessLDSInterface]     = @NO;
        permissionsDict[FSUserPermissionAccessDiscussionForums] = @NO;
        for (NSDictionary *permission in permissions) {
            permissionsDict[permission[@"value"]] = @YES;
        }
        _permissions = [NSDictionary dictionaryWithDictionary:permissionsDict];
    }];

	return request;
}

- (MTPocketRequest *)logout
{
    MTPocketRequest *request = [[FSClient requestToIdentityResource:@"logout" method:MTPocketMethodGET body:nil params:nil] send];

    if (response.success) {
        _loggedIn           = NO;
        _username           = nil;
        _treePerson         = nil;
        _displayName        = nil;
        _email              = nil;
        _identifier         = nil;
        _username           = nil;
        _birthDate          = nil;
        _country            = nil;
        _familyName         = nil;
        _gender             = nil;
        _givenName          = nil;
        _membershipNumber   = nil;
        _preferredLanguage  = nil;
        _ward               = nil;
        _permissions        = nil;
        _sessionID          = nil;
    }
    return response;
}

- (BOOL)LDSPermissions
{
    static NSArray *ldsPermissions = nil;
    if (!ldsPermissions) {
        ldsPermissions = @[ FSUserPermissionAccessLDSInterface, FSUserPermissionModifyLDSInformation, FSUserPermissionViewLDSInformation ];
    }
    BOOL allTrue = YES;
    for (NSString *permission in ldsPermissions) {
        if (![_permissions[permission] boolValue]) {
            allTrue = NO;
        }
    }
    return allTrue;
}



@end



NSString *const FSUserInfoIDKey                         = @"id";
NSString *const FSUserInfoMembershipIDKey               = @"member.id";
NSString *const FSUserInfoStakeKey                      = @"member.stake";
NSString *const FSUserInfoTempleDistrictKey             = @"member.templeDistrict";
NSString *const FSUserInfoWardKey                       = @"member.ward";
NSString *const FSUserInfoNameKey                       = @"names[first].value";
NSString *const FSUserInfoUsernameKey                   = @"username";

NSString *const FSUserPermissionAccess                  = @"Access";
NSString *const FSUserPermissionView                    = @"View";
NSString *const FSUserPermissionModify                  = @"Modify";
NSString *const FSUserPermissionViewLDSInformation      = @"View LDS Information";
NSString *const FSUserPermissionModifyLDSInformation    = @"Modify LDS Information";
NSString *const FSUserPermissionAccessLDSInterface      = @"Access LDS Interface";
NSString *const FSUserPermissionAccessDiscussionForums  = @"Access Discussion Forums";

