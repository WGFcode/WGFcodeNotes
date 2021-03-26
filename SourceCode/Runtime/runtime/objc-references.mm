/*
 * Copyright (c) 2004-2007 Apple Inc. All rights reserved.
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
/*
  Implementation of the weak / associative references for non-GC mode.
*/


#include "objc-private.h"
#include <objc/message.h>
#include <map>

#if _LIBCPP_VERSION
#   include <unordered_map>
#else
#   include <tr1/unordered_map>
    using namespace tr1;
#endif


// wrap all the murky C++ details in a namespace to get them out of the way.

namespace objc_references_support {
    struct DisguisedPointerEqual {
        bool operator()(uintptr_t p1, uintptr_t p2) const {
            return p1 == p2;
        }
    };
    
    struct DisguisedPointerHash {
        uintptr_t operator()(uintptr_t k) const {
            // borrowed from CFSet.c
#if __LP64__
            uintptr_t a = 0x4368726973746F70ULL;
            uintptr_t b = 0x686572204B616E65ULL;
#else
            uintptr_t a = 0x4B616E65UL;
            uintptr_t b = 0x4B616E65UL; 
#endif
            uintptr_t c = 1;
            a += k;
#if __LP64__
            a -= b; a -= c; a ^= (c >> 43);
            b -= c; b -= a; b ^= (a << 9);
            c -= a; c -= b; c ^= (b >> 8);
            a -= b; a -= c; a ^= (c >> 38);
            b -= c; b -= a; b ^= (a << 23);
            c -= a; c -= b; c ^= (b >> 5);
            a -= b; a -= c; a ^= (c >> 35);
            b -= c; b -= a; b ^= (a << 49);
            c -= a; c -= b; c ^= (b >> 11);
            a -= b; a -= c; a ^= (c >> 12);
            b -= c; b -= a; b ^= (a << 18);
            c -= a; c -= b; c ^= (b >> 22);
#else
            a -= b; a -= c; a ^= (c >> 13);
            b -= c; b -= a; b ^= (a << 8);
            c -= a; c -= b; c ^= (b >> 13);
            a -= b; a -= c; a ^= (c >> 12);
            b -= c; b -= a; b ^= (a << 16);
            c -= a; c -= b; c ^= (b >> 5);
            a -= b; a -= c; a ^= (c >> 3);
            b -= c; b -= a; b ^= (a << 10);
            c -= a; c -= b; c ^= (b >> 15);
#endif
            return c;
        }
    };
    
    struct ObjectPointerLess {
        bool operator()(const void *p1, const void *p2) const {
            return p1 < p2;
        }
    };
    
    struct ObjcPointerHash {
        uintptr_t operator()(void *p) const {
            return DisguisedPointerHash()(uintptr_t(p));
        }
    };

    // STL allocator that uses the runtime's internal allocator.
    
    template <typename T> struct ObjcAllocator {
        typedef T                 value_type;
        typedef value_type*       pointer;
        typedef const value_type *const_pointer;
        typedef value_type&       reference;
        typedef const value_type& const_reference;
        typedef size_t            size_type;
        typedef ptrdiff_t         difference_type;

        template <typename U> struct rebind { typedef ObjcAllocator<U> other; };

        template <typename U> ObjcAllocator(const ObjcAllocator<U>&) {}
        ObjcAllocator() {}
        ObjcAllocator(const ObjcAllocator&) {}
        ~ObjcAllocator() {}

        pointer address(reference x) const { return &x; }
        const_pointer address(const_reference x) const { 
            return x;
        }

        pointer allocate(size_type n, const_pointer = 0) {
            return static_cast<pointer>(::malloc(n * sizeof(T)));
        }

        void deallocate(pointer p, size_type) { ::free(p); }

        size_type max_size() const { 
            return static_cast<size_type>(-1) / sizeof(T);
        }

        void construct(pointer p, const value_type& x) { 
            new(p) value_type(x); 
        }

        void destroy(pointer p) { p->~value_type(); }

        void operator=(const ObjcAllocator&);

    };

    template<> struct ObjcAllocator<void> {
        typedef void        value_type;
        typedef void*       pointer;
        typedef const void *const_pointer;
        template <typename U> struct rebind { typedef ObjcAllocator<U> other; };
    };
  
    typedef uintptr_t disguised_ptr_t;
    inline disguised_ptr_t DISGUISE(id value) { return ~uintptr_t(value); }
    inline id UNDISGUISE(disguised_ptr_t dptr) { return id(~dptr); }
  
    class ObjcAssociation {
        uintptr_t _policy;
        id _value;
    public:
        ObjcAssociation(uintptr_t policy, id value) : _policy(policy), _value(value) {}
        ObjcAssociation() : _policy(0), _value(nil) {}

        uintptr_t policy() const { return _policy; }
        id value() const { return _value; }
        
        bool hasValue() { return _value != nil; }
    };

#if TARGET_OS_WIN32
    typedef hash_map<void *, ObjcAssociation> ObjectAssociationMap;
    typedef hash_map<disguised_ptr_t, ObjectAssociationMap *> AssociationsHashMap;
#else
    typedef ObjcAllocator<std::pair<void * const, ObjcAssociation> > ObjectAssociationMapAllocator;
    class ObjectAssociationMap : public std::map<void *, ObjcAssociation, ObjectPointerLess, ObjectAssociationMapAllocator> {
    public:
        void *operator new(size_t n) { return ::malloc(n); }
        void operator delete(void *ptr) { ::free(ptr); }
    };
    typedef ObjcAllocator<std::pair<const disguised_ptr_t, ObjectAssociationMap*> > AssociationsHashMapAllocator;
    class AssociationsHashMap : public unordered_map<disguised_ptr_t, ObjectAssociationMap *, DisguisedPointerHash, DisguisedPointerEqual, AssociationsHashMapAllocator> {
    public:
        void *operator new(size_t n) { return ::malloc(n); }
        void operator delete(void *ptr) { ::free(ptr); }
    };
#endif
}

using namespace objc_references_support;
//AssociationsManager管理了一个锁、一张哈希表；创建实例对象时会获取到锁；懒加载方式创建哈希表
// class AssociationsManager manages a lock / hash table singleton pair.
// Allocating an instance acquires the lock, and calling its assocations()
// method lazily allocates the hash table.
//自旋锁：忙等状态、比较消耗CPU资源、不能递归调用、如果短时间内可以获取到资源，则使用自旋锁比互斥锁效率要高，因为少了互斥锁中的线程调度等操作
spinlock_t AssociationsManagerLock;

/// WGRunTimeSourceCode 源码阅读
/*
 ⚠️关联对象的管理对象，里面存放的是哈希表AssociationsHashMap，类似一个字典，以key-value形式存在
 AssociationsHashMap结构: <disguised_ptr_t(被关联对象的地址), ObjectAssociationMap *(键值对)>
 ObjectAssociationMap结构: <void *(被关联对象名字的指针), ObjcAssociation(包含关联对象值和协议的类实例)>
 ObjcAssociation结构：
 class ObjcAssociation {
     uintptr_t _policy;
     id _value;
 }
 */
//MARK:关联对象的管理类AssociationsManager
class AssociationsManager {
    // associative references: object pointer -> PtrPtrHashMap.
    static AssociationsHashMap *_map;
public:
    AssociationsManager()   { AssociationsManagerLock.lock(); }
    ~AssociationsManager()  { AssociationsManagerLock.unlock(); }
    
    AssociationsHashMap &associations() {
        if (_map == NULL)
            _map = new AssociationsHashMap();
        return *_map;
    }
};

AssociationsHashMap *AssociationsManager::_map = NULL;

// expanded policy bits.

enum { 
    OBJC_ASSOCIATION_SETTER_ASSIGN      = 0,
    OBJC_ASSOCIATION_SETTER_RETAIN      = 1,
    OBJC_ASSOCIATION_SETTER_COPY        = 3,            // NOTE:  both bits are set, so we can simply test 1 bit in releaseValue below.
    OBJC_ASSOCIATION_GETTER_READ        = (0 << 8), 
    OBJC_ASSOCIATION_GETTER_RETAIN      = (1 << 8), 
    OBJC_ASSOCIATION_GETTER_AUTORELEASE = (2 << 8)
}; 

//⚠️获取关联对象属性值第2⃣️步
id _object_get_associative_reference(id object, void *key) {
    id value = nil;
    uintptr_t policy = OBJC_ASSOCIATION_ASSIGN;
    {
        AssociationsManager manager;
        AssociationsHashMap &associations(manager.associations());
        disguised_ptr_t disguised_object = DISGUISE(object);
        //⚠️通过关联对象object遍历AssociationsHashMap哈希表找到对应的ObjectAssociationMap哈希表
        AssociationsHashMap::iterator i = associations.find(disguised_object);
        if (i != associations.end()) {
            //若找到ObjectAssociationMap哈希表，则再通过key遍历ObjectAssociationMap哈希表找到ObjcAssociation
            ObjectAssociationMap *refs = i->second;
            ObjectAssociationMap::iterator j = refs->find(key);
            if (j != refs->end()) {
                //找到ObjcAssociation后将里面的value值返回
                ObjcAssociation &entry = j->second;
                value = entry.value();
                policy = entry.policy();
                if (policy & OBJC_ASSOCIATION_GETTER_RETAIN) {
                    objc_retain(value);
                }
            }
        }
    }
    if (value && (policy & OBJC_ASSOCIATION_GETTER_AUTORELEASE)) {
        objc_autorelease(value);
    }
    return value;
}

//若关联对象的属性值也是个对象类型，就需要进行引用计数处理
static id acquireValue(id value, uintptr_t policy) {
    switch (policy & 0xFF) {
    case OBJC_ASSOCIATION_SETTER_RETAIN:
        return objc_retain(value);
    case OBJC_ASSOCIATION_SETTER_COPY:
        return ((id(*)(id, SEL))objc_msgSend)(value, SEL_copy);
    }
    return value;
}

static void releaseValue(id value, uintptr_t policy) {
    if (policy & OBJC_ASSOCIATION_SETTER_RETAIN) {
        return objc_release(value);
    }
}

struct ReleaseValue {
    void operator() (ObjcAssociation &association) {
        releaseValue(association.value(), association.policy());
    }
};
/*
 -----AssociationsManager-----
   AssociationsHashMap *_map
                         |
         ---------AssociationsHashMap---------
         disguised_ptr_t : ObjectAssociationMap ----------->
         ...             : ...
         对应object
                                     |
                         ---ObjectAssociationMap---
                           void * : ObjcAssociation
                           ...    : ...     |
                           对应key
                                 ------ObjcAssociation------
                                     uintptr_t _policy   对应策略
                                     id _value           对应Value
 */
//⚠️设置关联对象属性值第2⃣️步
void _object_set_associative_reference(id object, void *key, id value, uintptr_t policy) {
    // retain the new value (if any) outside the lock.
    ObjcAssociation old_association(0, nil);
    id new_value = value ? acquireValue(value, policy) : nil;
    {
        AssociationsManager manager;
        AssociationsHashMap &associations(manager.associations());
        disguised_ptr_t disguised_object = DISGUISE(object);
        //如果new_value不为空，在AssociationsHashMap表中，以关联对象为key,查找对应的ObjectAssociationMap结构
        if (new_value) {
            // break any existing association.
            AssociationsHashMap::iterator i = associations.find(disguised_object);
            if (i != associations.end()) {
                //若找到了ObjectAssociationMap结构，然后通过key，遍历查找对应的ObjcAssociation结构
                // secondary table exists
                ObjectAssociationMap *refs = i->second;
                ObjectAssociationMap::iterator j = refs->find(key);
                if (j != refs->end()) {
                    //若找到了ObjcAssociation结构，则用新的value和policy替换掉原来的值，组成新的ObjcAssociation结构保存到ObjectAssociationMap哈希表中
                    old_association = j->second;
                    j->second = ObjcAssociation(policy, new_value);
                } else {
                    //若没有找到ObjcAssociation机构，则直接将value和policy保存到key映射的ObjectAssociationMap中
                    (*refs)[key] = ObjcAssociation(policy, new_value);
                }
            } else {
                //若在AssociationsHashMap哈希表中没有找到对应的ObjectAssociationMap，则新建一个ObjectAssociationMap对象，然后将new_value通过key的地址映射到ObjectAssociationMap哈希表中保存
                // create the new association (first time).
                ObjectAssociationMap *refs = new ObjectAssociationMap;
                associations[disguised_object] = refs;
                (*refs)[key] = ObjcAssociation(policy, new_value);
                //设置改对象具有关联对象，方便后续对象dealloc时用于判断是否有关联对象，若有就销毁
                object->setHasAssociatedObjects();
            }
        } else {
            //若new_value(value, policy)为空，则通过关联对象为key遍历查找到对应的ObjectAssociationMap哈希表；然后再通过key遍历查找对应的ObjcAssociation，然后将里面的内容(value, policy)清空
            // setting the association to nil breaks the association.
            AssociationsHashMap::iterator i = associations.find(disguised_object);
            if (i !=  associations.end()) {
                ObjectAssociationMap *refs = i->second;
                ObjectAssociationMap::iterator j = refs->find(key);
                if (j != refs->end()) {
                    old_association = j->second;
                    refs->erase(j);
                }
            }
        }
    }
    // release the old value (outside of the lock).
    if (old_association.hasValue()) ReleaseValue()(old_association);
}

//MARK:⚠️销毁关联对象
void _object_remove_assocations(id object) {
    vector< ObjcAssociation,ObjcAllocator<ObjcAssociation> > elements;
    {
        AssociationsManager manager;
        AssociationsHashMap &associations(manager.associations());
        if (associations.size() == 0) return;
        disguised_ptr_t disguised_object = DISGUISE(object);
        //根据对象disguised_object找到AssociationsHashMap哈希表中的ObjectAssociationMap哈希表，将其销毁
        AssociationsHashMap::iterator i = associations.find(disguised_object);
        if (i != associations.end()) {
            // copy all of the associations that need to be removed.
            ObjectAssociationMap *refs = i->second;
            for (ObjectAssociationMap::iterator j = refs->begin(), end = refs->end(); j != end; ++j) {
                elements.push_back(j->second);
            }
            // remove the secondary table.
            delete refs;
            associations.erase(i);
        }
    }
    // the calls to releaseValue() happen outside of the lock.
    for_each(elements.begin(), elements.end(), ReleaseValue());
}
