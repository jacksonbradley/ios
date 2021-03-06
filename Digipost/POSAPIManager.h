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

#import <Foundation/Foundation.h>
#import <AFNetworking/AFHTTPSessionManager.h>

// Custom NSError code enum
typedef NS_ENUM(NSUInteger, SHCAPIManagerErrorCode) {
    SHCAPIManagerErrorCodeUnauthorized = 1,
    SHCAPIManagerErrorCodeUploadFileDoesNotExist,
    SHCAPIManagerErrorCodeUploadFileTooBig,
    SHCAPIManagerErrorCodeUploadLinkNotFoundInRootResource,
    SHCAPIManagerErrorCodeUploadFailed,
    SHCAPIManagerErrorCodeNeedHigherAuthenticationLevel
};

typedef NS_ENUM(NSInteger, SHCAPIManagerState) {
    SHCAPIManagerStateIdle = 0,
    SHCAPIManagerStateValidatingAccessToken,
    SHCAPIManagerStateValidatingAccessTokenFinished,
    SHCAPIManagerStateRefreshingAccessToken,
    SHCAPIManagerStateRefreshingAccessTokenFinished,
    SHCAPIManagerStateRefreshingAccessTokenFailed,
    SHCAPIManagerStateRefreshingAccessTokenFailedNeedHigherAuthenticationLevel,
    SHCAPIManagerStateUpdatingRootResource,
    SHCAPIManagerStateUpdatingRootResourceFinished,
    SHCAPIManagerStateUpdatingRootResourceFailed,
    SHCAPIManagerStateUpdatingDocuments,
    SHCAPIManagerStateUpdatingDocumentsFinished,
    SHCAPIManagerStateUpdatingDocumentsFailed,
    SHCAPIManagerStateDownloadingBaseEncryptionModel,
    SHCAPIManagerStateDownloadingBaseEncryptionModelFinished,
    SHCAPIManagerStateDownloadingBaseEncryptionModelFailed,
    SHCAPIManagerStateMovingDocument,
    SHCAPIManagerStateMovingDocumentFinished,
    SHCAPIManagerStateMovingDocumentFailed,
    SHCAPIManagerStateDeletingDocument,
    SHCAPIManagerStateDeletingDocumentFinished,
    SHCAPIManagerStateDeletingDocumentFailed,
    SHCAPIManagerStateDeletingReceipt,
    SHCAPIManagerStateDeletingReceiptFinished,
    SHCAPIManagerStateDeletingReceiptFailed,
    SHCAPIManagerStateUpdatingBankAccount,
    SHCAPIManagerStateUpdatingBankAccountFinished,
    SHCAPIManagerStateUpdatingBankAccountFailed,
    SHCAPIManagerStateSendingInvoiceToBank,
    SHCAPIManagerStateSendingInvoiceToBankFinished,
    SHCAPIManagerStateSendingInvoiceToBankFailed,
    SHCAPIManagerStateUpdatingReceipts,
    SHCAPIManagerStateUpdatingReceiptsFinished,
    SHCAPIManagerStateUpdatingReceiptsFailed,
    SHCAPIManagerStateUploadingFile,
    SHCAPIManagerStateUploadingFileFinished,
    SHCAPIManagerStateUploadingFileFailed,
    SHCAPIManagerStateLoggingOut,
    SHCAPIManagerStateLoggingOutFailed,
    SHCAPIManagerStateLoggingOutFinished,
    SHCAPIManagerStateChangingFolder,
    SHCAPIManagerStateChangingFolderFailed,
    SHCAPIManagerStateChangingFolderFinished,
    SHCAPIManagerStateDeletingFolder,
    SHCAPIManagerStateDeletingFolderFailed,
    SHCAPIManagerStateDeletingFolderFinished,
    SHCAPIManagerStateCreatingFolder,
    SHCAPIManagerStateCreatingFolderFailed,
    SHCAPIManagerStateCreatingFolderFinished,
    SHCAPIManagerStateUpdatingFolder,
    SHCAPIManagerStateUpdatingFolderFailed,
    SHCAPIManagerStateUpdatingFolderFinished,
    SHCAPIManagerStateMovingFolders,
    SHCAPIManagerStateMovingFoldersFinished,
    SHCAPIManagerStateMovingFoldersFailed,
    SHCAPIManagerStateValididatingOpeningReceipt,
    SHCAPIManagerStateValididatingOpeningReceiptFinished,
    SHCAPIManagerStateValididatingOpeningReceiptFailed,
    SHCAPIManagerStateUpdateSingleDocument,
    SHCAPIManagerStateUpdateSingleDocumentFinished,
    SHCAPIManagerStateUpdateSingleDocumentFailed,
    SHCAPIManagerStateChangeDocumentName,
    SHCAPIManagerStateChangeDocumentNameFinished,
    SHCAPIManagerStateChangeDocumentNameFailed,
};
// Custom NSError consts
extern NSString *const kAPIManagerErrorDomain;

// Notification names
extern NSString *const kAPIManagerUploadProgressStartedNotificationName;
extern NSString *const kAPIManagerUploadProgressChangedNotificationName;
extern NSString *const kAPIManagerUploadProgressFinishedNotificationName;

@class POSFolder;
@class POSBaseEncryptedModel;
@class POSDocument;
@class POSInvoice;
@class POSMailbox;
@class POSReceipt;
@class POSAttachment;

@interface POSAPIManager : NSObject

@property (assign, nonatomic, getter=isUpdatingRootResource) BOOL updatingRootResource;
@property (assign, nonatomic, getter=isUpdatingBankAccount) BOOL updatingBankAccount;
@property (assign, nonatomic, getter=isUpdatingDocuments) BOOL updatingDocuments;
@property (assign, nonatomic, getter=isUpdatingReceipts) BOOL updatingReceipts;
@property (assign, nonatomic, getter=isDownloadingBaseEncryptionModel) BOOL downloadingBaseEncryptionModel;
@property (assign, nonatomic, getter=isUploadingFile) BOOL uploadingFile;
@property (strong, nonatomic) NSProgress *uploadProgress;
@property (strong, nonatomic) AFHTTPSessionManager *sessionManager;

+ (instancetype)sharedManager;

- (void)startLogging;
- (void)stopLogging;
- (void)updateRootResourceWithSuccess:(void (^)(void))success failure:(void (^)(NSError *error))failure;
- (void)cancelUpdatingRootResource;
- (void)updateBankAccountWithUri:(NSString *)uri success:(void (^)(void))success failure:(void (^)(NSError *error))failure;
- (void)cancelUpdatingBankAccount;
- (void)sendInvoiceToBank:(POSInvoice *)invoice withSuccess:(void (^)(void))success failure:(void (^)(NSError *error))failure;
- (void)updateDocumentsInFolderWithName:(NSString *)folderName mailboxDigipostAddress:(NSString *)digipostAddress folderUri:(NSString *)folderUri success:(void (^)(void))success failure:(void (^)(NSError *error))failure;
- (void)cancelUpdatingDocuments;
- (void)downloadBaseEncryptionModel:(POSBaseEncryptedModel *)baseEncryptionModel withProgress:(NSProgress *)progress success:(void (^)(void))success failure:(void (^)(NSError *error))failure;
- (void)moveDocument:(POSDocument *)document toFolder:(POSFolder *)folder withSuccess:(void (^)(void))success failure:(void (^)(NSError *))failure;
- (void)deleteDocument:(POSDocument *)document withSuccess:(void (^)(void))success failure:(void (^)(NSError *error))failure;
- (void)logoutWithSuccess:(void (^)(void))success failure:(void (^)(NSError *error))failure;
- (void)cancelDownloadingBaseEncryptionModels;
- (void)updateReceiptsInMailboxWithDigipostAddress:(NSString *)digipostAddress uri:(NSString *)uri success:(void (^)(void))success failure:(void (^)(NSError *error))failure;
- (void)cancelUpdatingReceipts;
- (void)deleteReceipt:(POSReceipt *)receipt withSuccess:(void (^)(void))success failure:(void (^)(NSError *error))failure;
- (void)uploadFileWithURL:(NSURL *)fileURL toFolder:(POSFolder *)folder success:(void (^)(void))success failure:(void (^)(NSError *error))failure;
- (void)cancelUploadingFiles;
- (BOOL)responseCodeIsUnauthorized:(NSURLResponse *)response;
- (BOOL)responseCodeForOAuthIsUnauthorized:(NSURLResponse *)response;

- (void)createFolderWithName:(NSString *)name iconName:(NSString *)iconName forMailBox:(POSMailbox *)mailbox success:(void (^)(void))success failure:(void (^)(NSError *))failure;

- (void)changeFolder:(POSFolder *)folder newName:(NSString *)newName newIcon:(NSString *)newIcon success:(void (^)(void))success failure:(void (^)(NSError *))failure;
- (void)delteFolder:(POSFolder *)folder success:(void (^)(void))success failure:(void (^)(NSError *))failure;
- (void)moveFolder:(NSArray *)folderArray mailbox:(POSMailbox *)mailbox success:(void (^)(void))success failure:(void (^)(NSError *))failure;

- (void)validateOpeningReceipt:(POSAttachment *)attachment success:(void (^)(NSDictionary *))success failure:(void (^)(NSError *))failure;

- (void)updateDocument:(POSDocument *)document success:(void (^)(void))success failure:(void (^)(NSError *))failure;
- (void)changeNameOfDocument:(POSDocument *)document newName:(NSString *)newName success:(void (^)(void))success failure:(void (^)(NSError *))failure;
- (void)logout;
@end
