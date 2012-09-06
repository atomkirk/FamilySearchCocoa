//
//  FSSearch.m
//  FamilySearchAPI
//
//  Created by Adam Kirk on 9/6/12.
//  Copyright (c) 2012 FamilySearch. All rights reserved.
//

#import <NSDate+MTDates.h>
#import <NSDictionary+MTJSONDictionary.h>
#import "FSSearch.h"
#import "private.h"





@interface FSSearch ()
@property (strong, nonatomic) NSString *sessionID;
@property (strong, nonatomic) NSMutableArray *criteria;
@end





@interface FSSearchResults ()
- (id)initWithSessionID:(NSString *)sessionID;
@property (strong, nonatomic)	NSMutableArray	*backingStore;
@property (strong, nonatomic)	NSString		*sessionID;
@property (strong, nonatomic)	FSURL			*url;
@property (nonatomic)			NSUInteger		currentIndex;
@property (nonatomic)			NSUInteger		batchSize;
@property (nonatomic)			NSMutableArray	*criteria;
@end





@implementation FSSearch

- (id)initWithSessionID:(NSString *)sessionID
{
    self = [super init];
    if (self) {
		_sessionID		= sessionID;
        _criteria		= [NSMutableArray array];
		_batchSize		= 10;
    }
    return self;
}

- (void)addValue:(id)value forCriteria:(FSSearchCriteria)criteria onRelative:(FSSearchRelativeType)relative matchingExactly:(BOOL)exact
{
	switch (relative) {
		case FSSearchRelativeTypeSelf:
			break;
		case FSSearchRelativeTypeFather:
			criteria = [NSString stringWithFormat:@"father.%@", criteria];
			break;
		case FSSearchRelativeTypeMother:
			criteria = [NSString stringWithFormat:@"mother.%@", criteria];
			break;
		case FSSearchRelativeTypeSpouse:
			criteria = [NSString stringWithFormat:@"spouse.%@", criteria];
			break;
		default:
			break;
	}
	if (exact && ![criteria isEqualToString:FSSearchCriteriaGender]) criteria = [NSString stringWithFormat:@"%@.exact", criteria];
	[_criteria addObject: @{ @"Criteria" : criteria, @"Value" : value } ];
}

- (FSSearchResults *)results
{
	FSSearchResults *results = [[FSSearchResults alloc] initWithSessionID:_sessionID];
	results.batchSize = _batchSize;
	results.criteria = _criteria;
	return results;
}

@end










@implementation FSSearchResults

- (id)initWithSessionID:(NSString *)sessionID
{
    self = [super init];
    if (self) {
		_backingStore	= [NSMutableArray array];
		_sessionID		= sessionID;
        _currentIndex	= 0;
		_url			= [[FSURL alloc] initWithSessionID:_sessionID];
    }
    return self;
}

- (MTPocketResponse *)next
{
	NSMutableArray *params = [NSMutableArray array];
	[params addObject:[NSString stringWithFormat:@"maxResults=%d", _batchSize]];
	[params addObject:[NSString stringWithFormat:@"startIndex=%d", _currentIndex]];
	for (NSDictionary *criteriaDictionary in _criteria) {
		NSString	*criteriaKey	= [criteriaDictionary objectForKey:@"Criteria"];
		id			value			= [criteriaDictionary objectForKey:@"Value"];

		NSString *formattedValue = (NSString *)value;
		if ([value isKindOfClass:[NSDate class]]) {
			formattedValue = [(NSDate *)value stringFromDateWithFormat:DATE_FORMAT];
		}
		[params addObject:[NSString stringWithFormat:@"%@=%@", criteriaKey, formattedValue]];
	}


	NSURL *url = [_url urlWithModule:@"familytree"
							 version:2
							resource:@"search"
						 identifiers:nil
							  params:0
								misc:[params componentsJoinedByString:@"&"]];

	MTPocketResponse *response = [MTPocketRequest objectAtURL:url method:MTPocketMethodGET format:MTPocketFormatJSON body:nil];

	if (response.success) {
		[self removeAllObjects];
		NSArray *searches = [response.body valueForComplexKeyPath:@"searches[first].search"];
		for (NSDictionary *search in searches) {
			NSDictionary *personDictionary = [search objectForKey:@"person"];
			FSPerson *person = [FSPerson personWithSessionID:_sessionID identifier:[personDictionary objectForKey:@"id"]];
			[person populateFromPersonDictionary:personDictionary];

			// Add parents
			NSArray *parents = [personDictionary objectForKey:@"parent"];
			for (NSDictionary *parentDictionary in parents) {
				FSPerson *parent = [FSPerson personWithSessionID:_sessionID identifier:[parentDictionary objectForKey:@"id"]];
				[parent populateFromPersonDictionary:parentDictionary];
				[person addParent:parent withLineage:FSLineageTypeBiological];
			}

			// Add children
			NSArray *children = [personDictionary objectForKey:@"child"];
			for (NSDictionary *childDictionary in children) {
				FSPerson *child = [FSPerson personWithSessionID:_sessionID identifier:[childDictionary objectForKey:@"id"]];
				[child populateFromPersonDictionary:childDictionary];
				[person addChild:child withLineage:FSLineageTypeBiological];
			}

			// Add spouses
			NSArray *spouses = [personDictionary objectForKey:@"spouse"];
			for (NSDictionary *spouseDictionary in spouses) {
				FSPerson *spouse = [FSPerson personWithSessionID:_sessionID identifier:[spouseDictionary objectForKey:@"id"]];
				[spouse populateFromPersonDictionary:spouseDictionary];
				[person addSpouse:spouse];
			}

			[self addObject:person];
		}
	}
	
	_currentIndex += _batchSize;
	return response;
}


#pragma mark NSArray

-(NSUInteger)count
{
    return [_backingStore count];
}

-(id)objectAtIndex:(NSUInteger)index
{
    return [_backingStore objectAtIndex:index];
}

#pragma mark NSMutableArray

-(void)insertObject:(id)anObject atIndex:(NSUInteger)index
{
    [_backingStore insertObject:anObject atIndex:index];
}

-(void)removeObjectAtIndex:(NSUInteger)index
{
    [_backingStore removeObjectAtIndex:index];
}

-(void)addObject:(id)anObject
{
    [_backingStore addObject:anObject];
}

-(void)removeLastObject
{
    [_backingStore removeLastObject];
}

-(void)replaceObjectAtIndex:(NSUInteger)index withObject:(id)anObject
{
    [_backingStore replaceObjectAtIndex:index withObject:anObject];
}

@end