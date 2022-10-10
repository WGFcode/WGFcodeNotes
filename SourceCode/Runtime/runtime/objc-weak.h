/*
 * Copyright (c) 2010-2011 Apple Inc. All rights reserved.
 *
 * @APPLE_LICENSE_HEADER_START@
 * 
 * This file contains Original Code and/or Modifications of Original Code
 * as defined in and that are subject to the Apple Public Source License
 * Version 2.0 (the 'License'). You may not use this file except in
 * compliance with the License. Please obtain a copy of the License at
 * http://www.opensource.apple.com/apsl/ and read it before using this
 * file.
 * 
 * The Original Code and all software distributed under the License are
 * distributed on an 'AS IS' basis, WITHOUT WARRANTY OF ANY KIND, EITHER
 * EXPRESS OR IMPLIED, AND APPLE HEREBY DISCLAIMS ALL SUCH WARRANTIES,
 * INCLUDING WITHOUT LIMITATION, ANY WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE, QUIET ENJOYMENT OR NON-INFRINGEMENT.
 * Please see the License for the specific language governing rights and
 * limitations under the License.
 * 
 * @APPLE_LICENSE_HEADER_END@
 */

#ifndef _OBJC_WEAK_H_
#define _OBJC_WEAK_H_

#include <objc/objc.h>
#include "objc-config.h"

__BEGIN_DECLS

/*
The weak table is a hash table governed by a single spin lock.
An allocated blob of memory, most often an object, but under GC any such 
allocation, may have its address stored in a __weak marked storage location 
through use of compiler generated write-barriers or hand coded uses of the 
register weak primitive. Associated with the registration can be a callback 
block for the case when one of the allocated chunks of memory is reclaimed. 
The table is hashed on the address of the allocated memory.  When __weak 
marked memory changes its reference, we count on the fact that we can still 
see its previous reference.

So, in the hash table, indexed by the weakly referenced item, is a list of 
all locations where this address is currently being stored.
 
For ARC, we also keep track of whether an arbitrary object is being 
deallocated by briefly placing it in the table just prior to invoking 
dealloc, and removing it via objc_clear_deallocating just prior to memory 
reclamation.

*/

// The address of a __weak variable.
// These pointers are stored disguised so memory analysis tools
// don't see lots of interior pointers from the weak table into objects.
typedef DisguisedPtr<objc_object *> weak_referrer_t;

#if __LP64__
#define PTR_MINUS_2 62
#else
#define PTR_MINUS_2 30
#endif

/**
 * The internal structure stored in the weak references table. 
 * It maintains and stores
 * a hash set of weak references pointing to an object.
 * If out_of_line_ness != REFERRERS_OUT_OF_LINE then the set
 * is instead a small inline array.
 */
#define WEAK_INLINE_COUNT 4

// out_of_line_ness field overlaps with the low two bits of inline_referrers[1].
// inline_referrers[1] is a DisguisedPtr of a pointer-aligned address.
// The low two bits of a pointer-aligned DisguisedPtr will always be 0b00
// (disguised nil or 0x80..00) or 0b11 (any other address).
// Therefore out_of_line_ness == 0b10 is used to mark the out-of-line state.
#define REFERRERS_OUT_OF_LINE 2

/// WGRunTimeSourceCode 源码阅读
/* union联合体特点
 1.联合体中可以定义多个成员，联合体的大小由最大的成员大小决定
 2.联合体的成员公用一个内存，一次只能使用一个成员
 3.对某一个成员赋值，会覆盖其他成员的值
 4.存储效率更高，可读性更强，可以提高代码的可读性，可以使用位运算提高数据的存储效率
 */
//⚠️weak_entry_t底层结构
/*弱引用实体,一个对象对应一个weak_entry_t,保存对象的弱引用;
保存弱应用的是个联合体,当弱引用小于等于4个的时候,直接用inline_referrers数组保存
大于四个时用referrers动态数组
 */
struct weak_entry_t { //对应关系是[referent weak指针的数组]
    DisguisedPtr<objc_object> referent;   //被弱引用的对象
    union { //联合体（共用体）共用体的所有成员占用同一段内存
        struct {
            weak_referrer_t *referrers;  //指向 referent 对象的weak指针数组。动态数组保存弱引用的指针
            uintptr_t        out_of_line_ness : 2;     //这里标记是否超过内联边界, 下面会提到
            uintptr_t        num_refs : PTR_MINUS_2;   //数组中已占用的大小
            uintptr_t        mask;          //数组下标最大值(数组大小 - 1)
            uintptr_t        max_hash_displacement;  //最大哈希偏移值
        };
        struct {
            // out_of_line_ness field is low bits of inline_referrers[1]
            //这是一个取名叫内联引用的数组，WEAK_INLINE_COUNT宏定义值为4 初始化时默认使用的数组
            weak_referrer_t  inline_referrers[WEAK_INLINE_COUNT];  //静态数组
        };
    };
    //当指向这个对象的 weak 指针不超过 4 个, 则直接使用数组 inline_referrers, 省去了哈希操作的步骤, 如果 weak 指针个数超过了4个, 就要使用第一个结构体中的动态数组weak_referrer_t *referrers
    bool out_of_line() {
        return (out_of_line_ness == REFERRERS_OUT_OF_LINE);
    }

    weak_entry_t& operator=(const weak_entry_t& other) {
        memcpy(this, &other, sizeof(other));
        return *this;
    }

    weak_entry_t(objc_object *newReferent, objc_object **newReferrer)
        : referent(newReferent)
    { //构造方法，里面初始化了静态数组
        inline_referrers[0] = newReferrer;
        for (int i = 1; i < WEAK_INLINE_COUNT; i++) {
            inline_referrers[i] = nil;
        }
    }
};

/**
 * The global weak references table. Stores object ids as keys,
 * and weak_entry_t structs as their values.
 */
/// WGRunTimeSourceCode 源码阅读
/*
 weak_table 是一个哈希表的结构, 根据 weak 指针指向的对象的地址计算哈希值, 哈希值相同的对象按照下标 +1 的形式向后查找可用位置, 是典型的闭散列算法. 最大哈希偏移值即是所有对象中计算出的哈希值和实际插入位置的最大偏移量, 在查找时可以作为循环的上限.
 1. 通过对象的地址，可以找到weak_table_t结构中的weak_entry_t
 2. weak_entry_t 中保存了所有指向这个对象的 weak 指针.
 */
//MARK: 对象弱引用表的底层结构weak_table_t
//⚠️弱引用表底层结构
struct weak_table_t {
    weak_entry_t *weak_entries;         //hash数组(动态数组)
    size_t    num_entries;              //hash数组中元素的个数
    uintptr_t mask;                     //hash数组长度-1，而不是元素的个数，一般是做位运算定义的值
    uintptr_t max_hash_displacement;    //hash冲突的最大次数(最大哈希偏移值)
};

//添加一对(object, weak pointer)到weakTable中
/// Adds an (object, weak pointer) pair to the weak table.
id weak_register_no_lock(weak_table_t *weak_table, id referent, 
                         id *referrer, bool crashIfDeallocating);

/// Removes an (object, weak pointer) pair from the weak table.
void weak_unregister_no_lock(weak_table_t *weak_table, id referent, id *referrer);

#if DEBUG
/// Returns true if an object is weakly referenced somewhere.
bool weak_is_registered_no_lock(weak_table_t *weak_table, id referent);
#endif

/// Called on object destruction. Sets all remaining weak pointers to nil.
void weak_clear_no_lock(weak_table_t *weak_table, id referent);

__END_DECLS

#endif /* _OBJC_WEAK_H_ */
