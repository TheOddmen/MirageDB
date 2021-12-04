//
//  Application.swift
//
//  The MIT License
//  Copyright (c) 2021 The Oddmen Technology Limited. All rights reserved.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

extension Application {
    
    final class Storage {
        
        let databases: Databases
        
        init(threadPool: NIOThreadPool, logger: Logger, on eventLoopGroup: EventLoopGroup) {
            self.databases = Databases(threadPool: threadPool, logger: logger, on: eventLoopGroup)
        }
    }
    
    struct Key: StorageKey {
        
        typealias Value = Storage
    }
    
    struct Lifecycle: LifecycleHandler {
        
        func shutdown(_ application: Application) {
            application.databases.shutdown()
        }
    }
}

extension Request {
    
    public func database(_ id: DatabaseID? = nil) -> DatabasePool {
        return self.application.database(id)
    }
    
    public var databases: Databases {
        return self.application.databases
    }
}

extension Application {
    
    private var _storage: Storage {
        if self.storage[Key.self] == nil {
            self.storage[Key.self] = Storage(threadPool: self.threadPool, logger: self.logger, on: self.eventLoopGroup)
            self.lifecycle.use(Lifecycle())
        }
        return self.storage[Key.self]!
    }
    
    public func database(_ id: DatabaseID? = nil) -> DatabasePool {
        return self.databases.database(id)
    }
    
    public var databases: Databases {
        return self._storage.databases
    }
}
