/*
 * Copyright (c) 2010-2012 Apple Inc. All rights reserved.
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

#include "objc-private.h"
#include "NSObject.h"

#include "objc-weak.h"
#include "llvm-DenseMap.h"
#include "NSObject.h"

#include <malloc/malloc.h>
#include <stdint.h>
#include <stdbool.h>
#include <mach/mach.h>
#include <mach-o/dyld.h>
#include <mach-o/nlist.h>
#include <sys/types.h>
#include <sys/mman.h>
#include <libkern/OSAtomic.h>
#include <Block.h>
#include <map>
#include <execinfo.h>

@interface NSInvocation
- (SEL)selector;
@end


#if TARGET_OS_MAC

// NSObject used to be in Foundation/CoreFoundation.

#define SYMBOL_ELSEWHERE_IN_3(sym, vers, n)                             \
    OBJC_EXPORT const char elsewhere_ ##n __asm__("$ld$hide$os" #vers "$" #sym); const char elsewhere_ ##n = 0
#define SYMBOL_ELSEWHERE_IN_2(sym, vers, n)     \
    SYMBOL_ELSEWHERE_IN_3(sym, vers, n)
#define SYMBOL_ELSEWHERE_IN(sym, vers)                  \
    SYMBOL_ELSEWHERE_IN_2(sym, vers, __COUNTER__)

#if __OBJC2__
# define NSOBJECT_ELSEWHERE_IN(vers)                       \
    SYMBOL_ELSEWHERE_IN(_OBJC_CLASS_$_NSObject, vers);     \
    SYMBOL_ELSEWHERE_IN(_OBJC_METACLASS_$_NSObject, vers); \
    SYMBOL_ELSEWHERE_IN(_OBJC_IVAR_$_NSObject.isa, vers)
#else
# define NSOBJECT_ELSEWHERE_IN(vers)                       \
    SYMBOL_ELSEWHERE_IN(.objc_class_name_NSObject, vers)
#endif

#if TARGET_OS_IOS
    NSOBJECT_ELSEWHERE_IN(5.1);
    NSOBJECT_ELSEWHERE_IN(5.0);
    NSOBJECT_ELSEWHERE_IN(4.3);
    NSOBJECT_ELSEWHERE_IN(4.2);
    NSOBJECT_ELSEWHERE_IN(4.1);
    NSOBJECT_ELSEWHERE_IN(4.0);
    NSOBJECT_ELSEWHERE_IN(3.2);
    NSOBJECT_ELSEWHERE_IN(3.1);
    NSOBJECT_ELSEWHERE_IN(3.0);
    NSOBJECT_ELSEWHERE_IN(2.2);
    NSOBJECT_ELSEWHERE_IN(2.1);
    NSOBJECT_ELSEWHERE_IN(2.0);
#elif TARGET_OS_OSX
    NSOBJECT_ELSEWHERE_IN(10.7);
    NSOBJECT_ELSEWHERE_IN(10.6);
    NSOBJECT_ELSEWHERE_IN(10.5);
    NSOBJECT_ELSEWHERE_IN(10.4);
    NSOBJECT_ELSEWHERE_IN(10.3);
    NSOBJECT_ELSEWHERE_IN(10.2);
    NSOBJECT_ELSEWHERE_IN(10.1);
    NSOBJECT_ELSEWHERE_IN(10.0);
#else
    // NSObject has always been in libobjc on these platforms.
#endif

// TARGET_OS_MAC
#endif


/***********************************************************************
* Weak ivar support
**********************************************************************/

static id defaultBadAllocHandler(Class cls)
{
    _objc_fatal("attempt to allocate object of class '%s' failed", 
                cls->nameForLogging());
}

static id(*badAllocHandler)(Class) = &defaultBadAllocHandler;

static id callBadAllocHandler(Class cls)
{
    // fixme add re-entrancy protection in case allocation fails inside handler
    return (*badAllocHandler)(cls);
}

void _objc_setBadAllocHandler(id(*newHandler)(Class))
{
    badAllocHandler = newHandler;
}


namespace {

// The order of these bits is important.
#define SIDE_TABLE_WEAKLY_REFERENCED (1UL<<0)
#define SIDE_TABLE_DEALLOCATING      (1UL<<1)  // MSB-ward of weak bit
#define SIDE_TABLE_RC_ONE            (1UL<<2)  // MSB-ward of deallocating bit
#define SIDE_TABLE_RC_PINNED         (1UL<<(WORD_BITS-1))

#define SIDE_TABLE_RC_SHIFT 2
#define SIDE_TABLE_FLAG_MASK (SIDE_TABLE_RC_ONE-1)

//MARK: ⚠️RefcountMap 引用计数表底层结构
/*
 引用计数Map,其实就是个以objc_object为key的hash表，value值对应的就是该对象的引用计数
 三个参数对应的就是：key类型、value类型、是否需要在value=0时释放掉响应的hash节点，这里写的是true
 */
// RefcountMap disguises its pointers because we 
// don't want the table to act as a root for `leaks`.
typedef objc::DenseMap<DisguisedPtr<objc_object>,size_t,true> RefcountMap;


/*
 DenseMap 又是一个模板类   【从其他地方搬过来的 方便在当前页面查看】
 1. ZeroValuesArePurgeable默认是false，但是RefcountMap引用计数表指定其初始化为true；意思就是是否可以使用值为0(引用计数为 1)的桶
 因为空桶存的初始值就是 0, 所以值为 0 的桶和空桶没什么区别.如果允许使用值为 0 的桶, 查找桶时如果没有找到对象对应的桶, 也没有找到墓碑桶,
 就会优先使用值为 0 的桶.
 2. Buckets 指针管理一段连续内存空间, 也就是数组，元素类型是BucketT类型，BucketT类型其实就类似swift中的元素(对象地址,引用计数)；在申请空间后会进行初始化
 在所有位置上都放上空桶（桶的 key 为 EmptyKey 时是空桶),之后对引用计数的操作, 都要依赖于桶;这里苹果把BucketT叫桶，
 实际上Buckets数组才叫桶，苹果把数组中的元素称为桶应该是为了形象一些
 3.NumEntries 记录数组中已使用的非空的桶的个数
 4.NumTombstones, Tombstone 直译为墓碑, 当一个对象的引用计数为0, 要从桶中取出时, 其所处的位置会被标记为 Tombstone. NumTombstones 就是数组中的墓碑的个数；
 当一个对象A引用计数为0时，被释放掉后，就会将该位置(例如下标3)的桶标记为墓碑，下次如果有新的对象B加入，哈希算法后找到的下标就是墓碑所在的下标（下标3），会将这个位置（下标3）记录下来，
 然后继续哈希算法查找位置，如果查找到空桶，就说明在桶数组中之前没有对象B，那么就将墓碑所在的下标（下标3）来存储对象B，这样就可以利用到已经释放的位置了
 5.NumBuckets 桶的数量, 因为数组中始终都充满桶, 所以可以理解为数组大小
 
 大概执行流程：
 1.通过哈希函数计算出对象地址的哈希值(下标)，然后通过哈希值(下标)从Sidetables哈希表中找到SideTable,哈希值重复的对象的引用计数存储在同一个 SideTable 里.
 2.在SideTable中获取到引用计数标后，通过对象地址查找到对应的桶，然后对引用计数进行【加】或者【减】
 */
template<typename KeyT, typename ValueT,
         bool ZeroValuesArePurgeable = false,
         typename KeyInfoT = DenseMapInfo<KeyT> >
class DenseMap
    : public DenseMapBase<DenseMap<KeyT, ValueT, ZeroValuesArePurgeable, KeyInfoT>,
                          KeyT, ValueT, KeyInfoT, ZeroValuesArePurgeable> {
  // Lift some types from the dependent base class into this class for
  // simplicity of referring to them.
  typedef DenseMapBase<DenseMap, KeyT, ValueT, KeyInfoT, ZeroValuesArePurgeable> BaseT;
  typedef typename BaseT::BucketT BucketT;
  friend class DenseMapBase<DenseMap, KeyT, ValueT, KeyInfoT, ZeroValuesArePurgeable>;

  BucketT *Buckets;
  unsigned NumEntries;
  unsigned NumTombstones;
  unsigned NumBuckets;
  ......
                              
  template<typename InputIt>
  DenseMap(const InputIt &I, const InputIt &E) {
    init(NextPowerOf2(std::distance(I, E)));
    this->insert(I, E);
  }
                              
  // 这是对应 64 位的提供数组大小的方法, 需要为桶数组开辟空间时, 会由这个方法来决定数组大小
  //⚠️简单理解就是桶数组的大小会是 2^n.为什么数组的大小是这个规律，是为了哈希出来的哈希值通过映射后，能够均匀的分布到数组中
  inline uint64_t NextPowerOf2(uint64_t A) {
    A |= (A >> 1);
    A |= (A >> 2);
    A |= (A >> 4);
    A |= (A >> 8);
    A |= (A >> 16);
    A |= (A >> 32);
    return A + 1;
  }
}
                              


// Template parameters.
enum HaveOld { DontHaveOld = false, DoHaveOld = true };
enum HaveNew { DontHaveNew = false, DoHaveNew = true };

/// WGRunTimeSourceCode 源码阅读
//⚠️MARK: SideTable底层结构
struct SideTable {
    /*
     自旋锁：忙等状态、比较消耗CPU资源、不能递归调用、如果短时间内可以获取到资源，则使用自旋锁比互斥锁效率要高，因为少了互斥锁中的线程调度等操作
     自旋锁比较适用于锁使用者保持锁时间比较短的情况。正是由于自旋锁使用者一般保持锁时间非常短,因此选择自旋而不是睡眠是非常必要的，自旋锁的效率远高于互斥锁。
     */
    spinlock_t slock;           //自旋锁：用于上锁/解锁SideTable
    RefcountMap refcnts;        //OC对象引用计数Map（key为对象，value为引用计数）-引用计数表
    weak_table_t weak_table;    //OC对象弱引用Map-弱引用表

    
    SideTable() { //构造函数
        memset(&weak_table, 0, sizeof(weak_table));
    }

    ~SideTable() { //析构函数
        _objc_fatal("Do not delete SideTable.");
    }
    //锁操作 符合StripedMap对T的定义
    void lock() { slock.lock(); }
    void unlock() { slock.unlock(); }
    void forceReset() { slock.forceReset(); }

    // Address-ordered lock discipline for a pair of side tables.

    template<HaveOld, HaveNew>
    static void lockTwo(SideTable *lock1, SideTable *lock2);
    template<HaveOld, HaveNew>
    static void unlockTwo(SideTable *lock1, SideTable *lock2);
};


template<>
void SideTable::lockTwo<DoHaveOld, DoHaveNew>
    (SideTable *lock1, SideTable *lock2)
{
    spinlock_t::lockTwo(&lock1->slock, &lock2->slock);
}

template<>
void SideTable::lockTwo<DoHaveOld, DontHaveNew>
    (SideTable *lock1, SideTable *)
{
    lock1->lock();
}

template<>
void SideTable::lockTwo<DontHaveOld, DoHaveNew>
    (SideTable *, SideTable *lock2)
{
    lock2->lock();
}

template<>
void SideTable::unlockTwo<DoHaveOld, DoHaveNew>
    (SideTable *lock1, SideTable *lock2)
{
    spinlock_t::unlockTwo(&lock1->slock, &lock2->slock);
}

template<>
void SideTable::unlockTwo<DoHaveOld, DontHaveNew>
    (SideTable *lock1, SideTable *)
{
    lock1->unlock();
}

template<>
void SideTable::unlockTwo<DontHaveOld, DoHaveNew>
    (SideTable *, SideTable *lock2)
{
    lock2->unlock();
}


// We cannot use a C++ static initializer to initialize SideTables because
// libc calls us before our C++ initializers run. We also don't want a global 
// pointer to this struct because of the extra indirection.
// Do it the hard way.
alignas(StripedMap<SideTable>) static uint8_t 
    SideTableBuf[sizeof(StripedMap<SideTable>)];

static void SideTableInit() {
    new (SideTableBuf) StripedMap<SideTable>();
}

/// WGRunTimeSourceCode 源码阅读
//MARK:⚠️SideTables底层结构
/*
 1. SideTables与iOS内存管理息息相关,其实可以理解成一个全局的hash数组
 2. SideTables实际的类型是存储SideTable的StripedMap，StripedMap里面定义了可以存储SideTable的最大数量StripeCount，最大数量是64个
 3. SideTables可以理解为全局的hash数组，里面存放的是SideTable元素，例如：数组[SideTable]
 4. SideTables的hash键值是一个对象obj的地址，对应的Value值就是SideTable,即一个对象对应一个SideTable；但是SideTable个数最多只有64个，
 所以一个SideTable中可以存放多个对象obj,即多个对象obj可以共用同一个SideTable
 */
static StripedMap<SideTable>& SideTables() {
    return *reinterpret_cast<StripedMap<SideTable>*>(SideTableBuf);
}

// anonymous namespace
};

void SideTableLockAll() {
    SideTables().lockAll();
}

void SideTableUnlockAll() {
    SideTables().unlockAll();
}

void SideTableForceResetAll() {
    SideTables().forceResetAll();
}

void SideTableDefineLockOrder() {
    SideTables().defineLockOrder();
}

void SideTableLocksPrecedeLock(const void *newlock) {
    SideTables().precedeLock(newlock);
}

void SideTableLocksSucceedLock(const void *oldlock) {
    SideTables().succeedLock(oldlock);
}

void SideTableLocksPrecedeLocks(StripedMap<spinlock_t>& newlocks) {
    int i = 0;
    const void *newlock;
    while ((newlock = newlocks.getLock(i++))) {
        SideTables().precedeLock(newlock);
    }
}

void SideTableLocksSucceedLocks(StripedMap<spinlock_t>& oldlocks) {
    int i = 0;
    const void *oldlock;
    while ((oldlock = oldlocks.getLock(i++))) {
        SideTables().succeedLock(oldlock);
    }
}

//
// The -fobjc-arc flag causes the compiler to issue calls to objc_{retain/release/autorelease/retain_block}
//

id objc_retainBlock(id x) {
    return (id)_Block_copy(x);
}

//
// The following SHOULD be called by the compiler directly, but the request hasn't been made yet :-)
//

BOOL objc_should_deallocate(id object) {
    return YES;
}

id
objc_retain_autorelease(id obj)
{
    return objc_autorelease(objc_retain(obj));
}


void
objc_storeStrong(id *location, id obj)
{
    id prev = *location;
    if (obj == prev) {
        return;
    }
    objc_retain(obj);
    *location = obj;
    objc_release(prev);
}


// Update a weak variable.
// If HaveOld is true, the variable has an existing value 
//   that needs to be cleaned up. This value might be nil.
// If HaveNew is true, there is a new value that needs to be 
//   assigned into the variable. This value might be nil.
// If CrashIfDeallocating is true, the process is halted if newObj is 
//   deallocating or newObj's class does not support weak references. 
//   If CrashIfDeallocating is false, nil is stored instead.
enum CrashIfDeallocating {
    DontCrashIfDeallocating = false, DoCrashIfDeallocating = true
};
template <HaveOld haveOld, HaveNew haveNew,
          CrashIfDeallocating crashIfDeallocating>

//MARK: StoreWeak源码->存储weak指针
/*
 ⚠️如果weak指向的对象还没有初始化 ，先对其进行初始化，再把它存储到弱引用表中
 storeWeak<DontHaveOld, DoHaveNew, DoCrashIfDeallocating>
     (location, (objc_object*)newObj);
 为什么搞两个sidetable(oldTable和newTable)，主要是因为 weak 修饰的变量如果之前已经指向一个对象，然后其再次改变指向另一个对象，那么按理来说我们需要释放旧对象中该 weak 变量的记录，也就是要将旧记录删除，然后在新记录中添加。这里的新旧散列表就是这个作用。
 1. 根据新旧变量的地址获取相应的 SideTable
 2. 对两个表进行加锁操作，防止多线程竞争冲突
 3. 进行线程冲突重处理判断
 4. 判断其 isa 是否为空，为空则需要进行初始化
 5. 如果存在旧值，调用 weak_unregister_no_lock 函数清除旧值
 6. 调用 weak_register_no_lock 函数分配新值
 7. 解锁两个表，并返回对象
 */
//MARK:⚠️weak指针存取第2⃣️步
static id 
storeWeak(id *location, objc_object *newObj) { //location 是 weak 指针,newObj 是 weak 指针将要指向的对象
    //模版函数 haveOld、haveNew由编译器传入参数，这里传递的是haveOld=false，haveNew=true
    assert(haveOld  ||  haveNew);
    if (!haveNew) assert(newObj == nil);

    Class previouslyInitializedClass = nil;
    id oldObj;
    SideTable *oldTable;  //⚠️存储旧对象的weak相关的信息
    SideTable *newTable;  //⚠️存储新对象的weak相关的信息

    // Acquire locks for old and new values.
    // Order by lock address to prevent lock ordering problems. 
    // Retry if the old value changes underneath us.
 retry:
    if (haveOld) {  //如果之前weak弱指针(即id *location)有指向，现在要改指向新的对象，那么需要先将旧的指向给删除了，才能重新指向新的对象
        oldObj = *location;                 //⚠️通过弱引用指针获取旧对象
        oldTable = &SideTables()[oldObj];   //⚠️通过旧对象获取到对应的SideTable
    } else {
        oldTable = nil;
    }
    if (haveNew) {
        newTable = &SideTables()[newObj];   //⚠️获取新对象的SideTable
    } else {
        newTable = nil;
    }

    SideTable::lockTwo<haveOld, haveNew>(oldTable, newTable);
    
    //进行线程冲突重处理判断
    if (haveOld  &&  *location != oldObj) {  //如果有旧值，并且现在新的弱引用指向不指向旧对象
        SideTable::unlockTwo<haveOld, haveNew>(oldTable, newTable);
        goto retry;
    }

    // Prevent a deadlock between the weak reference machinery
    // and the +initialize machinery by ensuring that no 
    // weakly-referenced object has an un-+initialized isa.
    if (haveNew  &&  newObj) { //⚠️有新值，并且新值不为nil，
        Class cls = newObj->getIsa();           //⚠️获取新对象的isa指针
        if (cls != previouslyInitializedClass  &&  
            !((objc_class *)cls)->isInitialized()) {
            SideTable::unlockTwo<haveOld, haveNew>(oldTable, newTable);
            //如果cls没有初始化，先对其进行初始化在尝试设置weak
            _class_initialize(_class_getNonMetaClass(cls, (id)newObj));

            // If this class is finished with +initialize then we're good.
            // If this class is still running +initialize on this thread 
            // (i.e. +initialize called storeWeak on an instance of itself)
            // then we may proceed but it will appear initializing and 
            // not yet initialized to the check above.
            // Instead set previouslyInitializedClass to recognize it on retry.
            previouslyInitializedClass = cls;
            goto retry;
        }
    }

    // Clean up old value, if any.
    //⚠️ 清除旧对象weak_table中的location
    if (haveOld) {  //旧对象所在的弱引用表、旧对象、弱引用指针
        //如果 weak 指针有旧值, 则需要在 weak_table 中处理掉旧值
        weak_unregister_no_lock(&oldTable->weak_table, oldObj, location);
    }
    
    // Assign new value, if any.
    //⚠️ 保存location到新对象的weak_table种
    if (haveNew) {
        //如果 weak 指针将要指向新值(即非 location = nil 的情况), 在 weak_table 中处理赋值操作
        newObj = (objc_object *)
            weak_register_no_lock(&newTable->weak_table, (id)newObj, location, 
                                  crashIfDeallocating);
        // weak_register_no_lock returns nil if weak store should be rejected

        // Set is-weakly-referenced bit in refcount table.
        if (newObj  &&  !newObj->isTaggedPointer()) {
            newObj->setWeaklyReferenced_nolock();
        }
        // Do not set *location anywhere else. That would introduce a race.
        //⚠️设置location指针指向newObj
        *location = (id)newObj;
    }
    else { //⚠️没有新值，则无需更改
        // No new value. The storage is not changed.
    }
    
    SideTable::unlockTwo<haveOld, haveNew>(oldTable, newTable);

    return (id)newObj;
}


/** 
 * This function stores a new value into a __weak variable. It would
 * be used anywhere a __weak variable is the target of an assignment.
 * 
 * @param location The address of the weak pointer itself
 * @param newObj The new object this weak ptr should now point to
 * 
 * @return \e newObj
 */
//MARK: weak变量的存储
id
objc_storeWeak(id *location, id newObj)
{
    return storeWeak<DoHaveOld, DoHaveNew, DoCrashIfDeallocating>
        (location, (objc_object *)newObj);
}


/** 
 * This function stores a new value into a __weak variable. 
 * If the new object is deallocating or the new object's class 
 * does not support weak references, stores nil instead.
 * 
 * @param location The address of the weak pointer itself
 * @param newObj The new object this weak ptr should now point to
 * 
 * @return The value stored (either the new object or nil)
 */
id
objc_storeWeakOrNil(id *location, id newObj)
{
    return storeWeak<DoHaveOld, DoHaveNew, DontCrashIfDeallocating>
        (location, (objc_object *)newObj);
}


/** 
 * Initialize a fresh weak pointer to some object location. 
 * It would be used for code like: 
 *
 * (The nil case) 
 * __weak id weakPtr;
 * (The non-nil case) 
 * NSObject *o = ...;
 * __weak id weakPtr = o;
 * 
 * This function IS NOT thread-safe with respect to concurrent 
 * modifications to the weak variable. (Concurrent weak clear is safe.)
 * 这个函数不是线程安全的
 * @param location Address of __weak ptr. 
 * @param newObj Object ptr. 
 */

//MARK: weak实现原理总结
/*
 ⚠️Runtime维护了一个全局的SideTables表，SideTables就是个哈希表，其实就是个数组，里面存放了SideTable结构,SideTables数组中元素的最大数量是64个，通过对象可以找到对应SideTable，进而可以找到对应的弱引用表、对应的引用计数表
 ⚠️SideTable表中存储了一个自旋锁、一个引用计数表RefcountMap、一个弱引用表weak_table_t
 ⚠️weak_table_t weak_table;弱引用表其实就是个哈希表，key是对象的地址，value是weak指针的地址（这个地址的值是所指向对象的地址）数组
 ⚠️weak弱引用指针的原理主要分为weak指针的存储和销毁
 存储阶段：
 1.在初始化阶段：Runtime会调用objc_initWeak方法，这个方法首先判断传入的对象是否为nil，若为nil，
 则直接将弱引用的指针设置为nil，并直接返回nil；若不为nil，则会初始化一个新的weak指针指向对象的地址。
 2.添加引用阶段：objc_initWeak方法会调用storeWeak方法，在storeWeak方法中，更新指针指向，创建对应的弱引用表，将弱引用指针添加到弱引用表中
 3.释放时调用clearDeallocating函数。clearDeallocating函数首先根据对象地址获取所有weak指针地址的数组，然后遍历这个数组把其中的数据设为nil，最后把这个entry从weak表中删除，清理对象的记录
 
 spinlock_t slock;           //自旋锁：用于上锁/解锁SideTable
 RefcountMap refcnts;        //OC对象引用计数Map（key为对象，value为引用计数）
 weak_table_t weak_table;    //OC对象弱引用Map（）
 
 
 NSObject *obj = [[NSObject alloc] init];
 weak的三种赋值情况
 1.变量赋值
 _weakObj = obj;                    编译为：objc_storeWeak(&_weakObj, obj);
 
 2.直接初始化，strong对象赋值
 __weak NSObject *obj1 = obj;       编译为：objc_initWeak(&obj1, obj);
 
 3.直接初始化，weak对象赋值
 __weak NSObject *obj2 = _weakObj;  编译为：objc_copyWeak(&obj2, & _weakObj);
 
 __weak NSObject *obj1 = obj;
 第一个参数id *location： weak指针地址(obj1)
 第二个参数id newObj：weak指针指向的对象(obj)
 这个函数是weak弱引用的底层入口
 */
//MARK:⚠️weak指针存取第1⃣️步
id
objc_initWeak(id *location, id newObj) {
    if (!newObj) { //如果newObj对象为nil，那么指向它的weak指针也要置为nil
        *location = nil;
        return nil;
    }
    //DontHaveOld: 没有旧对象    DoHaveNew: 有新对象     DoCrashIfDeallocating: 如果释放了就Crash提示
    return storeWeak<DontHaveOld, DoHaveNew, DoCrashIfDeallocating>
        (location, (objc_object*)newObj);
}

id
objc_initWeakOrNil(id *location, id newObj) {
    if (!newObj) {
        *location = nil;
        return nil;
    }
    return storeWeak<DontHaveOld, DoHaveNew, DontCrashIfDeallocating>
        (location, (objc_object*)newObj);
}


/** 
 * Destroys the relationship between a weak pointer
 * and the object it is referencing in the internal weak
 * table. If the weak pointer is not referencing anything, 
 * there is no need to edit the weak table. 
 *
 * This function IS NOT thread-safe with respect to concurrent 
 * modifications to the weak variable. (Concurrent weak clear is safe.)
 * 
 * @param location The weak pointer address. 
 */
//MARK: weak变量的释放
void
objc_destroyWeak(id *location)
{
    (void)storeWeak<DoHaveOld, DontHaveNew, DontCrashIfDeallocating>
        (location, nil);
}


/*
  Once upon a time we eagerly cleared *location if we saw the object 
  was deallocating. This confuses code like NSPointerFunctions which 
  tries to pre-flight the raw storage and assumes if the storage is 
  zero then the weak system is done interfering. That is false: the 
  weak system is still going to check and clear the storage later. 
  This can cause objc_weak_error complaints and crashes.
  So we now don't touch the storage until deallocation completes.
*/

id
objc_loadWeakRetained(id *location)
{
    id obj;
    id result;
    Class cls;

    SideTable *table;
    
 retry:
    // fixme std::atomic this load
    obj = *location;
    if (!obj) return nil;
    if (obj->isTaggedPointer()) return obj;
    
    table = &SideTables()[obj];
    
    table->lock();
    if (*location != obj) {
        table->unlock();
        goto retry;
    }
    
    result = obj;

    cls = obj->ISA();
    if (! cls->hasCustomRR()) {
        // Fast case. We know +initialize is complete because
        // default-RR can never be set before then.
        assert(cls->isInitialized());
        if (! obj->rootTryRetain()) {
            result = nil;
        }
    }
    else {
        // Slow case. We must check for +initialize and call it outside
        // the lock if necessary in order to avoid deadlocks.
        if (cls->isInitialized() || _thisThreadIsInitializingClass(cls)) {
            BOOL (*tryRetain)(id, SEL) = (BOOL(*)(id, SEL))
                class_getMethodImplementation(cls, SEL_retainWeakReference);
            if ((IMP)tryRetain == _objc_msgForward) {
                result = nil;
            }
            else if (! (*tryRetain)(obj, SEL_retainWeakReference)) {
                result = nil;
            }
        }
        else {
            table->unlock();
            _class_initialize(cls);
            goto retry;
        }
    }
        
    table->unlock();
    return result;
}

/** 
 * This loads the object referenced by a weak pointer and returns it, after
 * retaining and autoreleasing the object to ensure that it stays alive
 * long enough for the caller to use it. This function would be used
 * anywhere a __weak variable is used in an expression.
 * 
 * @param location The weak pointer address
 * 
 * @return The object pointed to by \e location, or \c nil if \e location is \c nil.
 */
id
objc_loadWeak(id *location)
{
    if (!*location) return nil;
    return objc_autorelease(objc_loadWeakRetained(location));
}


/** 
 * This function copies a weak pointer from one location to another,
 * when the destination doesn't already contain a weak pointer. It
 * would be used for code like:
 *
 *  __weak id src = ...;
 *  __weak id dst = src;
 * 
 * This function IS NOT thread-safe with respect to concurrent 
 * modifications to the destination variable. (Concurrent weak clear is safe.)
 *
 * @param dst The destination variable.
 * @param src The source variable.
 */
void
objc_copyWeak(id *dst, id *src)
{
    id obj = objc_loadWeakRetained(src);
    objc_initWeak(dst, obj);
    objc_release(obj);
}

/** 
 * Move a weak pointer from one location to another.
 * Before the move, the destination must be uninitialized.
 * After the move, the source is nil.
 *
 * This function IS NOT thread-safe with respect to concurrent 
 * modifications to either weak variable. (Concurrent weak clear is safe.)
 *
 */
void
objc_moveWeak(id *dst, id *src)
{
    objc_copyWeak(dst, src);
    objc_destroyWeak(src);
    *src = nil;
}


/***********************************************************************
   Autorelease pool implementation

   A thread's autorelease pool is a stack of pointers. 
   Each pointer is either an object to release, or POOL_BOUNDARY which is 
     an autorelease pool boundary.
   A pool token is a pointer to the POOL_BOUNDARY for that pool. When 
     the pool is popped, every object hotter than the sentinel is released.
   The stack is divided into a doubly-linked list of pages. Pages are added 
     and deleted as necessary. 
   Thread-local storage points to the hot page, where newly autoreleased 
     objects are stored. 
**********************************************************************/

// Set this to 1 to mprotect() autorelease pool contents
#define PROTECT_AUTORELEASEPOOL 0

// Set this to 1 to validate the entire autorelease pool header all the time
// (i.e. use check() instead of fastcheck() everywhere)
#define CHECK_AUTORELEASEPOOL (DEBUG)

BREAKPOINT_FUNCTION(void objc_autoreleaseNoPool(id obj));
BREAKPOINT_FUNCTION(void objc_autoreleasePoolInvalid(const void *token));

namespace {

struct magic_t {
    static const uint32_t M0 = 0xA1A1A1A1;
#   define M1 "AUTORELEASE!"
    static const size_t M1_len = 12;
    uint32_t m[4];
    
    magic_t() {
        assert(M1_len == strlen(M1));
        assert(M1_len == 3 * sizeof(m[1]));

        m[0] = M0;
        strncpy((char *)&m[1], M1, M1_len);
    }

    ~magic_t() {
        m[0] = m[1] = m[2] = m[3] = 0;
    }

    bool check() const {
        return (m[0] == M0 && 0 == strncmp((char *)&m[1], M1, M1_len));
    }

    bool fastcheck() const {
#if CHECK_AUTORELEASEPOOL
        return check();
#else
        return (m[0] == M0);
#endif
    }

#   undef M1
};
/*
 1. 每个AutoreleasePoolPage占用4096个字节，除了用来存放它内部的成员变量外，剩下的空间用来存放autorelease对象的地址
 AutoreleasePoolPage内部成员变量有7个，成员变量占用56个字节，剩下的4040个字节用来存放autorelease对象
 2. 所有的AutoreleasePoolPage对象都是通过双向链表的形式连接在一起
 3. 一个AutoreleasePoolPage的空间被占满时，会新建一个新的AutoreleasePoolPage对象，连接链表，后来的autorelease对象加入到新的page
 4. 调用push方法时，会先将一个POOL_BOUNDARY(哨兵对象/边界对象)入栈POOL_BOUNDARY，值为nil，作为边界，然后返回这个边界对象POOL_BOUNDARY
 的内存地址；push就是压栈操作，先加入边界对象，然后再添加autorelease对象
 5. 调用pop方法时传入一个POOL_BOUNDARY的内存地址，会从最后一个入栈的对象开始发送release消息，直到遇到这个POOL_BOUNDARY
 6. autorelease对象在什么时候释放？
    程序运行启动时，RunLoop会注册两个Observer来管理和维护AutoreleasePool，
   6.1一个Observer用来检测进入RunLoop的状态(kCFRunLoopEntry)，此时会调用objc_autoreleasePoolPush方法向当前的AutoreleasePoolPage
   增加一个POOL_BOUNDARY标志创建自动释放池。
   6.2一个Observer用来检测RunLoop即将进入休眠状态(kCFRunLoopBeforeWaiting)和退出状态(kCFRunLoopExit),
   在检测到RunLoop即将进入休眠状态时，会调用objc_autoreleasePoolPop() 和objc_autoreleasePoolPush() 方法.
   系统会根据情况从最新加入的对象一直往前清理直到遇到POOL_BOUNDARY标志
   在检测到RunLoop退出状态时，会调用objc_autoreleasePoolPop() 方法释放自动释放池内对象
   ⚠️所以autorelease的释放时机取决于RunLoop的运行状态，在RunLoop即将进入休眠和退出状态时，会释放AutoreleasePool自动释放池中所有的autorelease对象
 9. 每一页page里都存储了next指针，指向下次新添加的autoreleased对象的位置
 10. 每一页都有一个深度标记，第一页深度值为0，后面的页面递增1
 11. 自动释放池存储在栈区，page内部地址从低到高依次存储：AutoreleasePoolPage自身的成员、哨兵、自动释放的对象。
 12. 哨兵作为对象指针的边界，在释放池里只会有一个,如果autoreleasepool嵌套,那么可能会有多个哨兵对象
 13. 调用pop方法时传入一个POOL_BOUNDARY的内存地址，会从最后一个入栈的对象开始发送release消息，直到遇到这个POOL_BOUNDARY
 
 高地址
   ｜     自动释放的对象
   ｜     哨兵
 低地址    成员变量
 
 
 
 */
//MARK: AutoreleasePoolPage底层结构
class AutoreleasePoolPage 
{
    // EMPTY_POOL_PLACEHOLDER is stored in TLS when exactly one pool is 
    // pushed and it has never contained any objects. This saves memory 
    // when the top level (i.e. libdispatch) pushes and pops pools but 
    // never uses them.
#   define EMPTY_POOL_PLACEHOLDER ((id*)1)

#   define POOL_BOUNDARY nil     //哨兵对象
    static pthread_key_t const key = AUTORELEASE_POOL_KEY;
    static uint8_t const SCRIBBLE = 0xA3;  // 0xA3A3A3A3 after releasing
    //每一个page的大小
    static size_t const SIZE =
#if PROTECT_AUTORELEASEPOOL
        PAGE_MAX_SIZE;  // must be multiple of vm page size
#else
        PAGE_MAX_SIZE;  // size and alignment, power of 2
#endif
    static size_t const COUNT = SIZE / sizeof(id);
    // AutoreleasePoolPage对象内部有7个成员变量，每个占用8个字节
    magic_t const magic;     //用来校验 AutoreleasePoolPage 的结构是否完整  16字节
    id *next;                //指向了下一个能存放autorelease对象地址的区域，初始化时指向 begin()  8字节
    pthread_t const thread;  //指向当前线程，AutoreleasePool是和线程一一对应的，  8字节
    AutoreleasePoolPage * const parent;  //父节点，指向上一个AutoreleasePoolPage对象，第一个结点的parent值为nil  8字节
    AutoreleasePoolPage *child; //子节点，指向下一个AutoreleasePoolPage对象，最后一个结点的 child 值为 nil  8字节
    uint32_t const depth;       //代表深度，从 0 开始，往后递增 1   4字节
    uint32_t hiwat;    //4字节

    // SIZE-sizeof(*this) bytes of contents follow

    static void * operator new(size_t size) {
        return malloc_zone_memalign(malloc_default_zone(), SIZE, SIZE);
    }
    static void operator delete(void * p) {
        return free(p);
    }

    inline void protect() {
#if PROTECT_AUTORELEASEPOOL
        mprotect(this, SIZE, PROT_READ);
        check();
#endif
    }

    inline void unprotect() {
#if PROTECT_AUTORELEASEPOOL
        check();
        mprotect(this, SIZE, PROT_READ | PROT_WRITE);
#endif
    }

    AutoreleasePoolPage(AutoreleasePoolPage *newParent) 
        : magic(), next(begin()), thread(pthread_self()),
          parent(newParent), child(nil), 
          depth(parent ? 1+parent->depth : 0), 
          hiwat(parent ? parent->hiwat : 0)
    { 
        if (parent) {
            parent->check();
            assert(!parent->child);
            parent->unprotect();
            parent->child = this;
            parent->protect();
        }
        protect();
    }

    ~AutoreleasePoolPage() 
    {
        check();
        unprotect();
        assert(empty());

        // Not recursive: we don't want to blow out the stack 
        // if a thread accumulates a stupendous amount of garbage
        assert(!child);
    }


    void busted(bool die = true) 
    {
        magic_t right;
        (die ? _objc_fatal : _objc_inform)
            ("autorelease pool page %p corrupted\n"
             "  magic     0x%08x 0x%08x 0x%08x 0x%08x\n"
             "  should be 0x%08x 0x%08x 0x%08x 0x%08x\n"
             "  pthread   %p\n"
             "  should be %p\n", 
             this, 
             magic.m[0], magic.m[1], magic.m[2], magic.m[3], 
             right.m[0], right.m[1], right.m[2], right.m[3], 
             this->thread, pthread_self());
    }

    void check(bool die = true) 
    {
        if (!magic.check() || !pthread_equal(thread, pthread_self())) {
            busted(die);
        }
    }

    void fastcheck(bool die = true) 
    {
#if CHECK_AUTORELEASEPOOL
        check(die);
#else
        if (! magic.fastcheck()) {
            busted(die);
        }
#endif
    }

    
    id * begin() {
        return (id *) ((uint8_t *)this+sizeof(*this));
    }
    
    id * end() {
        return (id *) ((uint8_t *)this+SIZE);
    }
    
    //⚠️当 next == begin() 时，表示 AutoreleasePoolPage 为空
    bool empty() {
        return next == begin();
    }
    //⚠️当 next == end() 时，表示 AutoreleasePoolPage 已满
    bool full() { 
        return next == end();
    }

    bool lessThanHalfFull() {
        return (next - begin() < (end() - begin()) / 2);
    }


    void releaseAll() 
    {
        releaseUntil(begin());
    }

    void releaseUntil(id *stop) 
    {
        // Not recursive: we don't want to blow out the stack 
        // if a thread accumulates a stupendous amount of garbage
        
        while (this->next != stop) {
            // Restart from hotPage() every time, in case -release 
            // autoreleased more objects
            AutoreleasePoolPage *page = hotPage();

            // fixme I think this `while` can be `if`, but I can't prove it
            while (page->empty()) {
                page = page->parent;
                setHotPage(page);
            }

            page->unprotect();
            id obj = *--page->next;
            memset((void*)page->next, SCRIBBLE, sizeof(*page->next));
            page->protect();

            if (obj != POOL_BOUNDARY) {
                objc_release(obj);
            }
        }

        setHotPage(this);

#if DEBUG
        // we expect any children to be completely empty
        for (AutoreleasePoolPage *page = child; page; page = page->child) {
            assert(page->empty());
        }
#endif
    }

    void kill() 
    {
        // Not recursive: we don't want to blow out the stack 
        // if a thread accumulates a stupendous amount of garbage
        AutoreleasePoolPage *page = this;
        while (page->child) page = page->child;

        AutoreleasePoolPage *deathptr;
        do {
            deathptr = page;
            page = page->parent;
            if (page) {
                page->unprotect();
                page->child = nil;
                page->protect();
            }
            delete deathptr;
        } while (deathptr != this);
    }

    static void tls_dealloc(void *p) 
    {
        if (p == (void*)EMPTY_POOL_PLACEHOLDER) {
            // No objects or pool pages to clean up here.
            return;
        }

        // reinstate TLS value while we work
        setHotPage((AutoreleasePoolPage *)p);

        if (AutoreleasePoolPage *page = coldPage()) {
            if (!page->empty()) pop(page->begin());  // pop all of the pools
            if (DebugMissingPools || DebugPoolAllocation) {
                // pop() killed the pages already
            } else {
                page->kill();  // free all of the pages
            }
        }
        
        // clear TLS value so TLS destruction doesn't loop
        setHotPage(nil);
    }

    static AutoreleasePoolPage *pageForPointer(const void *p) 
    {
        return pageForPointer((uintptr_t)p);
    }

    static AutoreleasePoolPage *pageForPointer(uintptr_t p) 
    {
        AutoreleasePoolPage *result;
        uintptr_t offset = p % SIZE;

        assert(offset >= sizeof(AutoreleasePoolPage));

        result = (AutoreleasePoolPage *)(p - offset);
        result->fastcheck();

        return result;
    }


    static inline bool haveEmptyPoolPlaceholder()
    {
        id *tls = (id *)tls_get_direct(key);
        return (tls == EMPTY_POOL_PLACEHOLDER);
    }

    static inline id* setEmptyPoolPlaceholder()
    {
        assert(tls_get_direct(key) == nil);
        tls_set_direct(key, (void *)EMPTY_POOL_PLACEHOLDER);
        return EMPTY_POOL_PLACEHOLDER;
    }

    static inline AutoreleasePoolPage *hotPage() 
    {
        AutoreleasePoolPage *result = (AutoreleasePoolPage *)
            tls_get_direct(key);
        if ((id *)result == EMPTY_POOL_PLACEHOLDER) return nil;
        if (result) result->fastcheck();
        return result;
    }
    //设置当前可操作的page
    static inline void setHotPage(AutoreleasePoolPage *page) 
    {
        if (page) page->fastcheck();
        tls_set_direct(key, (void *)page);
    }

    static inline AutoreleasePoolPage *coldPage() 
    {
        AutoreleasePoolPage *result = hotPage();
        if (result) {
            while (result->parent) {
                result = result->parent;
                result->fastcheck();
            }
        }
        return result;
    }
    
    //MARK: ⚠️autoreleasePool自动释放池第2⃣️步
    static inline void *push()
    {
        id *dest;
        if (DebugPoolAllocation) {  //区别Debug模式
            // Each autorelease pool starts on a new pool page.
            //调试模式下，将新建一个链表结点，并将哨兵对象POOL_BOUNDARY加入链表栈中
            dest = autoreleaseNewPage(POOL_BOUNDARY);
        } else {
            //将哨兵对象POOL_BOUNDARY加入链表栈中
            dest = autoreleaseFast(POOL_BOUNDARY);
        }
        assert(dest == EMPTY_POOL_PLACEHOLDER || *dest == POOL_BOUNDARY);
        return dest;
    }
    
    //MARK: ⚠️autoreleasePool自动释放池第2⃣️.1⃣️步
    //新建一个链表，并将哨兵对象加入链表栈中
    static __attribute__((noinline))
    id *autoreleaseNewPage(id obj)
    {
        AutoreleasePoolPage *page = hotPage();   //获取当前最新的page，即当前可操作的page
        if (page) {  //若page不为nil，但是page已经满了，则新建一个page
            return autoreleaseFullPage(obj, page);
        }else {  //若没有page,则新建page
            return autoreleaseNoPage(obj);
        }
    }

    //MARK: ⚠️autoreleasePool自动释放池第3⃣️步
    static inline id *autoreleaseFast(id obj)
    {
        AutoreleasePoolPage *page = hotPage(); //获取最新的page,即链表上最新的结点
        if (page && !page->full()) { //page不为nil且没有装满，则直接将autorelease对象添加到栈中
            return page->add(obj);
        } else if (page) { //若page装满了，则新建一个page,将autorelease对象添加到新创建的page栈中
            return autoreleaseFullPage(obj, page);
        } else { //在没有page的情况下，则新建一个page,将autorelease对象添加到新创建的page栈中
            return autoreleaseNoPage(obj);
        }
    }
    
    //MARK: ⚠️autoreleasePool自动释放池第4⃣️步
    id *add(id obj) //入栈操作，将autorelease对象加入AutoreleasePoolPage栈中
    {
        assert(!full());
        unprotect();     //解除保护
        id *ret = next;  // faster than `return next-1` because of aliasing
        *next++ = obj;  //将obj入栈，并重新定位栈定(next就是栈顶，即可以存放下一个对象的地方)
        protect();  //添加保护
        return ret;   //返回当前next地址，用于传递给pop方法参数，就是当前page中最后添加对象的地址
    }
    
    //MARK: ⚠️autoreleasePool自动释放池第5⃣️步
    static __attribute__((noinline))
    id *autoreleaseFullPage(id obj, AutoreleasePoolPage *page)
    {
        // The hot page is full. 
        // Step to the next non-full page, adding a new page if necessary.
        // Then add the object to that page.
        assert(page == hotPage());
        assert(page->full()  ||  DebugPoolAllocation);

        do {
            if (page->child) {  //若当前page的下一个page(b)不为空，则将当前page的child指向下一个page(b),让page(b)作为当前可操作的page
                page = page->child;
            }else {  //若当前page的下一个page为nil，则需要建建一个page，作为当前可操作的page
                page = new AutoreleasePoolPage(page);
            }
        } while (page->full());
        //设置当前最新的page（即当前可操作的page）
        setHotPage(page);
        return page->add(obj);  //将autorelease对象入栈
    }

    //MARK: ⚠️autoreleasePool自动释放池第6⃣️步
    static __attribute__((noinline))
    id *autoreleaseNoPage(id obj)
    {
        // "No page" could mean no pool has been pushed
        // or an empty placeholder pool has been pushed and has no contents yet
        assert(!hotPage());

        bool pushExtraBoundary = false;
        if (haveEmptyPoolPlaceholder()) {
            // We are pushing a second pool over the empty placeholder pool
            // or pushing the first object into the empty placeholder pool.
            // Before doing that, push a pool boundary on behalf of the pool 
            // that is currently represented by the empty placeholder.
            pushExtraBoundary = true;
        }
        else if (obj != POOL_BOUNDARY  &&  DebugMissingPools) {
            // We are pushing an object with no pool in place, 
            // and no-pool debugging was requested by environment.
            _objc_inform("MISSING POOLS: (%p) Object %p of class %s "
                         "autoreleased with no pool in place - "
                         "just leaking - break on "
                         "objc_autoreleaseNoPool() to debug", 
                         pthread_self(), (void*)obj, object_getClassName(obj));
            objc_autoreleaseNoPool(obj);
            return nil;
        }
        else if (obj == POOL_BOUNDARY  &&  !DebugPoolAllocation) {
            // We are pushing a pool with no pool in place,
            // and alloc-per-pool debugging was not requested.
            // Install and return the empty pool placeholder.
            return setEmptyPoolPlaceholder();
        }

        // We are pushing an object or a non-placeholder'd pool.
        
        // Install the first page.
        AutoreleasePoolPage *page = new AutoreleasePoolPage(nil);  //新创建一个page，
        setHotPage(page);   //并设置该page为当前可操作的page
        
        // Push a boundary on behalf of the previously-placeholder'd pool.
        if (pushExtraBoundary) {
            page->add(POOL_BOUNDARY);   //然后将哨兵对象POOL_BOUNDARY压入栈中
        }
        //先将哨兵对象POOL_BOUNDARY压入栈中，然后将对象添加到page栈中
        // Push the requested object or pool.
        return page->add(obj);
    }


public:
    static inline id autorelease(id obj)
    {
        assert(obj);
        assert(!obj->isTaggedPointer());
        id *dest __unused = autoreleaseFast(obj);
        assert(!dest  ||  dest == EMPTY_POOL_PLACEHOLDER  ||  *dest == obj);
        return obj;
    }

    static void badPop(void *token)
    {
        // Error. For bincompat purposes this is not 
        // fatal in executables built with old SDKs.

        if (DebugPoolAllocation || sdkIsAtLeast(10_12, 10_0, 10_0, 3_0, 2_0)) {
            // OBJC_DEBUG_POOL_ALLOCATION or new SDK. Bad pop is fatal.
            _objc_fatal
                ("Invalid or prematurely-freed autorelease pool %p.", token);
        }

        // Old SDK. Bad pop is warned once.
        static bool complained = false;
        if (!complained) {
            complained = true;
            _objc_inform_now_and_on_crash
                ("Invalid or prematurely-freed autorelease pool %p. "
                 "Set a breakpoint on objc_autoreleasePoolInvalid to debug. "
                 "Proceeding anyway because the app is old "
                 "(SDK version " SDK_FORMAT "). Memory errors are likely.",
                     token, FORMAT_SDK(sdkVersion()));
        }
        objc_autoreleasePoolInvalid(token);
    }
    
    //执行pop出栈时，会传入push操作的返回值，即POOL_BOUNDARY的内存地址token，根据token找到哨兵对象所在，并释放之前的对象，next指针--
    //MARK: ⚠️autoreleasePool自动释放池第8⃣️步
    static inline void pop(void *token) 
    {
        AutoreleasePoolPage *page;
        id *stop;

        if (token == (void*)EMPTY_POOL_PLACEHOLDER) {
            // Popping the top-level placeholder pool.
            if (hotPage()) {
                // Pool was used. Pop its contents normally.
                // Pool pages remain allocated for re-use as usual.
                pop(coldPage()->begin());
            } else {
                // Pool was never used. Clear the placeholder.
                setHotPage(nil);
            }
            return;
        }
        //根据传入的哨兵对象地址，找到对应的可操作的page
        page = pageForPointer(token);
        stop = (id *)token;
        if (*stop != POOL_BOUNDARY) {
            if (stop == page->begin()  &&  !page->parent) {
                // Start of coldest page may correctly not be POOL_BOUNDARY:
                // 1. top-level pool is popped, leaving the cold page in place
                // 2. an object is autoreleased with no pool
            } else {
                // Error. For bincompat purposes this is not 
                // fatal in executables built with old SDKs.
                return badPop(token);
            }
        }

        if (PrintPoolHiwat) printHiwat();

        page->releaseUntil(stop);

        // memory: delete empty children
        if (DebugPoolAllocation  &&  page->empty()) {
            // special case: delete everything during page-per-pool debugging
            AutoreleasePoolPage *parent = page->parent;
            page->kill();
            setHotPage(parent);
        } else if (DebugMissingPools  &&  page->empty()  &&  !page->parent) {
            // special case: delete everything for pop(top) 
            // when debugging missing autorelease pools
            page->kill();
            setHotPage(nil);
        } 
        else if (page->child) {
            // hysteresis: keep one empty child if page is more than half full
            if (page->lessThanHalfFull()) {
                page->child->kill();
            }
            else if (page->child->child) {
                page->child->child->kill();
            }
        }
    }

    static void init()
    {
        int r __unused = pthread_key_init_np(AutoreleasePoolPage::key, 
                                             AutoreleasePoolPage::tls_dealloc);
        assert(r == 0);
    }

    void print() 
    {
        _objc_inform("[%p]  ................  PAGE %s %s %s", this, 
                     full() ? "(full)" : "", 
                     this == hotPage() ? "(hot)" : "", 
                     this == coldPage() ? "(cold)" : "");
        check(false);
        for (id *p = begin(); p < next; p++) {
            if (*p == POOL_BOUNDARY) {
                _objc_inform("[%p]  ################  POOL %p", p, p);
            } else {
                _objc_inform("[%p]  %#16lx  %s", 
                             p, (unsigned long)*p, object_getClassName(*p));
            }
        }
    }

    static void printAll()
    {        
        _objc_inform("##############");
        _objc_inform("AUTORELEASE POOLS for thread %p", pthread_self());

        AutoreleasePoolPage *page;
        ptrdiff_t objects = 0;
        for (page = coldPage(); page; page = page->child) {
            objects += page->next - page->begin();
        }
        _objc_inform("%llu releases pending.", (unsigned long long)objects);

        if (haveEmptyPoolPlaceholder()) {
            _objc_inform("[%p]  ................  PAGE (placeholder)", 
                         EMPTY_POOL_PLACEHOLDER);
            _objc_inform("[%p]  ################  POOL (placeholder)", 
                         EMPTY_POOL_PLACEHOLDER);
        }
        else {
            for (page = coldPage(); page; page = page->child) {
                page->print();
            }
        }

        _objc_inform("##############");
    }

    static void printHiwat()
    {
        // Check and propagate high water mark
        // Ignore high water marks under 256 to suppress noise.
        AutoreleasePoolPage *p = hotPage();
        uint32_t mark = p->depth*COUNT + (uint32_t)(p->next - p->begin());
        if (mark > p->hiwat  &&  mark > 256) {
            for( ; p; p = p->parent) {
                p->unprotect();
                p->hiwat = mark;
                p->protect();
            }
            
            _objc_inform("POOL HIGHWATER: new high water mark of %u "
                         "pending releases for thread %p:", 
                         mark, pthread_self());
            
            void *stack[128];
            int count = backtrace(stack, sizeof(stack)/sizeof(stack[0]));
            char **sym = backtrace_symbols(stack, count);
            for (int i = 0; i < count; i++) {
                _objc_inform("POOL HIGHWATER:     %s", sym[i]);
            }
            free(sym);
        }
    }

#undef POOL_BOUNDARY
};

// anonymous namespace
};


/***********************************************************************
* Slow paths for inline control
**********************************************************************/

#if SUPPORT_NONPOINTER_ISA

NEVER_INLINE id 
objc_object::rootRetain_overflow(bool tryRetain)
{
    return rootRetain(tryRetain, true);
}


NEVER_INLINE bool 
objc_object::rootRelease_underflow(bool performDealloc)
{
    return rootRelease(performDealloc, true);
}


// Slow path of clearDeallocating() 
// for objects with nonpointer isa
// that were ever weakly referenced 
// or whose retain count ever overflowed to the side table.
NEVER_INLINE void
//MARK: ⚠️dealloc销毁对象第6⃣️.2⃣️步  若有弱引用或者sidetable存储有引用计数
objc_object::clearDeallocating_slow() {
    assert(isa.nonpointer  &&  (isa.weakly_referenced || isa.has_sidetable_rc));
    SideTable& table = SideTables()[this];  //拿到对象的地址通过hash算法获取到SideTable
    table.lock();
    if (isa.weakly_referenced) { //若有弱引用表，则会将指向该对象的弱引用指针置为nil。
        //⚠️全局搜索weak_clear_no_lock(weak_table_t *weak_table, id referent_id)
        weak_clear_no_lock(&table.weak_table, (id)this);
    }
    if (isa.has_sidetable_rc) { //若有引用计数表，从引用计数表中擦除该对象的引用计数。
        table.refcnts.erase(this);
    }
    table.unlock();
}

#endif

__attribute__((noinline,used))
id 
objc_object::rootAutorelease2()
{
    assert(!isTaggedPointer());
    return AutoreleasePoolPage::autorelease((id)this);
}


BREAKPOINT_FUNCTION(
    void objc_overrelease_during_dealloc_error(void)
);


NEVER_INLINE
bool 
objc_object::overrelease_error()
{
    _objc_inform_now_and_on_crash("%s object %p overreleased while already deallocating; break on objc_overrelease_during_dealloc_error to debug", object_getClassName((id)this), this);
    objc_overrelease_during_dealloc_error();
    return false;  // allow rootRelease() to tail-call this
}


/***********************************************************************
* Retain count operations for side table.
**********************************************************************/


#if DEBUG
// Used to assert that an object is not present in the side table.
bool
objc_object::sidetable_present()
{
    bool result = false;
    SideTable& table = SideTables()[this];

    table.lock();

    RefcountMap::iterator it = table.refcnts.find(this);
    if (it != table.refcnts.end()) result = true;

    if (weak_is_registered_no_lock(&table.weak_table, (id)this)) result = true;

    table.unlock();

    return result;
}
#endif

#if SUPPORT_NONPOINTER_ISA

void 
objc_object::sidetable_lock()
{
    SideTable& table = SideTables()[this];
    table.lock();
}

void 
objc_object::sidetable_unlock()
{
    SideTable& table = SideTables()[this];
    table.unlock();
}


// Move the entire retain count to the side table, 
// as well as isDeallocating and weaklyReferenced.
void 
objc_object::sidetable_moveExtraRC_nolock(size_t extra_rc, 
                                          bool isDeallocating, 
                                          bool weaklyReferenced)
{
    assert(!isa.nonpointer);        // should already be changed to raw pointer
    SideTable& table = SideTables()[this];

    size_t& refcntStorage = table.refcnts[this];
    size_t oldRefcnt = refcntStorage;
    // not deallocating - that was in the isa
    assert((oldRefcnt & SIDE_TABLE_DEALLOCATING) == 0);  
    assert((oldRefcnt & SIDE_TABLE_WEAKLY_REFERENCED) == 0);  

    uintptr_t carry;
    size_t refcnt = addc(oldRefcnt, extra_rc << SIDE_TABLE_RC_SHIFT, 0, &carry);
    if (carry) refcnt = SIDE_TABLE_RC_PINNED;
    if (isDeallocating) refcnt |= SIDE_TABLE_DEALLOCATING;
    if (weaklyReferenced) refcnt |= SIDE_TABLE_WEAKLY_REFERENCED;

    refcntStorage = refcnt;
}


// Move some retain counts to the side table from the isa field.
// Returns true if the object is now pinned.
bool 
objc_object::sidetable_addExtraRC_nolock(size_t delta_rc)
{
    assert(isa.nonpointer);
    SideTable& table = SideTables()[this];

    size_t& refcntStorage = table.refcnts[this];
    size_t oldRefcnt = refcntStorage;
    // isa-side bits should not be set here
    assert((oldRefcnt & SIDE_TABLE_DEALLOCATING) == 0);
    assert((oldRefcnt & SIDE_TABLE_WEAKLY_REFERENCED) == 0);

    if (oldRefcnt & SIDE_TABLE_RC_PINNED) return true;

    uintptr_t carry;
    size_t newRefcnt = 
        addc(oldRefcnt, delta_rc << SIDE_TABLE_RC_SHIFT, 0, &carry);
    if (carry) {
        refcntStorage =
            SIDE_TABLE_RC_PINNED | (oldRefcnt & SIDE_TABLE_FLAG_MASK);
        return true;
    }
    else {
        refcntStorage = newRefcnt;
        return false;
    }
}


// Move some retain counts from the side table to the isa field.
// Returns the actual count subtracted, which may be less than the request.
size_t 
objc_object::sidetable_subExtraRC_nolock(size_t delta_rc)
{
    assert(isa.nonpointer);
    SideTable& table = SideTables()[this];

    RefcountMap::iterator it = table.refcnts.find(this);
    if (it == table.refcnts.end()  ||  it->second == 0) {
        // Side table retain count is zero. Can't borrow.
        return 0;
    }
    size_t oldRefcnt = it->second;

    // isa-side bits should not be set here
    assert((oldRefcnt & SIDE_TABLE_DEALLOCATING) == 0);
    assert((oldRefcnt & SIDE_TABLE_WEAKLY_REFERENCED) == 0);

    size_t newRefcnt = oldRefcnt - (delta_rc << SIDE_TABLE_RC_SHIFT);
    assert(oldRefcnt > newRefcnt);  // shouldn't underflow
    it->second = newRefcnt;
    return delta_rc;
}

// 从sideTable的引用计数表中获取引用计数
size_t 
objc_object::sidetable_getExtraRC_nolock()
{
    assert(isa.nonpointer);
    SideTable& table = SideTables()[this];
    RefcountMap::iterator it = table.refcnts.find(this);
    if (it == table.refcnts.end()) return 0;
    else return it->second >> SIDE_TABLE_RC_SHIFT;  //#define SIDE_TABLE_RC_SHIFT 2
}


// SUPPORT_NONPOINTER_ISA
#endif


id
objc_object::sidetable_retain()
{
#if SUPPORT_NONPOINTER_ISA
    assert(!isa.nonpointer);
#endif
    SideTable& table = SideTables()[this];
    
    table.lock();
    size_t& refcntStorage = table.refcnts[this];
    if (! (refcntStorage & SIDE_TABLE_RC_PINNED)) {
        refcntStorage += SIDE_TABLE_RC_ONE;
    }
    table.unlock();

    return (id)this;
}


bool
objc_object::sidetable_tryRetain()
{
#if SUPPORT_NONPOINTER_ISA
    assert(!isa.nonpointer);
#endif
    SideTable& table = SideTables()[this];

    // NO SPINLOCK HERE
    // _objc_rootTryRetain() is called exclusively by _objc_loadWeak(), 
    // which already acquired the lock on our behalf.

    // fixme can't do this efficiently with os_lock_handoff_s
    // if (table.slock == 0) {
    //     _objc_fatal("Do not call -_tryRetain.");
    // }

    bool result = true;
    RefcountMap::iterator it = table.refcnts.find(this);
    if (it == table.refcnts.end()) {
        table.refcnts[this] = SIDE_TABLE_RC_ONE;
    } else if (it->second & SIDE_TABLE_DEALLOCATING) {
        result = false;
    } else if (! (it->second & SIDE_TABLE_RC_PINNED)) {
        it->second += SIDE_TABLE_RC_ONE;
    }
    
    return result;
}


uintptr_t
objc_object::sidetable_retainCount()
{
    SideTable& table = SideTables()[this];

    size_t refcnt_result = 1;
    
    table.lock();
    RefcountMap::iterator it = table.refcnts.find(this);
    if (it != table.refcnts.end()) {
        // this is valid for SIDE_TABLE_RC_PINNED too
        refcnt_result += it->second >> SIDE_TABLE_RC_SHIFT;
    }
    table.unlock();
    return refcnt_result;
}


bool 
objc_object::sidetable_isDeallocating()
{
    SideTable& table = SideTables()[this];

    // NO SPINLOCK HERE
    // _objc_rootIsDeallocating() is called exclusively by _objc_storeWeak(), 
    // which already acquired the lock on our behalf.


    // fixme can't do this efficiently with os_lock_handoff_s
    // if (table.slock == 0) {
    //     _objc_fatal("Do not call -_isDeallocating.");
    // }

    RefcountMap::iterator it = table.refcnts.find(this);
    return (it != table.refcnts.end()) && (it->second & SIDE_TABLE_DEALLOCATING);
}


bool 
objc_object::sidetable_isWeaklyReferenced()
{
    bool result = false;

    SideTable& table = SideTables()[this];
    table.lock();

    RefcountMap::iterator it = table.refcnts.find(this);
    if (it != table.refcnts.end()) {
        result = it->second & SIDE_TABLE_WEAKLY_REFERENCED;
    }

    table.unlock();

    return result;
}


void 
objc_object::sidetable_setWeaklyReferenced_nolock()
{
#if SUPPORT_NONPOINTER_ISA
    assert(!isa.nonpointer);
#endif

    SideTable& table = SideTables()[this];

    table.refcnts[this] |= SIDE_TABLE_WEAKLY_REFERENCED;
}


// rdar://20206767
// return uintptr_t instead of bool so that the various raw-isa 
// -release paths all return zero in eax
uintptr_t
objc_object::sidetable_release(bool performDealloc)
{
#if SUPPORT_NONPOINTER_ISA
    assert(!isa.nonpointer);
#endif
    SideTable& table = SideTables()[this];

    bool do_dealloc = false;

    table.lock();
    RefcountMap::iterator it = table.refcnts.find(this);
    if (it == table.refcnts.end()) {
        do_dealloc = true;
        table.refcnts[this] = SIDE_TABLE_DEALLOCATING;
    } else if (it->second < SIDE_TABLE_DEALLOCATING) {
        // SIDE_TABLE_WEAKLY_REFERENCED may be set. Don't change it.
        do_dealloc = true;
        it->second |= SIDE_TABLE_DEALLOCATING;
    } else if (! (it->second & SIDE_TABLE_RC_PINNED)) {
        it->second -= SIDE_TABLE_RC_ONE;
    }
    table.unlock();
    if (do_dealloc  &&  performDealloc) {
        ((void(*)(objc_object *, SEL))objc_msgSend)(this, SEL_dealloc);
    }
    return do_dealloc;
}

//MARK: ⚠️dealloc销毁对象第6⃣️.1⃣️步 isa指针没有被优化过
void 
objc_object::sidetable_clearDeallocating()
{
    SideTable& table = SideTables()[this];  //拿到对象的地址通过hash算法获取到SideTable

    // clear any weak table items
    // clear extra retain count and deallocating bit
    // (fixme warn or abort if extra retain count == 0 ?)
    table.lock();
    //通过对象拿到引用计数表：OC对象引用计数Map（key为对象，value为引用计数）-引用计数表
    RefcountMap::iterator it = table.refcnts.find(this);
    //遍历引用计数表，
    if (it != table.refcnts.end()) {
        if (it->second & SIDE_TABLE_WEAKLY_REFERENCED) {  //如果有若引用表，则处理
            //对象被销毁的时候处理所有弱引用指针的方法，将指向该对象的弱引用指针置为nil
            weak_clear_no_lock(&table.weak_table, (id)this);
        }
        //从refcnts引用计数表中删除该对象的引用计数
        table.refcnts.erase(it);
    }
    table.unlock();
}


/***********************************************************************
* Optimized retain/release/autorelease entrypoints
**********************************************************************/


#if __OBJC2__

__attribute__((aligned(16)))
id 
objc_retain(id obj)
{
    if (!obj) return obj;
    if (obj->isTaggedPointer()) return obj;
    return obj->retain();
}


__attribute__((aligned(16)))
void 
objc_release(id obj)
{
    if (!obj) return;
    if (obj->isTaggedPointer()) return;
    return obj->release();
}


__attribute__((aligned(16)))
id
objc_autorelease(id obj)
{
    if (!obj) return obj;
    if (obj->isTaggedPointer()) return obj;
    return obj->autorelease();
}


// OBJC2
#else
// not OBJC2


id objc_retain(id obj) { return [obj retain]; }
void objc_release(id obj) { [obj release]; }
id objc_autorelease(id obj) { return [obj autorelease]; }


#endif


/***********************************************************************
* Basic operations for root class implementations a.k.a. _objc_root*()
**********************************************************************/

bool
_objc_rootTryRetain(id obj) 
{
    assert(obj);

    return obj->rootTryRetain();
}

bool
_objc_rootIsDeallocating(id obj) 
{
    assert(obj);

    return obj->rootIsDeallocating();
}


void 
objc_clear_deallocating(id obj) 
{
    assert(obj);

    if (obj->isTaggedPointer()) return;
    obj->clearDeallocating();
}


bool
_objc_rootReleaseWasZero(id obj)
{
    assert(obj);

    return obj->rootReleaseShouldDealloc();
}


id
_objc_rootAutorelease(id obj)
{
    assert(obj);
    return obj->rootAutorelease();
}

uintptr_t
_objc_rootRetainCount(id obj)
{
    assert(obj);

    return obj->rootRetainCount();
}


id
_objc_rootRetain(id obj)
{
    assert(obj);

    return obj->rootRetain();
}

void
_objc_rootRelease(id obj)
{
    assert(obj);

    obj->rootRelease();
}


id
_objc_rootAllocWithZone(Class cls, malloc_zone_t *zone)
{
    id obj;

#if __OBJC2__
    // allocWithZone under __OBJC2__ ignores the zone parameter
    (void)zone;
    obj = class_createInstance(cls, 0);
#else
    if (!zone) {
        obj = class_createInstance(cls, 0);
    }
    else {
        obj = class_createInstanceFromZone(cls, 0, zone);
    }
#endif

    if (slowpath(!obj)) obj = callBadAllocHandler(cls);
    return obj;
}


// Call [cls alloc] or [cls allocWithZone:nil], with appropriate 
// shortcutting optimizations.
static ALWAYS_INLINE id
callAlloc(Class cls, bool checkNil, bool allocWithZone=false)
{
    if (slowpath(checkNil && !cls)) return nil;

#if __OBJC2__
    if (fastpath(!cls->ISA()->hasCustomAWZ())) {
        // No alloc/allocWithZone implementation. Go straight to the allocator.
        // fixme store hasCustomAWZ in the non-meta class and 
        // add it to canAllocFast's summary
        if (fastpath(cls->canAllocFast())) {
            // No ctors, raw isa, etc. Go straight to the metal.
            bool dtor = cls->hasCxxDtor();
            id obj = (id)calloc(1, cls->bits.fastInstanceSize());
            if (slowpath(!obj)) return callBadAllocHandler(cls);
            obj->initInstanceIsa(cls, dtor);
            return obj;
        }
        else {
            // Has ctor or raw isa or something. Use the slower path.
            id obj = class_createInstance(cls, 0);
            if (slowpath(!obj)) return callBadAllocHandler(cls);
            return obj;
        }
    }
#endif

    // No shortcuts available.
    if (allocWithZone) return [cls allocWithZone:nil];
    return [cls alloc];
}


// Base class implementation of +alloc. cls is not nil.
// Calls [cls allocWithZone:nil].
id
_objc_rootAlloc(Class cls)
{
    return callAlloc(cls, false/*checkNil*/, true/*allocWithZone*/);
}

// Calls [cls alloc].
id
objc_alloc(Class cls)
{
    return callAlloc(cls, true/*checkNil*/, false/*allocWithZone*/);
}

// Calls [cls allocWithZone:nil].
id 
objc_allocWithZone(Class cls)
{
    return callAlloc(cls, true/*checkNil*/, true/*allocWithZone*/);
}


//MARK: ⚠️dealloc销毁对象第2⃣️步
void
_objc_rootDealloc(id obj)
{
    assert(obj);

    obj->rootDealloc();  //⚠️全局搜索rootDealloc()找到对应的方法 objc_object::rootDealloc()
}

void
_objc_rootFinalize(id obj __unused)
{
    assert(obj);
    _objc_fatal("_objc_rootFinalize called with garbage collection off");
}


id
_objc_rootInit(id obj)
{
    // In practice, it will be hard to rely on this function.
    // Many classes do not properly chain -init calls.
    return obj;
}


malloc_zone_t *
_objc_rootZone(id obj)
{
    (void)obj;
#if __OBJC2__
    // allocWithZone under __OBJC2__ ignores the zone parameter
    return malloc_default_zone();
#else
    malloc_zone_t *rval = malloc_zone_from_ptr(obj);
    return rval ? rval : malloc_default_zone();
#endif
}

uintptr_t
_objc_rootHash(id obj)
{
    return (uintptr_t)obj;
}

/*
 ⚠️ 自动释放池底层结构 autoreleasePool
 OC代码转为CPP问价底层结构
 @autoreleasepool {
     NSLog(@"111111");
 }
 
 { __AtAutoreleasePool __autoreleasepool;
     NSLog((NSString *)&__NSConstantStringImpl__var_folders_2g_rblj4zp502n0kd06tng4srph0000gn_T_WGSEntity_9273ec_mi_0);
 }
 
 struct __AtAutoreleasePool {
   __AtAutoreleasePool() {
       atautoreleasepoolobj = objc_autoreleasePoolPush();
   }
   ~__AtAutoreleasePool() {
       objc_autoreleasePoolPop(atautoreleasepoolobj);
   }
   void * atautoreleasepoolobj;  指针
 };
 @autoreleasepool在刚开始时调用的是objc_autoreleasePoolPush()方法，在大括号{结束时调用的是objc_autoreleasePoolPop(atautoreleasepoolobj)方法
 
 1. autoreleasePool自动释放池是以AutoreleasePoolPage为节点的双向链表结构
 
 */
//MARK: ⚠️autoreleasePool自动释放池第1⃣️步
void *
objc_autoreleasePoolPush(void)
{
    return AutoreleasePoolPage::push();
}

//⚠️autoreleasePool自动释放池第7⃣️步 ctxt就是当前page存放autorelease对象的栈顶地址，每次push后，就会返回这个地址
void
objc_autoreleasePoolPop(void *ctxt)
{
    AutoreleasePoolPage::pop(ctxt);
}


void *
_objc_autoreleasePoolPush(void)
{
    return objc_autoreleasePoolPush();
}

void
_objc_autoreleasePoolPop(void *ctxt)
{
    objc_autoreleasePoolPop(ctxt);
}

void 
_objc_autoreleasePoolPrint(void)
{
    AutoreleasePoolPage::printAll();
}


// Same as objc_release but suitable for tail-calling 
// if you need the value back and don't want to push a frame before this point.
__attribute__((noinline))
static id 
objc_releaseAndReturn(id obj)
{
    objc_release(obj);
    return obj;
}

// Same as objc_retainAutorelease but suitable for tail-calling 
// if you don't want to push a frame before this point.
__attribute__((noinline))
static id 
objc_retainAutoreleaseAndReturn(id obj)
{
    return objc_retainAutorelease(obj);
}


// Prepare a value at +1 for return through a +0 autoreleasing convention.
id 
objc_autoreleaseReturnValue(id obj)
{
    if (prepareOptimizedReturn(ReturnAtPlus1)) return obj;

    return objc_autorelease(obj);
}

// Prepare a value at +0 for return through a +0 autoreleasing convention.
id 
objc_retainAutoreleaseReturnValue(id obj)
{
    if (prepareOptimizedReturn(ReturnAtPlus0)) return obj;

    // not objc_autoreleaseReturnValue(objc_retain(obj)) 
    // because we don't need another optimization attempt
    return objc_retainAutoreleaseAndReturn(obj);
}

// Accept a value returned through a +0 autoreleasing convention for use at +1.
id
objc_retainAutoreleasedReturnValue(id obj)
{
    if (acceptOptimizedReturn() == ReturnAtPlus1) return obj;

    return objc_retain(obj);
}

// Accept a value returned through a +0 autoreleasing convention for use at +0.
id
objc_unsafeClaimAutoreleasedReturnValue(id obj)
{
    if (acceptOptimizedReturn() == ReturnAtPlus0) return obj;

    return objc_releaseAndReturn(obj);
}

id
objc_retainAutorelease(id obj)
{
    return objc_autorelease(objc_retain(obj));
}

void
_objc_deallocOnMainThreadHelper(void *context)
{
    id obj = (id)context;
    [obj dealloc];
}

// convert objc_objectptr_t to id, callee must take ownership.
id objc_retainedObject(objc_objectptr_t pointer) { return (id)pointer; }

// convert objc_objectptr_t to id, without ownership transfer.
id objc_unretainedObject(objc_objectptr_t pointer) { return (id)pointer; }

// convert id to objc_objectptr_t, no ownership transfer.
objc_objectptr_t objc_unretainedPointer(id object) { return object; }


void arr_init(void) 
{
    AutoreleasePoolPage::init();
    SideTableInit();
}


#if SUPPORT_TAGGED_POINTERS

// Placeholder for old debuggers. When they inspect an 
// extended tagged pointer object they will see this isa.

@interface __NSUnrecognizedTaggedPointer : NSObject
@end

@implementation __NSUnrecognizedTaggedPointer
+(void) load { } 
-(id) retain { return self; }
-(oneway void) release { }
-(id) autorelease { return self; }
@end

#endif


@implementation NSObject

+ (void)load {
}

+ (void)initialize {
}

+ (id)self {
    return (id)self;
}

- (id)self {
    return self;
}

+ (Class)class {
    return self;
}

/*
 若是对象：则为类对象
 若是类对象，则为元类对象
 */
- (Class)class {
    return object_getClass(self);
}

+ (Class)superclass {
    return self->superclass;
}

- (Class)superclass {
    return [self class]->superclass;
}

+ (BOOL)isMemberOfClass:(Class)cls {
    return object_getClass((id)self) == cls;
}

- (BOOL)isMemberOfClass:(Class)cls {
    return [self class] == cls;
}

+ (BOOL)isKindOfClass:(Class)cls {
    for (Class tcls = object_getClass((id)self); tcls; tcls = tcls->superclass) {
        if (tcls == cls) return YES;
    }
    return NO;
}

- (BOOL)isKindOfClass:(Class)cls {
    for (Class tcls = [self class]; tcls; tcls = tcls->superclass) {
        if (tcls == cls) return YES;
    }
    return NO;
}

+ (BOOL)isSubclassOfClass:(Class)cls {
    for (Class tcls = self; tcls; tcls = tcls->superclass) {
        if (tcls == cls) return YES;
    }
    return NO;
}

+ (BOOL)isAncestorOfObject:(NSObject *)obj {
    for (Class tcls = [obj class]; tcls; tcls = tcls->superclass) {
        if (tcls == self) return YES;
    }
    return NO;
}

+ (BOOL)instancesRespondToSelector:(SEL)sel {
    if (!sel) return NO;
    return class_respondsToSelector(self, sel);
}

+ (BOOL)respondsToSelector:(SEL)sel {
    if (!sel) return NO;
    return class_respondsToSelector_inst(object_getClass(self), sel, self);
}

- (BOOL)respondsToSelector:(SEL)sel {
    if (!sel) return NO;
    return class_respondsToSelector_inst([self class], sel, self);
}

+ (BOOL)conformsToProtocol:(Protocol *)protocol {
    if (!protocol) return NO;
    for (Class tcls = self; tcls; tcls = tcls->superclass) {
        if (class_conformsToProtocol(tcls, protocol)) return YES;
    }
    return NO;
}

- (BOOL)conformsToProtocol:(Protocol *)protocol {
    if (!protocol) return NO;
    for (Class tcls = [self class]; tcls; tcls = tcls->superclass) {
        if (class_conformsToProtocol(tcls, protocol)) return YES;
    }
    return NO;
}

+ (NSUInteger)hash {
    return _objc_rootHash(self);
}

- (NSUInteger)hash {
    return _objc_rootHash(self);
}

+ (BOOL)isEqual:(id)obj {
    return obj == (id)self;
}

- (BOOL)isEqual:(id)obj {
    return obj == self;
}


+ (BOOL)isFault {
    return NO;
}

- (BOOL)isFault {
    return NO;
}

+ (BOOL)isProxy {
    return NO;
}

- (BOOL)isProxy {
    return NO;
}


+ (IMP)instanceMethodForSelector:(SEL)sel {
    if (!sel) [self doesNotRecognizeSelector:sel];
    return class_getMethodImplementation(self, sel);
}

+ (IMP)methodForSelector:(SEL)sel {
    if (!sel) [self doesNotRecognizeSelector:sel];
    return object_getMethodImplementation((id)self, sel);
}

- (IMP)methodForSelector:(SEL)sel {
    if (!sel) [self doesNotRecognizeSelector:sel];
    return object_getMethodImplementation(self, sel);
}

+ (BOOL)resolveClassMethod:(SEL)sel {
    return NO;
}

+ (BOOL)resolveInstanceMethod:(SEL)sel {
    return NO;
}

// Replaced by CF (throws an NSException)
+ (void)doesNotRecognizeSelector:(SEL)sel {
    _objc_fatal("+[%s %s]: unrecognized selector sent to instance %p", 
                class_getName(self), sel_getName(sel), self);
}

// Replaced by CF (throws an NSException)
- (void)doesNotRecognizeSelector:(SEL)sel {
    _objc_fatal("-[%s %s]: unrecognized selector sent to instance %p", 
                object_getClassName(self), sel_getName(sel), self);
}


+ (id)performSelector:(SEL)sel {
    if (!sel) [self doesNotRecognizeSelector:sel];
    return ((id(*)(id, SEL))objc_msgSend)((id)self, sel);
}

+ (id)performSelector:(SEL)sel withObject:(id)obj {
    if (!sel) [self doesNotRecognizeSelector:sel];
    return ((id(*)(id, SEL, id))objc_msgSend)((id)self, sel, obj);
}

+ (id)performSelector:(SEL)sel withObject:(id)obj1 withObject:(id)obj2 {
    if (!sel) [self doesNotRecognizeSelector:sel];
    return ((id(*)(id, SEL, id, id))objc_msgSend)((id)self, sel, obj1, obj2);
}

- (id)performSelector:(SEL)sel {
    if (!sel) [self doesNotRecognizeSelector:sel];
    return ((id(*)(id, SEL))objc_msgSend)(self, sel);
}

- (id)performSelector:(SEL)sel withObject:(id)obj {
    if (!sel) [self doesNotRecognizeSelector:sel];
    return ((id(*)(id, SEL, id))objc_msgSend)(self, sel, obj);
}

- (id)performSelector:(SEL)sel withObject:(id)obj1 withObject:(id)obj2 {
    if (!sel) [self doesNotRecognizeSelector:sel];
    return ((id(*)(id, SEL, id, id))objc_msgSend)(self, sel, obj1, obj2);
}


// Replaced by CF (returns an NSMethodSignature)
+ (NSMethodSignature *)instanceMethodSignatureForSelector:(SEL)sel {
    _objc_fatal("+[NSObject instanceMethodSignatureForSelector:] "
                "not available without CoreFoundation");
}

// Replaced by CF (returns an NSMethodSignature)
+ (NSMethodSignature *)methodSignatureForSelector:(SEL)sel {
    _objc_fatal("+[NSObject methodSignatureForSelector:] "
                "not available without CoreFoundation");
}

// Replaced by CF (returns an NSMethodSignature)
- (NSMethodSignature *)methodSignatureForSelector:(SEL)sel {
    _objc_fatal("-[NSObject methodSignatureForSelector:] "
                "not available without CoreFoundation");
}

+ (void)forwardInvocation:(NSInvocation *)invocation {
    [self doesNotRecognizeSelector:(invocation ? [invocation selector] : 0)];
}

- (void)forwardInvocation:(NSInvocation *)invocation {
    [self doesNotRecognizeSelector:(invocation ? [invocation selector] : 0)];
}

+ (id)forwardingTargetForSelector:(SEL)sel {
    return nil;
}

- (id)forwardingTargetForSelector:(SEL)sel {
    return nil;
}


// Replaced by CF (returns an NSString)
+ (NSString *)description {
    return nil;
}

// Replaced by CF (returns an NSString)
- (NSString *)description {
    return nil;
}

+ (NSString *)debugDescription {
    return [self description];
}

- (NSString *)debugDescription {
    return [self description];
}


+ (id)new {
    return [callAlloc(self, false/*checkNil*/) init];
}

+ (id)retain {
    return (id)self;
}

// Replaced by ObjectAlloc
- (id)retain {
    return ((id)self)->rootRetain();
}


+ (BOOL)_tryRetain {
    return YES;
}

// Replaced by ObjectAlloc
- (BOOL)_tryRetain {
    return ((id)self)->rootTryRetain();
}

+ (BOOL)_isDeallocating {
    return NO;
}

- (BOOL)_isDeallocating {
    return ((id)self)->rootIsDeallocating();
}

+ (BOOL)allowsWeakReference { 
    return YES; 
}

+ (BOOL)retainWeakReference { 
    return YES; 
}

- (BOOL)allowsWeakReference { 
    return ! [self _isDeallocating]; 
}

- (BOOL)retainWeakReference { 
    return [self _tryRetain]; 
}

+ (oneway void)release {
}

// Replaced by ObjectAlloc
- (oneway void)release {
    ((id)self)->rootRelease();
}

+ (id)autorelease {
    return (id)self;
}

// Replaced by ObjectAlloc
- (id)autorelease {
    return ((id)self)->rootAutorelease();
}

+ (NSUInteger)retainCount {
    return ULONG_MAX;
}

//MARK: ⚠️获取对象的引用计数 第1⃣️步
- (NSUInteger)retainCount {
    return ((id)self)->rootRetainCount();
}

+ (id)alloc {
    return _objc_rootAlloc(self);
}

// Replaced by ObjectAlloc
+ (id)allocWithZone:(struct _NSZone *)zone {
    return _objc_rootAllocWithZone(self, (malloc_zone_t *)zone);
}

// Replaced by CF (throws an NSException)
+ (id)init {
    return (id)self;
}

- (id)init {
    return _objc_rootInit(self);
}

// Replaced by CF (throws an NSException)
+ (void)dealloc {
}


/*
 ⚠️dealloc执行流程 调用dealloc方法的执行流程
 1. 调用dealloc方法，首先会调用_objc_rootDealloc方法
 2. 在_objc_rootDealloc方法中，会调用rootDealloc方法，在该方法中判断对象是否是TaggedPointer，若是则直接返回不做处理；因为TaggedPointer并不是真正的OC对象，不涉及到内存管理的东西；然后判断对象【1.是否优化过isa2.是否存在弱引用指向3.是否设置过关联对象4.是否有cpp的析构函数5.引用计数器是否过大无法存储在isa中】是否满足上面这5种情况，若满足则直接调用free方法快速释放对象；若不满足条件，则继续调用object_dispose方法
 3. object_dispose方法中，会再调用objc_destructInstance方法，objc_destructInstance方法里面会判断【1.有析构函数就清除2.有关联对象就移除】，然后再调用clearDeallocating方法
 4.在clearDeallocating方法中，判断【isa是否优化过】，arm64架构后都做了优化处理，但若没有优化处理会调用sidetable_clearDeallocating；若优化处理过了，则判断【是否有弱引用或者引用计数】，若有则调用clearDeallocating_slow方法进行慢释放过程
 5. 在clearDeallocating_slow方法中，【1.若有弱引用表，则会将指向该对象的弱引用指针置全部置为nil；2.若有引用计数表，从引用计数表中擦除该对象的引用计数。】
 6. 至此dealloc方法执行流程完成
 */
//MARK: OC中dealloc方法底层调用顺序及流程

// Replaced by NSZombies
//MARK:  ⚠️dealloc销毁对象第1⃣️步
- (void)dealloc {
    _objc_rootDealloc(self);
}

// Previously used by GC. Now a placeholder for binary compatibility.
- (void) finalize {
}

+ (struct _NSZone *)zone {
    return (struct _NSZone *)_objc_rootZone(self);
}

- (struct _NSZone *)zone {
    return (struct _NSZone *)_objc_rootZone(self);
}

+ (id)copy {
    return (id)self;
}

+ (id)copyWithZone:(struct _NSZone *)zone {
    return (id)self;
}

- (id)copy {
    return [(id)self copyWithZone:nil];
}

+ (id)mutableCopy {
    return (id)self;
}

+ (id)mutableCopyWithZone:(struct _NSZone *)zone {
    return (id)self;
}

- (id)mutableCopy {
    return [(id)self mutableCopyWithZone:nil];
}

@end


