//
//  SXXFindSymbols.h
//  CRJailbreakUtilities
//
//  Created by SXX on 2023/4/26.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

__attribute__((visibility("hidden")))
OBJC_EXTERN void *_Nullable SXXFindSymbol(const char *lib, const char *symbol);

NS_ASSUME_NONNULL_END