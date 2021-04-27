//===--- Mutex.cpp - Mutex support code -----------------------------------===//
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

// Include the runtime's mutex support code.
// FIXME: figure out some reasonable way to share this stuff

#include "../runtime/MutexPThread.cpp"
#include "../runtime/MutexWin32.cpp"

SWIFT_NORETURN void swift::fatalError(uint32_t flags, const char *format, ...) {
  abort();
}
