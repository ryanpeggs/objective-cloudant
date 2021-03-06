//
//  CDTSessionCookieInterceptor.h
//
//
//  Created by Rhys Short on 08/09/2015.
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

#import <Foundation/Foundation.h>
#import "CDTHTTPInterceptor.h"

/**
 An HTTP interceptor which handles creating and renewing session
 cookies from the `_session` HTTP endpoint.
 */
@interface CDTSessionCookieInterceptor : NSObject <CDTHTTPInterceptor>

/**
 Unavailable: use -initWithUsername:password: instead
 */
- (nullable instancetype)init NS_UNAVAILABLE;

/**
 Initialises an instance of CDTSessionCookieInterceptor
 @param username the username to use for authentication
 @param password the password to use for authentication
 */
- (nullable instancetype)initWithUsername:(nonnull NSString*)username
                                 password:(nonnull NSString*)password NS_DESIGNATED_INITIALIZER;

@end
