//
//  FSUser.h
//  FSUser
//
//  Created by Adam Kirk on 8/2/12.
//  Copyright (c) 2012 FamilySearch.org. All rights reserved.
//

@class MTPocketRequest, FSPerson;

typedef NSString * FSUserGender;
#define FSUserGenderMale    @"MALE"
#define FSUserGenderFemail  @"FEMALE"


// @YES or @NO
extern NSString *const FSUserPermissionAccess;
extern NSString *const FSUserPermissionView;
extern NSString *const FSUserPermissionModify;
extern NSString *const FSUserPermissionViewLDSInformation;
extern NSString *const FSUserPermissionModifyLDSInformation;
extern NSString *const FSUserPermissionAccessLDSInterface;
extern NSString *const FSUserPermissionAccessDiscussionForums;




@interface FSAgent : NSObject

@property (readonly)          NSString      *sessionID;
@property (strong, nonatomic) NSString      *identifier;
@property (strong, nonatomic) NSString      *displayName;
@property (strong, nonatomic) NSString      *email;
@property (strong, nonatomic) NSString      *username;
@property (strong, nonatomic) NSDate        *birthDate;
@property (strong, nonatomic) NSString      *country;
@property (strong, nonatomic) NSString      *familyName;
@property (strong, nonatomic) FSUserGender  gender;
@property (strong, nonatomic) NSString      *givenName;
@property (strong, nonatomic) NSNumber      *membershipNumber;
@property (strong, nonatomic) NSString      *preferredLanguage;
@property (strong, nonatomic) NSNumber      *ward;
@property (strong, nonatomic) NSDictionary  *permissions;
@property (readonly, getter=isLoggedIn) BOOL loggedIn;

- (id)initWithUsername:(NSString *)username password:(NSString *)password developerKey:(NSString *)devKey;
- (MTPocketRequest *)login;
+ (FSAgent *)currentUser;            // You have to log in first before this is not nil.
- (MTPocketRequest *)fetch;
- (FSPerson *)treePerson;
- (MTPocketRequest *)logout;
- (BOOL)LDSPermissions;

@end
