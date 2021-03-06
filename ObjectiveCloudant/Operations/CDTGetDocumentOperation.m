//
//  CDTGetDocumentOperation.m
//  ObjectiveCouch
//
//  Created by Michael Rhodes on 27/08/2015.
//  Copyright (c) 2015 IBM Corp.
//
//  Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file
//  except in compliance with the License. You may obtain a copy of the License at
//    http://www.apache.org/licenses/LICENSE-2.0
//  Unless required by applicable law or agreed to in writing, software distributed under the
//  License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND,
//  either express or implied. See the License for the specific language governing permissions
//  and limitations under the License.
//

#import "CDTGetDocumentOperation.h"
#import "CDTCouchOperation+internal.h"
#import "CDTOperationRequestBuilder.h"

@implementation CDTGetDocumentOperation

- (BOOL)buildAndValidate
{
    if ([super buildAndValidate]) {
        if (self.docId) {
            return YES;
        }
    }

    return NO;
}

- (NSArray<NSURLQueryItem *> *)queryItems
{
    NSMutableArray *queryItems = [NSMutableArray array];
    [queryItems addObject:[NSURLQueryItem queryItemWithName:@"revs"
                                                      value:(self.revs ? @"true" : @"false")]];
    if (self.revId) {
        [queryItems addObject:[NSURLQueryItem queryItemWithName:@"rev" value:self.revId]];
    }
    return [NSArray arrayWithArray:queryItems];
}

- (NSString *)httpPath
{
    return [NSString stringWithFormat:@"/%@/%@", self.databaseName, self.docId];
}

- (NSString *)httpMethod { return @"GET"; }

#pragma mark Instance methods

- (void)callCompletionHandlerWithError:(NSError *)error
{
    if (self && self.getDocumentCompletionBlock) {
        self.getDocumentCompletionBlock(nil, error);
    }
}

- (void)processResponseWithData:(NSData *)responseData
                     statusCode:(NSInteger)statusCode
                          error:(NSError *)error
{
    NSDictionary *result = nil;
    
    if (responseData && (statusCode == 200)) {
        // We know this will be a dict on 200 response
        result = (NSDictionary *)
        [NSJSONSerialization JSONObjectWithData:responseData options:0 error:nil];
        self.getDocumentCompletionBlock(result, error);
        
    } else {
        NSString *json = [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding];
        NSString *msg =
        [NSString stringWithFormat:@"Get document failed with %ld %@.", (long)statusCode, json];
        NSDictionary *userInfo = @{NSLocalizedDescriptionKey : NSLocalizedString(msg, nil)};
        NSError *error = [NSError errorWithDomain:CDTObjectiveCloudantErrorDomain
                                             code:CDTObjectiveCloudantErrorGetDocumentFailed
                                         userInfo:userInfo];
        self.getDocumentCompletionBlock(nil, error);
    }
}

@end
