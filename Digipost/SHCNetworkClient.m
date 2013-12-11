//
//  SHCNetworkClient.m
//  Digipost
//
//  Created by Eivind Bohler on 11.12.13.
//  Copyright (c) 2013 Shortcut. All rights reserved.
//

#import <AFNetworking/AFHTTPSessionManager.h>
#import "SHCNetworkClient.h"
#import "SHCOAuthManager.h"

@interface SHCNetworkClient ()

@property (strong, nonatomic) AFHTTPSessionManager *sessionManager;

@end

@implementation SHCNetworkClient

#pragma mark - NSObject

- (instancetype)init
{
    self = [super init];
    if (self) {
        NSURL *baseURL = [NSURL URLWithString:__SERVER_URI__];
        _sessionManager = [[AFHTTPSessionManager alloc] initWithBaseURL:baseURL
                                                   sessionConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]];

        NSString *contentType = [NSString stringWithFormat:@"application/vnd.digipost-%@+json", __API_VERSION__];

        _sessionManager.requestSerializer = [AFHTTPRequestSerializer serializer];
        [_sessionManager.requestSerializer setValue:contentType forHTTPHeaderField:@"Accept"];

        _sessionManager.responseSerializer = [AFJSONResponseSerializer serializer];
        NSMutableSet *acceptableContentTypesMutable = [NSMutableSet setWithSet:_sessionManager.responseSerializer.acceptableContentTypes];
        [acceptableContentTypesMutable addObject:contentType];
        _sessionManager.responseSerializer.acceptableContentTypes = [NSSet setWithSet:acceptableContentTypesMutable];
    }

    return self;
}

#pragma mark - Public methods

+ (instancetype)sharedClient
{
    static SHCNetworkClient *sharedInstance;

    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[SHCNetworkClient alloc] init];
    });

    return sharedInstance;
}

- (void)updateRootResourceWithSuccess:(void (^)(void))success failure:(void (^)(NSError *))failure
{
    [self validateTokensWithSuccess:^{
        NSURLSessionDataTask *task = [self.sessionManager GET:__ROOT_RESOURCE_URI__
                                                   parameters:nil
                                                      success:^(NSURLSessionDataTask *task, id responseObject) {
                                                          if (success) {
                                                              success();
                                                          }
                                                      } failure:^(NSURLSessionDataTask *task, NSError *error) {
                                                          if (failure) {
                                                              failure(error);
                                                          }
                                                      }];

        DDLogDebug(@"%@", task.currentRequest.URL.absoluteString);

        [task resume];

    } failure:^(NSError *error) {
        if (failure) {
            failure(error);
        }
    }];
}

#pragma mark - Private methods

- (void)validateTokensWithSuccess:(void (^)(void))success failure:(void (^)(NSError *error))failure
{
    SHCOAuthManager *OAuthManager = [SHCOAuthManager sharedManager];

    // If the OAuth manager already has its access token, we'll go ahead and try an API request using this.
    if (OAuthManager.accessToken) {
        if (success) {
            [self updateAuthorizationHeader];
            success();
            return;
        }
    }

    // If the OAuth manager has its refresh token, ask it to update its access token first,
    // and then go ahead and try an API request.
    if (OAuthManager.refreshToken) {
        [OAuthManager refreshAccessTokenWithRefreshToken:OAuthManager.refreshToken success:^{
            if (success) {
                [self updateAuthorizationHeader];
                success();
            }
        } failure:^(NSError *error) {
            if (failure) {
                failure(error);
            }
        }];
    }
}

- (void)updateAuthorizationHeader
{
    NSString *bearer = [NSString stringWithFormat:@"Bearer %@", [SHCOAuthManager sharedManager].accessToken];
    [self.sessionManager.requestSerializer setValue:bearer forHTTPHeaderField:@"Authorization"];
}

@end