//
//  SXXFindSymbols.m
//  CRJailbreakUtilities
//
//  Created by SXX on 2023/4/26.
//

#import "SXXFindSymbols.h"

#import <dlfcn.h>
#import <mach/mach_init.h>
#import <mach/mach_types.h>
#import <stddef.h>
#import <string.h>

typedef struct CSTypeRef {
    void *csCppData;
    void *csCppObj;
} CSTypeRef;

#define kCSNull ((CSTypeRef){NULL, NULL})
#define kCSNow 0x80000000u

typedef CSTypeRef CSSymbolicatorRef;
typedef CSTypeRef CSSymbolOwnerRef;
typedef CSTypeRef CSSymbolRef;

typedef struct CSRange {
    unsigned long long location;
    unsigned long long length;
} CSRange;

typedef void (^CSSymbolOwnerIterator)(CSSymbolOwnerRef owner);
typedef void (^CSSymbolIterator)(CSSymbolRef symbol);

static CSSymbolicatorRef (*CSSymbolicatorCreateWithTask)(task_t task) = NULL;
static bool (*CSIsNull)(CSTypeRef cs) = NULL;
static int (*CSSymbolicatorForeachSymbolOwnerWithNameAtTime)(CSSymbolicatorRef cs, const char *name, uint64_t time,
                                                             CSSymbolOwnerIterator it) = NULL;
static long (*CSSymbolOwnerForeachSymbol)(CSSymbolOwnerRef owner, CSSymbolIterator each) = NULL;
static const char *(*CSSymbolGetMangledName)(CSSymbolRef sym) = NULL;
static CSRange (*CSSymbolGetRange)(CSSymbolRef sym) = NULL;
static void (*CSRelease)(CSTypeRef cs) = NULL;
static void *CoreSymbolicationHandle = NULL;

static int CRJUSymbolicationInit(void) {
    if (CoreSymbolicationHandle != NULL) {
        return true;
    }

    CoreSymbolicationHandle =
        dlopen("/System/Library/PrivateFrameworks/CoreSymbolication.framework/CoreSymbolication", RTLD_LAZY);
    if (CoreSymbolicationHandle == NULL) {
        if (CoreSymbolicationHandle) {
            dlclose(CoreSymbolicationHandle);
            CoreSymbolicationHandle = NULL;
        }
        return false;
    }

    void *h = CoreSymbolicationHandle;
    CSSymbolicatorCreateWithTask = (CSSymbolicatorRef(*)(task_t))dlsym(h, "CSSymbolicatorCreateWithTask");
    CSIsNull = (bool (*)(CSTypeRef))dlsym(h, "CSIsNull");
    CSSymbolicatorForeachSymbolOwnerWithNameAtTime =
        (int (*)(CSSymbolicatorRef, const char *, uint64_t, CSSymbolOwnerIterator))dlsym(
            h, "CSSymbolicatorForeachSymbolOwnerWithNameAtTime");
    CSRelease = (void (*)(CSTypeRef))dlsym(h, "CSRelease");
    CSSymbolOwnerForeachSymbol = (long (*)(CSSymbolOwnerRef, CSSymbolIterator))dlsym(h, "CSSymbolOwnerForeachSymbol");
    CSSymbolGetMangledName = (const char *(*)(CSSymbolRef))dlsym(h, "CSSymbolGetMangledName");
    CSSymbolGetRange = (CSRange(*)(CSSymbolRef))dlsym(h, "CSSymbolGetRange");

    if (CSSymbolicatorCreateWithTask == NULL || CSIsNull == NULL ||
        CSSymbolicatorForeachSymbolOwnerWithNameAtTime == NULL || CSRelease == NULL ||
        CSSymbolOwnerForeachSymbol == NULL || CSSymbolGetMangledName == NULL || CSSymbolGetRange == NULL) {
        if (CoreSymbolicationHandle) {
            dlclose(CoreSymbolicationHandle);
            CoreSymbolicationHandle = NULL;
        }
        return false;
    }

    return true;
}

static void *CRJUFindSymbol(const char *symbol_owner, const char *symbol_to_resolve) {
    task_t targetTask = mach_task_self();
    CSSymbolicatorRef targetSymbolicator;

    targetSymbolicator = CSSymbolicatorCreateWithTask(targetTask);
    if (CSIsNull(targetSymbolicator)) {
        return NULL;
    }

    __block CSSymbolOwnerRef symbolOwner = kCSNull;
    CSSymbolicatorForeachSymbolOwnerWithNameAtTime(targetSymbolicator, symbol_owner, kCSNow, ^(CSSymbolOwnerRef owner) {
      symbolOwner = owner;
    });

    if (CSIsNull(symbolOwner)) {
        CSRelease(targetSymbolicator);
        return NULL;
    }

    __block uintptr_t p = (uintptr_t)NULL;
    CSSymbolOwnerForeachSymbol(symbolOwner, ^(CSSymbolRef symbol) {
      const char *symbol_name = CSSymbolGetMangledName(symbol);
      if (symbol_name != NULL) {
          if (0 == strcmp(symbol_name, symbol_to_resolve)) {
              p = CSSymbolGetRange(symbol).location;
          }
      }
    });

    CSRelease(targetSymbolicator);
    if ((uintptr_t)NULL == p) {
        return NULL;
    } else {
        return (void *)p;
    }
}

void *SXXFindSymbol(const char *lib, const char *symbol) {
    if (CRJUSymbolicationInit()) {
        return CRJUFindSymbol(lib, symbol);
    } else {
        return NULL;
    }
}