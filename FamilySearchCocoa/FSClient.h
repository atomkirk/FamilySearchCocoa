//
//  FSClient.h
//  FamilySearchCocoa
//
//  Created by Adam Kirk on 1/23/13.
//  Copyright (c) 2013 FamilySearch. All rights reserved.
//

//// Media Types
//typedef NSString * FSMediaType;
//#define FSMediaTypeXML          @"application/x-fs-v1+xml"
//#define FSMediaTypeJSON         @"application/x-fs-v1+json"



@interface FSClient : NSObject

+ (void)setSandboxed:(BOOL)sandboxed;

+ (MTPocketRequest *)requestToIdentityResource:(NSString *)resource                                         method:(MTPocketMethod)method   body:(id)body   params:(NSDictionary *)params;
+ (MTPocketRequest *)requestToConclusionResource:(NSString *)resource   identifiers:(NSArray *)identifiers  method:(MTPocketMethod)method   body:(id)body   params:(NSDictionary *)params;
+ (MTPocketRequest *)requestToReservationResource:(NSString *)resource  identifiers:(NSArray *)identifiers  method:(MTPocketMethod)method   body:(id)body   params:(NSDictionary *)params;
+ (MTPocketRequest *)requestToArtifactResource:(NSString *)resource                                         method:(MTPocketMethod)method   body:(id)body   params:(NSDictionary *)params;

@end
