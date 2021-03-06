//
//  CDTCreateQueryIndexOperation.m
//  ObjectiveCloudant
//
//  Created by Rhys Short on 22/09/2015.
//  Copyright (c) 2015 IBM Corp.
//
//  Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file
//  except in compliance with the License. You may obtain a copy of the License at
//    http://www.apache.org/licenses/LICENSE-2.0
//  Unless required by applicable law or agreed to in writing, software distributed under the
//  License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND,
//  either express or implied. See the License for the specific language governing permissions
//  and limitations under the License.

#import "CDTCreateQueryIndexOperation.h"
#import "CDTSortSyntaxValidator.h"
#import "CDTCouchOperation+internal.h"
#import "CDTOperationRequestBuilder.h"

// Testing this class will need to mock the entire query back end,
// XCTest doesn't provide a way to skip tests based on conditions
@interface CDTCreateQueryIndexOperation ()

@property (nullable, nonatomic, strong) NSData *jsonBody;
@property NSURLRequest *request;

@end

@implementation CDTCreateQueryIndexOperation

- (instancetype)init
{
    self = [super init];
    if (self) {
        _indexType = CDTQueryIndexTypeJson;
        _defaultFieldEnabled = NO;
    }
    return self;
}

- (BOOL)buildAndValidate
{
    if (![super buildAndValidate]) {
        return NO;
    }

    switch (self.indexType) {
        case CDTQueryIndexTypeJson:
            return [self buildAndValidateJsonIndex];
        case CDTQueryIndexTypeText:
            return [self buildAndValidateTextIndex];
        default:
            return NO;
    }
}

- (BOOL)buildAndValidateJsonIndex
{
    // Check whether any text index specific attributes are set; fail if they are
    if (self.selector) {
        return NO;
    }
    if (self.defaultFieldEnabled || self.defaultFieldAnalyzer) {
        return NO;
    }

    // fields is the only required parameter
    if ((!self.fields) || self.fields.count == 0) {
        return NO;
    } else {
        if (![CDTSortSyntaxValidator validateSortSyntaxInArray:self.fields]) {
            return NO;
        }
     }

    NSMutableDictionary *body = [NSMutableDictionary dictionary];
    body[@"index"] = @{ @"fields" : self.fields };
    body[@"type"] = @"json";
    if (self.indexName) {
        body[@"name"] = self.indexName;
    }
    if (self.designDocName) {
        body[@"ddoc"] = self.designDocName;
    }

    NSError *error = nil;

    self.jsonBody = [NSJSONSerialization dataWithJSONObject:body options:0 error:&error];

    return (self.jsonBody != nil);
}

- (BOOL)buildAndValidateTextIndex
{
    // fields parameter is not requried for text indexes
    if (self.fields.count > 0) {  // equal to zero will cause indexing everywhere
        // check the fields are a 2 element dict of strings
        for (NSObject *item in self.fields) {
            if ([item isKindOfClass:[NSDictionary class]]) {
                NSDictionary *field = (NSDictionary *)item;
                if (field.count != 2) {
                    return NO;
                }

                NSObject *fieldName = field[@"name"];
                NSObject *type = field[@"type"];

                if (!fieldName || !type) {
                    return NO;
                }

                if (![fieldName isKindOfClass:[NSString class]]) {
                    return NO;
                }

                if (![@[ @"boolean", @"string", @"number" ] containsObject:type]) {
                    return NO;
                }
            } else {
                return NO;
            }
        }
    }

    NSMutableDictionary *body = [NSMutableDictionary dictionary];
    body[@"index"] = [NSMutableDictionary dictionary];
    if (self.fields) {
        body[@"index"][@"fields"] = self.fields;
    }
    body[@"type"] = @"text";
    if (self.defaultFieldEnabled) {
        // if default field is enabled, but an analyzer hasn't been set, don't emit any json for
        // default field, the user probably wants couchdb's defaults
        if (self.defaultFieldAnalyzer) {
            body[@"index"][@"default_field"] = @{
                @"enabled" : @(self.defaultFieldEnabled),
                @"analyzer" : self.defaultFieldAnalyzer
            };
        }
    } else {
        body[@"index"][@"default_field"] = @{ @"enabled" : @(self.defaultFieldEnabled) };
    }
    if (self.indexName) {
        body[@"name"] = self.indexName;
    }
    if (self.designDocName) {
        body[@"ddoc"] = self.designDocName;
    }
    
    if(self.selector){
        body[@"index"][@"selector"] = self.selector;
    }

    NSError *error = nil;

    self.jsonBody = [NSJSONSerialization dataWithJSONObject:body options:0 error:&error];

    return (self.jsonBody != nil);
}

- (NSString *)httpPath { return [NSString stringWithFormat:@"/%@/_index", self.databaseName]; }

- (NSString *)httpMethod { return @"POST"; }

- (NSData *)httpRequestBody { return self.jsonBody; }

- (void)callCompletionHandlerWithError:(NSError *)error
{
    if (self.createIndexCompletionBlock) {
        self.createIndexCompletionBlock(error);
    }
}



- (void)processResponseWithData:(NSData *)responseData
                     statusCode:(NSInteger)statusCode
                          error:(NSError *)error
{
    if (!error && responseData && statusCode / 100 == 2) {
        self.createIndexCompletionBlock(nil);
    } else if (error) {
        self.createIndexCompletionBlock(error);
    } else {
        NSString *json = [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding];
        NSString *msg = [NSString
                         stringWithFormat:@"Index creation failed with %ld %@.", (long)statusCode, json];
        NSDictionary *userInfo = @{NSLocalizedDescriptionKey : NSLocalizedString(msg, nil)};
        error = [NSError errorWithDomain:CDTObjectiveCloudantErrorDomain
                                    code:CDTObjectiveCloudantErrorCreateQueryIndexFailed
                                userInfo:userInfo];
        self.createIndexCompletionBlock(error);
    }
}

@end
