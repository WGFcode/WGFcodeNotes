//===--- HeapObject.h -------------------------------------------*- C++ -*-===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2017 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//
#ifndef SWIFT_STDLIB_SHIMS_HEAPOBJECT_H
#define SWIFT_STDLIB_SHIMS_HEAPOBJECT_H

#include "RefCount.h"
#include "SwiftStddef.h"
#include "System.h"
#include "Target.h"

#define SWIFT_ABI_HEAP_OBJECT_HEADER_SIZE_64 16
#define SWIFT_ABI_HEAP_OBJECT_HEADER_SIZE_32 8

#ifndef __swift__
#include <type_traits>
#include "swift/Basic/type_traits.h"

namespace swift {

struct InProcess;

//⚠️HeapMetadata是TargetHeapMetadata的别名 InProcess其实就是kind
template <typename Target> struct TargetHeapMetadata;
using HeapMetadata = TargetHeapMetadata<InProcess>;
#else
typedef struct HeapMetadata HeapMetadata;
typedef struct HeapObject HeapObject;
#endif

#if !defined(__swift__) && __has_feature(ptrauth_calls)
#include <ptrauth.h>
#endif
#ifndef __ptrauth_objc_isa_pointer
#define __ptrauth_objc_isa_pointer
#endif


// The members of the HeapObject header that are not shared by a
// standard Objective-C instance
#define SWIFT_HEAPOBJECT_NON_OBJC_MEMBERS       \
  InlineRefCounts refCounts

/// The Swift heap-object header.
/// This must match RefCountedStructTy in IRGen.
/*
 WGSwift底层源码
 第1⃣️步
 ⚠️ swift对象的底层结构是个结构体HeapObject，里面包含两个成员，元数据和引用计数
 元数据类型是HeapMetadata，它是TargetHeapMetadata的别名，所以元数据类型其实是TargetHeapMetadata类型
 */
struct HeapObject {
  /// This is always a valid pointer to a metadata object.
  HeapMetadata const *__ptrauth_objc_isa_pointer metadata;  //指向元数据的指针-8字节
  SWIFT_HEAPOBJECT_NON_OBJC_MEMBERS;                        //引用计数-8字节

#ifndef __swift__
  HeapObject() = default;

  // Initialize a HeapObject header as appropriate for a newly-allocated object.
  constexpr HeapObject(HeapMetadata const *newMetadata) 
    : metadata(newMetadata)
    , refCounts(InlineRefCounts::Initialized)
  { }
  
  // Initialize a HeapObject header for an immortal object
  constexpr HeapObject(HeapMetadata const *newMetadata,
                       InlineRefCounts::Immortal_t immortal)
  : metadata(newMetadata)
  , refCounts(InlineRefCounts::Immortal)
  { }

#ifndef NDEBUG
  void dump() const SWIFT_USED;
#endif

#endif // __swift__
};



//⚠️第2⃣️步 TargetHeapMetadata
/*
 模板类型,这个结构体中没有属性，只有一个初始化方法
 */
template <typename Runtime>
struct TargetHeapMetadata : TargetMetadata<Runtime> {
  using HeaderType = TargetHeapMetadataHeader<Runtime>;

  TargetHeapMetadata() = default;
    //初始化方法 这里传入的参数是MetadataKind kind，其实就是传入的InProcess
  constexpr TargetHeapMetadata(MetadataKind kind)
    : TargetMetadata<Runtime>(kind) {}
#if SWIFT_OBJC_INTEROP
  constexpr TargetHeapMetadata(TargetAnyClassMetadata<Runtime> *isa)
    : TargetMetadata<Runtime>(isa) {}
#endif
};


//⚠️第3⃣️步 MetadataKind元数据类型-总结版
/*
 const unsigned MetadataKindIsNonHeap = 0x200;
 */
enum class MetadataKind : uint32_t {
    /// A class type.
    NOMINALTYPEMETADATAKIND(Class, 0)                                                                   //0x0
    /// A struct type.
    NOMINALTYPEMETADATAKIND(Struct, 0 | MetadataKindIsNonHeap)                                          //0x200
    /// An enum type.
    /// If we add reference enums, that needs to go here.
    NOMINALTYPEMETADATAKIND(Enum, 1 | MetadataKindIsNonHeap)                                            //0x201
    /// An optional type.
    NOMINALTYPEMETADATAKIND(Optional, 2 | MetadataKindIsNonHeap)                                        //0x202
    /// A foreign class, such as a Core Foundation class.
    METADATAKIND(ForeignClass, 3 | MetadataKindIsNonHeap)                                               //0x203
    /// A type whose value is not exposed in the metadata system.
    METADATAKIND(Opaque, 0 | MetadataKindIsRuntimePrivate | MetadataKindIsNonHeap)                      //0x300
    /// A tuple.
    METADATAKIND(Tuple, 1 | MetadataKindIsRuntimePrivate | MetadataKindIsNonHeap)                       //0x301
    /// A monomorphic function.
    METADATAKIND(Function, 2 | MetadataKindIsRuntimePrivate | MetadataKindIsNonHeap)                    //0x302
    /// An existential type.
    METADATAKIND(Existential, 3 | MetadataKindIsRuntimePrivate | MetadataKindIsNonHeap)                 //0x303
    /// A metatype.
    METADATAKIND(Metatype, 4 | MetadataKindIsRuntimePrivate | MetadataKindIsNonHeap)                    //0x304
    /// An ObjC class wrapper.
    METADATAKIND(ObjCClassWrapper, 5 | MetadataKindIsRuntimePrivate | MetadataKindIsNonHeap)            //0x305
    /// An existential metatype.
    METADATAKIND(ExistentialMetatype, 6 | MetadataKindIsRuntimePrivate | MetadataKindIsNonHeap)         //0x306
    /// A heap-allocated local variable using statically-generated metadata.
    METADATAKIND(HeapLocalVariable, 0 | MetadataKindIsNonType)                                          //0x400
    /// A heap-allocated local variable using runtime-instantiated metadata.
    METADATAKIND(HeapGenericLocalVariable, 0 | MetadataKindIsNonType | MetadataKindIsRuntimePrivate)    //0x500
    /// A native error object.
    METADATAKIND(ErrorObject, 1 | MetadataKindIsNonType | MetadataKindIsRuntimePrivate)                 //0x501
    /// A heap-allocated task.
    METADATAKIND(Task, 2 | MetadataKindIsNonType | MetadataKindIsRuntimePrivate)
    /// A non-task async job.
    METADATAKIND(Job, 3 | MetadataKindIsNonType | MetadataKindIsRuntimePrivate)
  LastEnumerated = 0x7FF,
};



//⚠️第4⃣️步 TargetMetadata简化版
/*
 
 */
struct TargetMetadata {
    ......
    StoredPointer Kind;  //⚠️kind属性，就是之前传入的Inprocess，主要用于区分是哪种类型的元数据
    ......
    /// Get the class object for this type if it has one, or return null if the
    /// type is not a class (or not a class with a class object).
    const TargetClassMetadata<Runtime> *getClassObject() const; //⚠️在该方法中去匹配kind返回值是TargetClassMetadata类型
}








#ifdef __cplusplus
extern "C" {
#endif

SWIFT_RUNTIME_STDLIB_API
void _swift_instantiateInertHeapObject(void *address,
                                       const HeapMetadata *metadata);

SWIFT_RUNTIME_STDLIB_API
__swift_size_t swift_retainCount(HeapObject *obj);

SWIFT_RUNTIME_STDLIB_API
__swift_size_t swift_unownedRetainCount(HeapObject *obj);

SWIFT_RUNTIME_STDLIB_API
__swift_size_t swift_weakRetainCount(HeapObject *obj);

#ifdef __cplusplus
} // extern "C"
#endif

#ifndef __swift__
static_assert(std::is_trivially_destructible<HeapObject>::value,
              "HeapObject must be trivially destructible");

static_assert(sizeof(HeapObject) == 2*sizeof(void*),
              "HeapObject must be two pointers long");

static_assert(alignof(HeapObject) == alignof(void*),
              "HeapObject must be pointer-aligned");

} // end namespace swift
#endif // __cplusplus

/// Global bit masks

// TODO(<rdar://problem/34837179>): Convert each macro below to static consts
// when static consts are visible to SIL.

// The extra inhabitants and spare bits of heap object pointers.
// These must align with the values in IRGen's SwiftTargetInfo.cpp.
#if defined(__x86_64__)

#ifdef __APPLE__
#define _swift_abi_LeastValidPointerValue                                      \
  (__swift_uintptr_t) SWIFT_ABI_DARWIN_X86_64_LEAST_VALID_POINTER
#else
#define _swift_abi_LeastValidPointerValue                                      \
  (__swift_uintptr_t) SWIFT_ABI_DEFAULT_LEAST_VALID_POINTER
#endif
#define _swift_abi_SwiftSpareBitsMask                                          \
  (__swift_uintptr_t) SWIFT_ABI_X86_64_SWIFT_SPARE_BITS_MASK
#if SWIFT_TARGET_OS_SIMULATOR
#define _swift_abi_ObjCReservedBitsMask                                        \
  (__swift_uintptr_t) SWIFT_ABI_X86_64_SIMULATOR_OBJC_RESERVED_BITS_MASK
#define _swift_abi_ObjCReservedLowBits                                         \
  (unsigned) SWIFT_ABI_X86_64_SIMULATOR_OBJC_NUM_RESERVED_LOW_BITS
#else
#define _swift_abi_ObjCReservedBitsMask                                        \
  (__swift_uintptr_t) SWIFT_ABI_X86_64_OBJC_RESERVED_BITS_MASK
#define _swift_abi_ObjCReservedLowBits                                         \
  (unsigned) SWIFT_ABI_X86_64_OBJC_NUM_RESERVED_LOW_BITS
#endif

#define _swift_BridgeObject_TaggedPointerBits                                  \
  (__swift_uintptr_t) SWIFT_ABI_DEFAULT_BRIDGEOBJECT_TAG_64

#elif defined(__arm64__) || defined(__aarch64__) || defined(_M_ARM64)

#ifdef __APPLE__
#define _swift_abi_LeastValidPointerValue                                      \
  (__swift_uintptr_t) SWIFT_ABI_DARWIN_ARM64_LEAST_VALID_POINTER
#else
#define _swift_abi_LeastValidPointerValue                                      \
  (__swift_uintptr_t) SWIFT_ABI_DEFAULT_LEAST_VALID_POINTER
#endif
#define _swift_abi_SwiftSpareBitsMask                                          \
  (__swift_uintptr_t) SWIFT_ABI_ARM64_SWIFT_SPARE_BITS_MASK
#define _swift_abi_ObjCReservedBitsMask                                        \
  (__swift_uintptr_t) SWIFT_ABI_ARM64_OBJC_RESERVED_BITS_MASK
#define _swift_abi_ObjCReservedLowBits                                         \
  (unsigned) SWIFT_ABI_ARM64_OBJC_NUM_RESERVED_LOW_BITS
#define _swift_BridgeObject_TaggedPointerBits                                  \
  (__swift_uintptr_t) SWIFT_ABI_DEFAULT_BRIDGEOBJECT_TAG_64

#elif defined(__powerpc64__)

#define _swift_abi_LeastValidPointerValue                                      \
  (__swift_uintptr_t) SWIFT_ABI_DEFAULT_LEAST_VALID_POINTER
#define _swift_abi_SwiftSpareBitsMask                                          \
  (__swift_uintptr_t) SWIFT_ABI_POWERPC64_SWIFT_SPARE_BITS_MASK
#define _swift_abi_ObjCReservedBitsMask                                        \
  (__swift_uintptr_t) SWIFT_ABI_DEFAULT_OBJC_RESERVED_BITS_MASK
#define _swift_abi_ObjCReservedLowBits                                         \
  (unsigned) SWIFT_ABI_DEFAULT_OBJC_NUM_RESERVED_LOW_BITS
#define _swift_BridgeObject_TaggedPointerBits                                  \
  (__swift_uintptr_t) SWIFT_ABI_DEFAULT_BRIDGEOBJECT_TAG_64

#elif defined(__s390x__)

#define _swift_abi_LeastValidPointerValue                                      \
  (__swift_uintptr_t) SWIFT_ABI_DEFAULT_LEAST_VALID_POINTER
#define _swift_abi_SwiftSpareBitsMask                                          \
  (__swift_uintptr_t) SWIFT_ABI_S390X_SWIFT_SPARE_BITS_MASK
#define _swift_abi_ObjCReservedBitsMask                                        \
  (__swift_uintptr_t) SWIFT_ABI_S390X_OBJC_RESERVED_BITS_MASK
#define _swift_abi_ObjCReservedLowBits                                         \
  (unsigned) SWIFT_ABI_S390X_OBJC_NUM_RESERVED_LOW_BITS
#define _swift_BridgeObject_TaggedPointerBits                                  \
  (__swift_uintptr_t) SWIFT_ABI_DEFAULT_BRIDGEOBJECT_TAG_64

#else

#define _swift_abi_LeastValidPointerValue                                      \
  (__swift_uintptr_t) SWIFT_ABI_DEFAULT_LEAST_VALID_POINTER

#if defined(__i386__)
#define _swift_abi_SwiftSpareBitsMask                                          \
  (__swift_uintptr_t) SWIFT_ABI_I386_SWIFT_SPARE_BITS_MASK
#elif defined(__arm__) || defined(_M_ARM)
#define _swift_abi_SwiftSpareBitsMask                                          \
  (__swift_uintptr_t) SWIFT_ABI_ARM_SWIFT_SPARE_BITS_MASK
#else
#define _swift_abi_SwiftSpareBitsMask                                          \
  (__swift_uintptr_t) SWIFT_ABI_DEFAULT_SWIFT_SPARE_BITS_MASK
#endif

#define _swift_abi_ObjCReservedBitsMask                                        \
  (__swift_uintptr_t) SWIFT_ABI_DEFAULT_OBJC_RESERVED_BITS_MASK
#define _swift_abi_ObjCReservedLowBits                                         \
  (unsigned) SWIFT_ABI_DEFAULT_OBJC_NUM_RESERVED_LOW_BITS

#if __POINTER_WIDTH__ == 64
#define _swift_BridgeObject_TaggedPointerBits                                  \
  (__swift_uintptr_t) SWIFT_ABI_DEFAULT_BRIDGEOBJECT_TAG_64
#else
#define _swift_BridgeObject_TaggedPointerBits                                  \
  (__swift_uintptr_t) SWIFT_ABI_DEFAULT_BRIDGEOBJECT_TAG_32
#endif

#endif

/// Corresponding namespaced decls
#ifdef __cplusplus
namespace heap_object_abi {
static const __swift_uintptr_t LeastValidPointerValue =
    _swift_abi_LeastValidPointerValue;
static const __swift_uintptr_t SwiftSpareBitsMask =
    _swift_abi_SwiftSpareBitsMask;
static const __swift_uintptr_t ObjCReservedBitsMask =
    _swift_abi_ObjCReservedBitsMask;
static const unsigned ObjCReservedLowBits =
    _swift_abi_ObjCReservedLowBits;
static const __swift_uintptr_t BridgeObjectTagBitsMask =
    _swift_BridgeObject_TaggedPointerBits;
} // heap_object_abi
#endif // __cplusplus

#endif // SWIFT_STDLIB_SHIMS_HEAPOBJECT_H
