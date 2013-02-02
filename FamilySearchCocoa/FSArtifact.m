//
//  FSArtifact.m
//  FamilySearchCocoa
//
//  Created by Adam Kirk on 11/5/12.
//  Copyright (c) 2012 FamilySearch. All rights reserved.
//

#import "FSArtifact.h"
#import "private.h"
#import <NSObject+MTJSONUtils.h>
#import <NSDate+MTDates.h>





@interface FSArtifactTag ()
@property (unsafe_unretained, nonatomic)    FSArtifact  *artifact;
@property (strong, nonatomic)               NSString    *taggedPersonID;
@property (nonatomic)                       BOOL        deleted;
- (MTPocketResponse *)save;
- (MTPocketResponse *)destroy;
- (void)populateFromDictionary:(NSDictionary *)dictionary linkPerson:(BOOL)linkPerson;
@end





@interface FSArtifact ()
@property (strong, nonatomic) NSArray *tags;
@end




@implementation FSArtifact


- (id)initWithIdentifier:(NSString *)identifier data:(NSData *)data MIMEType:(FSArtifactMIMEType)MIMEType
{
    self = [super init];
    if (self) {
        _identifier = identifier;
		_data       = data;
		_MIMEType	= MIMEType;
        _tags       = [NSMutableArray array];
    }
    return self;
}

+ (FSArtifact *)artifactWithData:(NSData *)data MIMEType:(FSArtifactMIMEType)MIMEType
{
	return [[FSArtifact alloc] initWithIdentifier:nil data:data MIMEType:MIMEType];
}

+ (FSArtifact *)artifactWithIdentifier:(NSString *)identifier
{
    return [[FSArtifact alloc] initWithIdentifier:identifier data:nil MIMEType:FSArtifactMIMETypeImagePNG];
}

+ (NSArray *)artifactsForPerson:(FSPerson *)person category:(FSArtifactCategory)category response:(MTPocketResponse **)response
{
    if (!person || !person.identifier) raiseParamException(@"person");

    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    if (category) params[@"artifactCategory"] = category;
    // TODO: I've asked cameraon to add 'includeTags' to this call so we can populate the tags

    MTPocketResponse *resp = *response = [[FSClient requestToArtifactResource:[NSString stringWithFormat:@"persons/personsByTreePersonId/%@/artifacts", person.identifier]
                                                     method:MTPocketMethodGET
                                                       body:nil
                                                     params:params] send];

    if (resp.success) {
        NSMutableArray *artifactsArray = [NSMutableArray array];
        for (NSDictionary *artifactDict in resp.body[@"artifact"]) {
            FSArtifact *artifact = [FSArtifact artifactWithIdentifier:artifactDict[@"id"]];
            [artifact populateFromDictionary:artifactDict linkPerson:YES];
            [artifactsArray addObject:artifact];
        }
        return artifactsArray;
    }

    return nil;
}

+ (FSArtifact *)portraitArtifactForPerson:(FSPerson *)person response:(MTPocketResponse **)response
{
    if (!person || !person.identifier) raiseParamException(@"person");

    NSURL *url = [FSURL  urlWithModule:@"artifactmanager"
                               version:0
                              resource:[NSString stringWithFormat:@"persons/personsByTreePersonId/%@", person.identifier]
                           identifiers:nil
                                params:0
                                  misc:@"includePortraitArtifact=true"];

    MTPocketResponse *resp = *response = [MTPocketRequest requestForURL:url method:MTPocketMethodGET format:MTPocketFormatJSON body:nil].send;


    if (resp.success) {
        NSArray *taggedPersons = resp.body[@"taggedPerson"];
        for (NSDictionary *taggedPersonDict in taggedPersons) {
            NSDictionary *portraitArtifactDict = NILL(taggedPersonDict[@"portraitArtifact"]);
            if (portraitArtifactDict) {
                FSArtifact *portraitArtifact = [FSArtifact artifactWithIdentifier:nil];
                [portraitArtifact populateFromDictionary:portraitArtifactDict];
                return portraitArtifact;
            }
        }
    }

    return nil;
}

+ (NSArray *)artifactsUploadedByCurrentUserWithResponse:(MTPocketResponse **)response
{
    NSURL *url = [FSURL  urlWithModule:@"artifactmanager"
                               version:0
                              resource:@"users/unknown/artifacts"
                           identifiers:nil
                                params:0
                                  misc:@"includeTags=true"];

    MTPocketResponse *resp = *response = [MTPocketRequest requestForURL:url method:MTPocketMethodGET format:MTPocketFormatJSON body:nil].send;

    if (resp.success) {
        NSMutableArray *artifacts = [NSMutableArray array];
        for (NSDictionary *artifactDict in resp.body[@"artifact"]) {
            FSArtifact *artifact = [FSArtifact artifactWithIdentifier:nil];
            [artifact populateFromDictionary:artifactDict];
            [artifacts addObject:artifact];
        }
        return artifacts;
    }

    return nil;
}



#pragma mark - Syncing

- (MTPocketResponse *)fetch
{
	if (!_identifier) raiseException(@"Nil identifier", @"You must set the identifier before you can call fetch.");

    NSURL *url = [FSURL urlWithModule:@"artifactmanager"
                              version:0
                             resource:[NSString stringWithFormat:@"artifacts/%@", _identifier]
                          identifiers:nil
                               params:0
                                 misc:@"includeTags=true"];

    MTPocketResponse *response = [MTPocketRequest requestForURL:url method:MTPocketMethodGET format:MTPocketFormatJSON body:nil].send;

	if (response.success) {
        [self populateFromDictionary:response.body linkPerson:YES];
	}

	return response;
}

- (MTPocketResponse *)save
{
    if (_identifier) return [self update];

	NSMutableArray *params = [NSMutableArray array];
//	[params appendFormat:@"folderId=%@", _person.identifier];
	[params addObject:[NSString stringWithFormat:@"filename=%@", (_originalFilename ? _originalFilename : [[NSUUID UUID] UUIDString])]];
    if (_category) 	[params addObject:[NSString stringWithFormat:@"artifactCategory=%@", _category]];

	NSURL *url = [FSURL urlWithModule:@"artifactmanager"
                              version:0
                             resource:@"artifacts/files"
                          identifiers:nil
                               params:0
                                 misc:[params componentsJoinedByString:@"&"]];

	MTPocketRequest *request = [MTPocketRequest requestForURL:url method:MTPocketMethodPOST format:MTPocketFormatJSON body:_data];
	request.headers = @{ @"Content-Type" : _MIMEType };
	MTPocketResponse *response = [request send];

	if (response.success) {

        // HACK
        // when first creating the artifact, whatever is returned for title and desc should be
        // discarded in favor of the localy set _title and _description
        NSString *title          = [_title copy];
        NSString *description    = [_description copy];
        [self populateFromDictionary:response.body[@"artifact"]];
        _title          = title;
        _description    = description;

        for (FSArtifactTag *tag in _tags) {
            if (!tag.identifier)
                [tag save];
        }

        // TEMP: if they add a &title= param to /artifacts/files, we can ditch this extra request
        if (_title || _description) {
            [self update];
        }
	}

	return response;
}

- (MTPocketResponse *)destroy
{
    if (!_identifier) raiseException(@"Nil identifier", @"You must set the identifier before you can call fetch.");

	NSURL *url = [FSURL urlWithModule:@"artifactmanager"
                              version:0
                             resource:[NSString stringWithFormat:@"artifacts/%@", _identifier]
                          identifiers:nil
                               params:0
                                 misc:nil];

    MTPocketResponse *response = [MTPocketRequest requestForURL:url method:MTPocketMethodDELETE format:MTPocketFormatJSON body:nil].send;

	if (response.success) {
        [self populateFromDictionary:@{}];
	}

	return response;
}





#pragma mark - Tagging

- (NSArray *)tags
{
    return [_tags filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(id evaluatedObject, NSDictionary *bindings) {
        return !((FSArtifactTag *)evaluatedObject).deleted;
    }]];
}

- (void)addTag:(FSArtifactTag *)tag
{
    tag.artifact = self;
    [(NSMutableArray *)_tags addObject:tag];
}

- (void)removeTag:(FSArtifactTag *)tag
{
    tag.deleted = YES;
}





#pragma mark - Protected

- (MTPocketResponse *)fetchAsPortraitForPerson:(FSPerson *)person
{
	NSURL *url = [FSURL urlWithModule:@"artifactmanager"
                              version:0
                             resource:[NSString stringWithFormat:@"artifacts/%@", _identifier]
                          identifiers:nil
                               params:0
                                 misc:nil];

    MTPocketResponse *response = [MTPocketRequest requestForURL:url method:MTPocketMethodDELETE format:MTPocketFormatJSON body:nil].send;

	if (response.success) {
        [self populateFromDictionary:@{}];
	}

	return response;
}





#pragma mark - Private

- (MTPocketResponse *)update
{
	NSURL *url = [FSURL urlWithModule:@"artifactmanager"
                              version:0
                             resource:[NSString stringWithFormat:@"artifacts/%@", _identifier]
                          identifiers:nil
                               params:0
                                 misc:nil];

	NSDictionary *body = @{ @"title" : NUL(_title), @"description" : NUL(_description) };
    MTPocketResponse *response = [MTPocketRequest requestForURL:url method:MTPocketMethodPOST format:MTPocketFormatJSON body:body].send;

    if (response.success) {
        [self populateFromDictionary:response.body];

        // TODO: should probably write a test for this
        for (FSArtifactTag *tag in _tags) {
            if (!tag.identifier)
                [tag save];
            else if (tag.deleted) {
                if ([tag destroy].success) {
                    for (FSArtifactTag *t in _tags) {
                        if (t == tag || [t.identifier isEqualToString:tag.identifier]) {
                            tag.artifact = nil;
                            [(NSMutableArray *)_tags removeObject:tag];
                        }
                    }
                }
            }
        }
	}

	return response;
}

- (void)populateFromDictionary:(NSDictionary *)dictionary
{
    [self populateFromDictionary:dictionary linkPerson:NO];
}

- (void)populateFromDictionary:(NSDictionary *)dictionary linkPerson:(BOOL)linkPerson
{
    _apID					= NILL(dictionary[@"apid"]);
    _category				= NILL(dictionary[@"category"]);
    _description            = NILL(dictionary[@"description"]);
    _folderID				= NILL(dictionary[@"folderId"]);
    _size.height			= [dictionary[@"height"] floatValue];
    _identifier				= NILL([dictionary[@"id"] stringValue]);
    _MIMEType				= NILL(dictionary[@"mimeType"]);
    _originalFilename		= NILL(dictionary[@"originalFilename"]);
    _screeningStatus        = NILL(dictionary[@"screeningState"]);
    if (dictionary[FSArtifactThumbnailStyleNormalKey]) {
        _thumbnails         = @{
                                    FSArtifactThumbnailStyleNormalKey   : dictionary[FSArtifactThumbnailStyleNormalKey],
                                    FSArtifactThumbnailStyleIconKey     : dictionary[FSArtifactThumbnailStyleIconKey],
                                    FSArtifactThumbnailStyleSquareKey   : dictionary[FSArtifactThumbnailStyleSquareKey]
                                };
    }
    _title                  = NILL(dictionary[@"title"]);
    _uploadedDate           = NILL(dictionary[@"uploadDatetime"]);
    if (_uploadedDate) {
        _uploadedDate       = [NSDate dateWithTimeIntervalSince1970:([(NSNumber *)_uploadedDate doubleValue] / 1000.0)];
    }
    _status					= NILL(dictionary[@"uploadState"]);
    _uploaderID				= NILL(dictionary[@"uploaderId"]);
    _url					= [NSURL URLWithString:dictionary[@"url"]];
    _size.width				= [dictionary[@"width"] floatValue];

    // add tags
    NSArray *tags = NILL(dictionary[@"photoTags"]);
    if (tags) {
        for (NSDictionary *tagDict in tags) {
            FSArtifactTag *tag = [[FSArtifactTag alloc] init];
            [tag populateFromDictionary:tagDict linkPerson:linkPerson];
            [self addTag:tag];
        }
    }
}


@end



















@implementation FSArtifactTag

- (id)initWithPerson:(FSPerson *)person title:(NSString *)title rect:(CGRect)rect
{
    self = [super init];
    if (self) {
        _person     = person;
        _title      = title;
		_rect       = rect;
        _deleted    = NO;
    }
    return self;
}

+ (FSArtifactTag *)tagWithPerson:(FSPerson *)person title:(NSString *)title rect:(CGRect)rect
{
    if (!person) raiseParamException(@"person");
    if (!title) raiseParamException(@"title");
	return [[FSArtifactTag alloc] initWithPerson:person title:title rect:rect];
}

- (MTPocketResponse *)save
{
    if (!_artifact) raiseException(@"No artifact", @"This tag must be added to an artifact before it can be saved");
    if (!_person) raiseException(@"No Person", @"You cannot save a tag until you've set the 'person' property");

    NSMutableArray *params = [NSMutableArray array];
    [params addObject:[NSString stringWithFormat:@"treePersonId=%@", _person.identifier]];

    NSURL *url = [FSURL urlWithModule:@"artifactmanager"
                              version:0
                             resource:[NSString stringWithFormat:@"artifacts/%@/tags", _artifact.identifier]
                          identifiers:nil
                               params:0
                                 misc:[params componentsJoinedByString:@"&"]];

    MTPocketResponse *response = [MTPocketRequest requestForURL:url method:MTPocketMethodPOST format:MTPocketFormatJSON body:[self dictionaryValue]].send;


    if (response.success) {
        [self populateFromDictionary:response.body linkPerson:YES];
    }

    return response;
}

- (FSArtifact *)artifactFromSavingTagAsPortraitWithResponse:(MTPocketResponse **)response
{
    if (!_artifact) raiseException(@"No artifact", @"This tag must be added to an artifact before it can be saved");
    if (!_person) raiseException(@"No Person", @"You cannot save a tag until you've set the 'person' property");

    NSURL *url = [FSURL urlWithModule:@"artifactmanager"
                              version:0
                             resource:[NSString stringWithFormat:@"artifacts/%@/tags/%@/portrait", _artifact.identifier, _identifier]
                          identifiers:nil
                               params:0
                                 misc:nil];

    MTPocketResponse *resp = *response = [MTPocketRequest requestForURL:url method:MTPocketMethodPOST format:MTPocketFormatJSON body:nil].send;

    if (resp.success) {
        FSArtifact *createdArtifact = [FSArtifact artifactWithIdentifier:nil];
        [createdArtifact populateFromDictionary:resp.body[@"artifact"]];
        return createdArtifact;
    }
    
    return nil;
}

- (MTPocketResponse *)destroy
{
    if (!_artifact) raiseException(@"No artifact", @"This tag must be added to an artifact before it can be deleted from the server.");
    if (!_identifier) raiseException(@"No identifier", @"You cannot delete a tag with no identifier");

    NSURL *url = [FSURL urlWithModule:@"artifactmanager"
                              version:0
                             resource:[NSString stringWithFormat:@"artifacts/%@/tags/%@", _artifact.identifier, _identifier]
                          identifiers:nil
                               params:0
                                 misc:nil];

    MTPocketResponse *response = [MTPocketRequest requestForURL:url method:MTPocketMethodDELETE format:MTPocketFormatJSON body:nil].send;


    if (response.success) {
        [self populateFromDictionary:@{} linkPerson:NO];
    }
    
    return response;
}





#pragma mark - Private

- (void)populateFromDictionary:(NSDictionary *)dictionary linkPerson:(BOOL)linkPerson
{
    _identifier         = [dictionary[@"id"] stringValue];
    _taggedPersonID     = [dictionary[@"taggedPersonId"] stringValue];
    _rect.size.height   = [dictionary[@"height"] floatValue];
    _rect.size.width    = [dictionary[@"width"] floatValue];
    _rect.origin.x      = [dictionary[@"x"] floatValue];
    _rect.origin.y      = [dictionary[@"y"] floatValue];
    _title              = dictionary[@"title"];

    // TODO: I've asked Cameron to return treePersonId so i don't have to do this
    if (linkPerson && _taggedPersonID) {
        NSURL *url = [FSURL urlWithModule:@"artifactmanager"
                                  version:0
                                 resource:[NSString stringWithFormat:@"persons/%@", _taggedPersonID]
                              identifiers:nil
                                   params:0
                                     misc:nil];

        MTPocketResponse *response = [MTPocketRequest requestForURL:url method:MTPocketMethodGET format:MTPocketFormatJSON body:nil].send;

        if (response.success) {
            NSString *identifier = NILL(response.body[@"personId"]);
            if (identifier)
                _person = [FSPerson personWithIdentifier:identifier];
        }
    }
}

- (NSDictionary *)dictionaryValue
{
	NSMutableDictionary *dict = [NSMutableDictionary dictionary];
	dict[@"artifactId"]	= _artifact.identifier;
	dict[@"title"]      = _title;
	dict[@"x"]          = @(_rect.origin.x);
	dict[@"y"]          = @(_rect.origin.y);
	dict[@"width"]      = @(_rect.size.width);
	dict[@"height"]     = @(_rect.size.height);
	return dict;
}


@end











NSString *const FSArtifactThumbnailStyleNormalKey   = @"thumbUrl";
NSString *const FSArtifactThumbnailStyleIconKey     = @"thumbIconUrl";
NSString *const FSArtifactThumbnailStyleSquareKey   = @"thumbSquareUrl";
