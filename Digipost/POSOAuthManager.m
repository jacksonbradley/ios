//
// Copyright (C) Posten Norge AS
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//         http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

#import <AFNetworking/AFHTTPSessionManager.h>
#import "POSOAuthManager.h"
#import "NSString+RandomNumber.h"
#import "LUKeychainAccess.h"
#import "POSAPIManager.h"
#import "POSFileManager.h"
#import "digipost-Swift.h"
#import "oauth.h"

// Digipost OAuth2 API consts
NSString *const kOAuth2ClientID = @"client_id";
NSString *const kOAuth2RedirectURI = @"redirect_uri";
NSString *const kOAuth2ResponseType = @"response_type";
NSString *const kOAuth2State = @"state";
NSString *const kOAuth2Code = @"code";
NSString *const kOAuth2Scope = @"scope";
NSString *const kOAuth2GrantType = @"grant_type";

NSString *const kOAuth2AccessToken = @"access_token";
NSString *const kOAuth2RefreshToken = @"refresh_token";

NSString *const kOauth2ScopeFull = @"FULL";
NSString *const kOauth2ScopeFullHighAuth = @"FULL_HIGHAUTH";
NSString *const kOauth2ScopeFull_Idporten3 = @"IDPORTEN_3";
NSString *const kOauth2ScopeFull_Idporten4 = @"IDPORTEN_4";

// Internal Keychain key consts
NSString *const kKeychainAccessRefreshTokenKey = @"refresh_token";

// Custom NSError consts
NSString *const kOAuth2ErrorDomain = @"OAuth2ErrorDomain";

NSString *const kOAuth2TokensKey = @"OAuth2Tokens";

@interface POSOAuthManager ()

@property (strong, nonatomic) AFHTTPSessionManager *sessionManager;

@end

@implementation POSOAuthManager

#pragma mark - NSObject

- (instancetype)init
{
    self = [super init];

    if (self) {
        NSURL *baseURL = [NSURL URLWithString:__SERVER_URI__];

        NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
        configuration.requestCachePolicy = NSURLRequestReloadIgnoringLocalAndRemoteCacheData;

        _sessionManager = [[AFHTTPSessionManager alloc] initWithBaseURL:baseURL
                                                   sessionConfiguration:configuration];

        _sessionManager.requestSerializer = [AFHTTPRequestSerializer serializer];
        [_sessionManager.requestSerializer setAuthorizationHeaderFieldWithUsername:OAUTH_CLIENT_ID
                                                                          password:OAUTH_SECRET];

        _sessionManager.responseSerializer = [AFJSONResponseSerializer serializer];

#if (__ACCEPT_SELF_SIGNED_CERTIFICATES__)

        _sessionManager.securityPolicy.allowInvalidCertificates = YES;

#endif
    }

    return self;
}

#pragma mark - Public methods

+ (instancetype)sharedManager
{
    static POSOAuthManager *sharedInstance;

    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[POSOAuthManager alloc] init];
    });

    return sharedInstance;
}

- (void)authenticateWithCode:(NSString *)code scope:(NSString *)scope success:(void (^)(void))success failure:(void (^)(NSError *))failure
{
    NSDictionary *parameters = @{kOAuth2GrantType : kOAuth2Code,
                                 kOAuth2Code : code,
                                 kOAuth2RedirectURI : OAUTH_REDIRECT_URI};

    [self.sessionManager POST:__ACCESS_TOKEN_URI__
        parameters:parameters
        success:^(NSURLSessionDataTask *task, id responseObject) {
                          NSDictionary *responseDict = (NSDictionary *)responseObject;
                          if ([responseDict isKindOfClass:[NSDictionary class]]) {
                              NSString *refreshToken = responseDict[kOAuth2RefreshToken];
                              NSString *accessToken = responseDict[kOAuth2AccessToken];
                              
                              OAuthToken *oAuthToken = [[OAuthToken alloc] initWithRefreshToken:refreshToken accessToken:accessToken scope:scope];
                              if (oAuthToken != nil ) {

                                  // We only call the success block if the access token is set.
                                  // The refresh token is not strictly neccesary at this point.
                                  if (success) {
                                      success();
                                      return;
                                  }
                              }
                          }

                          if (failure) {
                              NSError *error = [NSError errorWithDomain:kOAuth2ErrorDomain
                                                                   code:SHCOAuthErrorCodeMissingAccessTokenResponse
                                                               userInfo:@{NSLocalizedDescriptionKey: NSLocalizedString(@"OAUTH_MANAGER_MISSING_ACCESS_TOKEN_RESPONSE", @"Missing access token response")}];
                              failure(error);
                          }
        }
        failure:^(NSURLSessionDataTask *task, NSError *error) {
                          if (failure) {
                              failure(error);
                          }
        }];
}

- (void)refreshAccessTokenWithRefreshToken:(NSString *)refreshToken scope:(NSString *)scope success:(void (^)(void))success failure:(void (^)(NSError *))failure
{
    NSDictionary *parameters = @{kOAuth2GrantType : kOAuth2RefreshToken,
                                 kOAuth2RefreshToken : refreshToken,
                                 kOAuth2RedirectURI : OAUTH_REDIRECT_URI};

    [self.sessionManager POST:__ACCESS_TOKEN_URI__
        parameters:parameters
        success:^(NSURLSessionDataTask *task, id responseObject) {
                          NSDictionary *responseDict = (NSDictionary *)responseObject;
                          if ([responseDict isKindOfClass:[NSDictionary class]]) {

                              NSString *accessToken = responseDict[kOAuth2AccessToken];
                              if ([accessToken isKindOfClass:[NSString class]]) {
                                  OAuthToken *oauthToken = [OAuthToken oAuthTokenWithScope:scope];
                                  oauthToken.accessToken = accessToken;
                                  DDLogInfo(@"Access token updated");

                                  if (success) {
                                      success();
                                      return;
                                  }
                              }
                          }

                          if (failure) {
                              NSError *error = [NSError errorWithDomain:kOAuth2ErrorDomain
                                                                   code:SHCOAuthErrorCodeMissingAccessTokenResponse
                                                               userInfo:@{NSLocalizedDescriptionKey: NSLocalizedString(@"OAUTH_MANAGER_MISSING_ACCESS_TOKEN_RESPONSE", @"Missing access token response")}];
                              failure(error);
                          }
        }
        failure:^(NSURLSessionDataTask *task, NSError *error) {

                          if (failure) {
                              // Check to see if the request failed because the refresh token was denied

                              if ([[POSAPIManager sharedManager] responseCodeForOAuthIsUnauthorized:task.response]) {
                                  NSError *customError = [NSError errorWithDomain:kOAuth2ErrorDomain
                                                                             code:SHCOAuthErrorCodeInvalidRefreshTokenResponse
                                                                         userInfo:@{NSLocalizedDescriptionKey: NSLocalizedString(@"GENERIC_REFRESH_TOKEN_INVALID_MESSAGE", @"Refresh token invalid message")}];
                                  failure(customError);
                              } else {
                                  failure(error);
                              }
                          }
        }];
}

@end
