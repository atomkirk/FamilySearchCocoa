//
//  FSOrdinance.m
//  FamilySearchCocoa
//
//  Created by Adam Kirk on 8/21/12.
//  Copyright (c) 2012 FamilySearch. All rights reserved.
//

#import "FSOrdinance.h"
#import "private.h"
#import <NSObject+MTJSONUtils.h>
#import <NSDate+MTDates.h>
#import <NSDateComponents+MTDates.h>




@implementation FSOrdinance


- (id)initWithType:(FSOrdinanceType)type
{
    self = [super init];
    if (self) {
		_identifier		= nil;
		_type			= type;
		_status			= FSOrdinanceStatusNotSet;
		_date			= nil;
		_templeCode		= nil;
		_inventory		= FSOrdinanceInventoryTypePersonal;
		_official		= NO;
		_completed		= NO;
		_reservable		= NO;
		_notes			= nil;
		_prerequisites	= [NSMutableArray array];
		_people			= [NSMutableSet set];

		_userAdded	= NO;
    }
    return self;
}

+ (FSOrdinance *)ordinanceWithType:(FSOrdinanceType)type
{
	return [[FSOrdinance alloc] initWithType:type];
}




#pragma mark - Getting Ordinances

+ (MTPocketRequest *)fetchOrdinancesForPeople:(NSArray *)people
{
	if (people.count == 0) return nil;

	NSMutableArray *identifiers = [NSMutableArray array];
	for (FSPerson *person in people) {
		if (person.identifier) [identifiers addObject:person.identifier];
	}

    MTPocketRequest *request = [[FSClient requestToReservationResource:@"person" identifiers:identifiers method:MTPocketMethodGET body:nil params:nil] send];

	if (response.success) {

		NSArray *peopleDictionaries = NILL([response.body valueForKeyPath:@"persons.person"]);
		for (NSDictionary *personDictionary in peopleDictionaries) {
			
			FSPerson *person = [FSPerson personWithIdentifier:personDictionary[@"ref"]];

			NSString *notes = NILL([personDictionary valueForComplexKeyPath:@"userNotifications.userNotification[first].message"]);

			for (NSString *ordinanceType in [FSOrdinance ordinanceTypes]) {
				NSString *reservationType = [FSOrdinance reservationTypeFromOrdinanceType:ordinanceType];
				NSArray *ordinanceDictionaries = [personDictionary valueForComplexKeyPath:reservationType];
				if (!ordinanceDictionaries) continue;
				if (![ordinanceDictionaries isKindOfClass:[NSArray class]]) ordinanceDictionaries = @[ ordinanceDictionaries ];

				for (NSDictionary *ordinanceDictionary in ordinanceDictionaries) {
					FSOrdinance *ordinance = [FSOrdinance ordinanceWithType:ordinanceType];

					[ordinance setOfficial:YES];

					// COMPLETED
					NSNumber *completedString = ordinanceDictionary[@"completed"];
					if (completedString) [ordinance setCompleted:[completedString boolValue]];

					// RESERVABLE
					NSNumber *reservableString = ordinanceDictionary[@"reservable"];
					if (reservableString) [ordinance setReservable:[reservableString boolValue]];

					// STATUS
					NSString *statusString = ordinanceDictionary[@"status"];
					if (statusString) [ordinance setStatus:statusString];

					// NOTES
					if (notes) [ordinance setNotes:notes];

					// DATE
					NSString *dateString = NILL([ordinanceDictionary valueForKeyPath:@"date.normalized"]);
					if (dateString) [ordinance setDate:[NSDate dateFromString:dateString usingFormat:DATE_FORMAT]];

					// TEMPLE
					NSString *templeCodeString = NILL([ordinanceDictionary valueForKeyPath:@"temple.code"]);
					if (templeCodeString) [ordinance setTempleCode:templeCodeString];

					// BORN IN THE COVENANT
					NSNumber *bornInCovenantString = ordinanceDictionary[@"bornInCovenant"];
					if (bornInCovenantString) [ordinance setBornInTheCovenant:[bornInCovenantString boolValue]];

					// PREREQS
					NSArray *preReqPeople = NILL([ordinanceDictionary valueForKeyPath:@"prerequisitesForTrip"]);
					for (NSDictionary *preReqPersonDictionary in preReqPeople) {
						FSPerson *preReqPerson = [FSPerson personWithIdentifier:preReqPersonDictionary[@"ref"]];
						for (NSString *ordName in [FSOrdinance ordinanceTypes]) {
							NSString *reservationType = [FSOrdinance reservationTypeFromOrdinanceType:ordName];
							NSArray *preReqOrdinanceDictionaries = [preReqPersonDictionary valueForComplexKeyPath:reservationType];
							if (preReqOrdinanceDictionaries) {
								if (![preReqOrdinanceDictionaries isKindOfClass:[NSArray class]]) preReqOrdinanceDictionaries = @[ preReqOrdinanceDictionaries ];
								for (NSDictionary *preReqOrdinanceDictionary in preReqOrdinanceDictionaries) {
									FSOrdinance *preReqOrdinance = [FSOrdinance ordinanceWithType:ordName];
									[preReqOrdinance addPerson:preReqPerson];
									[ordinance addPrerequisite:preReqOrdinance];
								}
							}
						}
					}

					// PARENTS
					NSArray *parents = NILL([ordinanceDictionary valueForKeyPath:@"parent"]);
					for (NSDictionary *parent in parents) {
						FSPerson *p = [FSPerson personWithIdentifier:parent[@"ref"]];
						p.name = NILL([parent valueForKeyPath:@"qualification.name.fullText"]);
						[p addOrReplaceOrdinance:ordinance];
					}

					// SPOUSES
					NSArray *spouses = NILL([ordinanceDictionary valueForKeyPath:@"spouses"]);
					for (NSDictionary *spouse in spouses) {
						FSPerson *p = [FSPerson personWithIdentifier:spouse[@"ref"]];
						p.name = NILL([spouse valueForKeyPath:@"qualification.name.fullText"]);
						[p addOrReplaceOrdinance:ordinance];
					}
					
					[person addOrReplaceOrdinance:ordinance];
				}
			}

			person.onSync(person, FSPersonSyncResultFetched);
		}
	}

	return response;
}

+ (NSArray *)peopleReservedByCurrentUserWithResponse:(MTPocketRequest **)response
{
    MTPocketRequest *resp = [[FSClient requestToReservationResource:@"person" identifiers:nil method:MTPocketMethodGET body:nil params:nil] send];

    NSMutableArray *people = [NSMutableArray array];
	if (resp.success) {
		NSArray *persons = NILL([resp.body valueForKeyPath:@"persons.person"]);
		for (NSDictionary *personDictionary in persons) {
			NSString *identifier = NILL([personDictionary valueForKeyPath:@"ref"]);
			FSPerson *person = [FSPerson personWithIdentifier:identifier];
			[people addObject:person];
		}
	}

    *request = resp;

    return people;
}




#pragma mark - Reserving

+ (MTPocketRequest *)reserveOrdinances:(NSArray *)ordinances forPeople:(NSArray *)people inventory:(FSOrdinanceInventoryType)inventory
{
	if (people.count == 0) raiseParamException(@"people");

	// For each person, reserve the ordinances
	NSMutableArray *personDictionaries = [NSMutableArray array];
	for (FSPerson *person in people) {
		NSMutableDictionary *personDictionary = [NSMutableDictionary dictionary];
		personDictionary[@"ref"] = person.identifier;
		for (FSOrdinanceType type in ordinances) {

			// SEALING TO PARENTS
			if ([type isEqualToString:FSOrdinanceTypeSealingToParents]) {

				NSMutableArray *couples = [NSMutableArray array];

				for (FSPerson *parent in person.parents) {
					BOOL foundSpouse = NO;
					for (FSMarriage *marriage in parent.marriages) {
						FSPerson *spouse = parent.isMale ? marriage.wife : marriage.husband;
						if (foundSpouse) break;
						for (FSPerson *otherParent in person.parents) {
							if ([spouse isSamePerson:otherParent]) {
								foundSpouse = YES;
								[couples addObject:@[ @{ @"role" : (parent.isMale ? @"Father" : @"Mother"), @"ref" : parent.identifier}, @{ @"role" : (spouse.isMale ? @"Father" : @"Mother"), @"ref" : spouse.identifier} ]];
								break;
							}
						}
					}
				}

				// if no information about either parent, don't reserve this ordinance
				if (couples.count < 2) continue;

				NSMutableArray *sealingsToParents = [NSMutableArray array];
				for (NSArray *couple in couples) {
					NSDictionary *ordinanceDictionary = @{
										@"reservation" : @{
											@"inventory" : @{
												@"type" : (inventory == FSOrdinanceInventoryTypeChurch ? @"Church" : @"Personal" )
											}
										},
										@"parent" : couple
									};
					[sealingsToParents addObject:ordinanceDictionary];
					FSOrdinance *ordinance = [FSOrdinance ordinanceWithType:type];
					ordinance.inventory = inventory;
					[ordinance addPerson:couple[0]];
					[ordinance addPerson:couple[1]];
					[person addOrReplaceOrdinance:ordinance];
				}
				personDictionary[@"sealingToParents"] = sealingsToParents;
			}

			
			// SEALING TO SPOUSE
			else if ([type isEqualToString:FSOrdinanceTypeSealingToSpouse]) {
				if (person.marriages.count == 0) continue;
				NSMutableArray *sealingsToSpouse = [NSMutableArray array];
				for (FSMarriage *marriage in person.marriages) {
					FSPerson *spouse = person.isMale ? marriage.wife : marriage.husband;
					NSDictionary *ordinanceDictionary = @{
										@"reservation" : @{
											@"inventory" : @{
												@"type" : (inventory == FSOrdinanceInventoryTypeChurch ? @"Church" : @"Personal" )
											}
										},
										@"spouse" : @{ @"ref" : spouse.identifier }
									};
					[sealingsToSpouse addObject:ordinanceDictionary];
					FSOrdinance *ordinance = [FSOrdinance ordinanceWithType:type];
					ordinance.inventory = inventory;
					[ordinance addPerson:spouse];
					[person addOrReplaceOrdinance:ordinance];
				}
				personDictionary[@"sealingToSpouse"] = sealingsToSpouse;
			}

			
			// PERSONAL ORDINANCE
			else {
				NSDictionary *ordinanceDictionary = @{
														@"reservation" : @{
															@"inventory" : @{
																@"type" : (inventory == FSOrdinanceInventoryTypeChurch ? @"Church" : @"Personal" )
															}
														}
													};
				personDictionary[[FSOrdinance reservationTypeFromOrdinanceType:type]] = ordinanceDictionary;
				FSOrdinance *ordinance = [FSOrdinance ordinanceWithType:type];
				ordinance.inventory = inventory;
				[person addOrReplaceOrdinance:ordinance];
			}
		}
		[personDictionaries addObject:personDictionary];
		person.onSync(person, FSPersonSyncResultUpdated);
	}
	
	NSDictionary *body = @{ @"persons" : @{ @"person" : personDictionaries } };

    MTPocketRequest *request = [[FSClient requestToReservationResource:@"person" identifiers:nil method:MTPocketMethodPOST body:body params:nil] send];

	return response;
}

+ (MTPocketRequest *)unreserveOrdinances:(NSArray *)ordinances forPeople:(NSArray *)people
{
	if (people.count == 0) raiseParamException(@"people");

	// For each person, reserve the ordinances
	NSMutableArray *personDictionaries = [NSMutableArray array];
	for (FSPerson *person in people) {
		NSMutableDictionary *personDictionary = [NSMutableDictionary dictionary];
		personDictionary[@"ref"] = person.identifier;
		personDictionary[@"action"] = @"unreserve";
		[personDictionaries addObject:personDictionary];
	}
	
	NSDictionary *body = @{ @"persons" : @{ @"person" : personDictionaries } };

    MTPocketRequest *request = [[FSClient requestToReservationResource:@"person" identifiers:nil method:MTPocketMethodPOST body:body params:@{@"owner" : @"me"}] send];

	return response;
}




#pragma mark - Printing Ordinance Requests

+ (NSURL *)familyOrdinanceRequestPDFURLForPeople:(NSArray *)people response:(MTPocketRequest **)response
{
	if (people.count == 0) raiseParamException(@"people");

    NSURL *PDFURL = nil;

    MTPocketRequest *resp = *request = [FSOrdinance fetchOrdinancesForPeople:people];

	if (resp.success) {

		NSMutableArray *personDictionaries = [NSMutableArray array];
		for (FSPerson *person in people) {
			NSMutableDictionary *personDictionary = [NSMutableDictionary dictionary];
			personDictionary[@"ref"] = person.identifier;
			for (FSOrdinance *ordinance in person.ordinances) {
                if (![ordinance.status isEqualToString:FSOrdinanceStatusReserved] && ![ordinance.status isEqualToString:FSOrdinanceStatusInProgress]) continue;

				if ([ordinance.type isEqualToString:FSOrdinanceTypeSealingToParents]) {
					NSMutableArray *parentDictionaries = [NSMutableArray array];
					for (FSPerson *participant in ordinance.people) {
						if ([participant isSamePerson:person]) continue;
						[parentDictionaries addObject: @{ @"role" : (participant.isMale ? @"Father" : @"Mother"), @"ref" : participant.identifier } ];
					}
					NSMutableArray *sealings = personDictionary[[FSOrdinance reservationTypeFromOrdinanceType:ordinance.type]];
					if (!sealings) {
						sealings = [NSMutableArray array];
						personDictionary[[FSOrdinance reservationTypeFromOrdinanceType:ordinance.type]] = sealings;
					}
					if (parentDictionaries.count > 0) [sealings addObject: @{ @"parent" : parentDictionaries } ];
				}

				else if ([ordinance.type isEqualToString:FSOrdinanceTypeSealingToSpouse]) {
					NSDictionary *spouseDictionary = nil;
					for (FSPerson *participant in ordinance.people) {
						if ([participant isSamePerson:person]) continue;
						spouseDictionary = @{ @"ref" : participant.identifier };
					}
					NSMutableArray *sealings = personDictionary[[FSOrdinance reservationTypeFromOrdinanceType:ordinance.type]];
					if (!sealings) {
						sealings = [NSMutableArray array];
						personDictionary[[FSOrdinance reservationTypeFromOrdinanceType:ordinance.type]] = sealings;
					}
					if (spouseDictionary) [sealings addObject: @{ @"spouse" : spouseDictionary } ];
				}

				else {
					personDictionary[[FSOrdinance reservationTypeFromOrdinanceType:ordinance.type]] = @{};
				}
			}
			[personDictionaries addObject:personDictionary];
		}

		NSDictionary *body = @{
								@"trips" : @{
									@"trip" : @[@{
										@"persons" : @{
											@"person" : personDictionaries
										}
									}]
								}
							};

        resp = *request = [[FSClient requestToReservationResource:@"trip" identifiers:nil method:MTPocketMethodPOST body:body params:nil] send];

		if (resp.success) {
			NSString *identifier = NILL([resp.body valueForComplexKeyPath:@"trips.trip[first].id"]);
			PDFURL = [FSClient urlWithModule:@"reservation"
                                  version:1
                                 resource:[NSString stringWithFormat:@"trip/%@/pdf", identifier]
                              identifiers:nil
                                   params:0
                                     misc:nil];
		}
	}
	
	return PDFURL;
}

+ (NSURL *)urlOfChurchPoliciesResponse:(MTPocketRequest **)response
{
	return nil; // TODO
}




#pragma mark - Keys

+ (NSArray *)ordinanceTypes
{
	static NSArray *types = nil;
	if (!types) {
		types = @[
			FSOrdinanceTypeBaptism,
			FSOrdinanceTypeConfirmation,
			FSOrdinanceTypeInitiatory,
			FSOrdinanceTypeEndowment,
			FSOrdinanceTypeSealingToParents,
			FSOrdinanceTypeSealingToSpouse
		];
	}
	return types;
}

+ (NSArray *)ordinanceStatuses
{
	static NSArray *statuses = nil;
	if (!statuses) {
		statuses = @[
			FSOrdinanceStatusCompleted,
			FSOrdinanceStatusReady,
			FSOrdinanceStatusInProgress,
			FSOrdinanceStatusNeedsMoreInfo,
			FSOrdinanceStatusNotReady,
			FSOrdinanceStatusNotAvailable,
			FSOrdinanceStatusNotNeeded,
			FSOrdinanceStatusOnHold,
			FSOrdinanceStatusReserved,
			FSOrdinanceStatusNotSet
		];
	}
	return statuses;
}





#pragma mark - Private Methods

- (void)setStatus:(FSOrdinanceStatus)status
{
	_status = status;
}

- (void)setDate:(NSDate *)date
{
	_date = date;
}

- (void)setTempleCode:(NSString *)templeCode
{
	_templeCode = templeCode;
}

- (void)setOfficial:(BOOL)official
{
	_official = official;
}

- (void)setCompleted:(BOOL)completed
{
	_completed = completed;
}

- (void)setReservable:(BOOL)reservable
{
	_reservable = reservable;
}

- (void)setBornInTheCovenant:(BOOL)bornInTheCovenant
{
	_bornInTheCovenant = bornInTheCovenant;
}

- (void)setNotes:(NSString *)notes
{
	_notes = notes;
}

- (void)addPrerequisite:(FSOrdinance *)ordinance
{
	[(NSMutableArray *)_prerequisites addObject:ordinance];
}

- (void)addPerson:(FSPerson *)person
{
	[(NSMutableSet *)_people addObject:person];
}




#pragma mark - Private Helpers

- (BOOL)isEqualToOrdinance:(FSOrdinance *)ordinance
{
	BOOL matchingOfficial		= self.official == ordinance.official;
	BOOL matchingTypes			= [self.type isEqualToString:ordinance.type];
	BOOL matchingPeople			= [self.people isEqualToSet:ordinance.people];
	return (self.official && ordinance.official && matchingTypes && matchingPeople) || (matchingOfficial && matchingTypes && matchingPeople);
}

+ (NSString *)reservationTypeFromOrdinanceType:(FSOrdinanceType)ordinanceType
{
	NSArray *words = [ordinanceType componentsSeparatedByString:@" "];
	NSMutableString *string = [NSMutableString string];
	for (NSString *word in words) {
		if ([words indexOfObject:word] == 0) {
			[string appendString:[word lowercaseString]];
			continue;
		}
		[string appendString:[word capitalizedString]];
	}
	return string;
}


@end
