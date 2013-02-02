//
//  FSClient.m
//  FamilySearchCocoa
//
//  Created by Adam Kirk on 1/23/13.
//  Copyright (c) 2013 FamilySearch. All rights reserved.
//

#import "private.h"


#define IN_MASK(a, b) ((a & b) == b)









@implementation FSClient

static BOOL __sandboxed = YES;

+ (void)setSandboxed:(BOOL)sandboxed
{
	__sandboxed = sandboxed;
}



+ (MTPocketRequest *)requestToIdentityResource:(NSString *)resource
                                        method:(MTPocketMethod)method
                                          body:(id)body
                                        params:(NSDictionary *)params
{

}

+ (MTPocketRequest *)requestToConclusionResource:(NSString *)resource
                                     identifiers:(NSArray *)identifiers
                                          method:(MTPocketMethod)method
                                            body:(id)body
                                          params:(NSDictionary *)params
{
    NSURL *url = [self urlWithModule:@"platform"
                             version:0
                            resource:resource
                         identifiers:nil
                              params:params];
    return [MTPocketRequest requestForURL:url method:method format:MTPocketFormatJSON body:body];
}


+ (MTPocketRequest *)requestToReservationResource:(NSString *)resource
                                      identifiers:(NSArray *)identifiers
                                           method:(MTPocketMethod)method
                                             body:(id)body
                                           params:(NSDictionary *)params
{
    NSURL *url = [self urlWithModule:@"reservation"
                             version:1
                            resource:resource
                         identifiers:nil
                              params:params];
    return [MTPocketRequest requestForURL:url method:method format:MTPocketFormatJSON body:body];
}

+ (MTPocketRequest *)requestToArtifactResource:(NSString *)resource
                                        method:(MTPocketMethod)method
                                          body:(id)body
                                        params:(NSDictionary *)params
{
    NSURL *url = [self urlWithModule:@"artifactmanager"
                             version:0
                            resource:resource
                         identifiers:nil
                              params:params];
    return [MTPocketRequest requestForURL:url method:method format:MTPocketFormatJSON body:body];
}


+ (NSURL *)urlWithModule:(NSString *)module
				 version:(NSUInteger)version
				resource:(NSString *)resource
			 identifiers:(NSArray *)identifiers
                  params:(NSDictionary *)params
{
	NSMutableString *url = [NSMutableString stringWithFormat:@"https://%@familysearch.org", (__sandboxed ? @"sandbox." : ([module isEqualToString:@"platform"] ? @"" : @"api."))];
	[url appendFormat:@"/%@", module];
	if (version > 0) [url appendFormat:@"/v%u", version];
	[url appendFormat:@"/%@", resource];
	if (identifiers && identifiers.count > 0) [url appendFormat:@"/%@", [identifiers componentsJoinedByString:@","]];
	[url appendString:@"?"];

    NSMutableDictionary *defaultParams = [NSMutableDictionary dictionary];
    if ([FSAgent currentUser].sessionID) defaultParams[@"sessionId"] = [FSAgent currentUser].sessionID;
    defaultParams[@"agent"] = @"akirk-at-familysearch-dot-org/1.0";
    [defaultParams addEntriesFromDictionary:params];
	[url appendString:[self paramsStringFromDictionary:defaultParams]];

	return [NSURL URLWithString:url];
}





#pragma mark - Private


+ (NSString *)paramsStringFromDictionary:(NSDictionary *)dictionary
{
    NSString *paramsString = nil;
    if (dictionary) {
        NSMutableArray *paramsArray = [NSMutableArray array];
        for (NSString *key in [dictionary allKeys]) {
            NSString *value = dictionary[key];
            [paramsArray addObject:[NSString stringWithFormat:@"%@=%@", key, value]];
        }
        paramsString = [paramsArray componentsJoinedByString:@"&"];
    }
    return paramsString;
}


@end
