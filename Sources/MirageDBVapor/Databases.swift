//
//  Databases.swift
//
//  The MIT License
//  Copyright (c) 2021 - 2022 O2ter Limited. All rights reserved.
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

public struct DatabaseID: Hashable, Codable {
    
    public let string: String
    
    public init(string: String) {
        self.string = string
    }
}

extension DatabaseID: ExpressibleByStringLiteral {
    
    public init(stringLiteral value: StringLiteralType) {
        self.init(string: value)
    }
}

public class DatabasePool {
    
    let logger: Logger
    
    let eventLoopGroup: EventLoopGroup
    
    let connection: EventLoopFuture<MDConnection>?
    
    let pool: EventLoopGroupConnectionPool<MDConnectionPoolSource>
    
    public init(
        source: MDConnectionSource,
        maxConnectionsPerEventLoop: Int,
        requestTimeout: TimeAmount,
        logger: Logger,
        on eventLoopGroup: EventLoopGroup
    ) {
        
        self.logger = logger
        self.eventLoopGroup = eventLoopGroup
        
        let _source: MDConnectionPoolSource
        
        if source.driver.isThreadBased {
            
            let promise = eventLoopGroup.next().makePromise(of: MDConnection.self)
            
            promise.completeWithTask {
                
                try await MDConnection.connect(
                    config: source.configuration,
                    logger: logger,
                    driver: source.driver,
                    on: eventLoopGroup)
            }
            
            self.connection = promise.futureResult
            
            _source = MDConnectionPoolSource { _, eventLoop in promise.futureResult.map { $0.bind(to: eventLoop) } }
            
        } else {
            
            self.connection = nil
            
            _source = MDConnectionPoolSource { logger, eventLoop in
                
                let promise = eventLoopGroup.next().makePromise(of: MDConnection.self)
                
                promise.completeWithTask {
                    
                    try await MDConnection.connect(
                        config: source.configuration,
                        logger: logger,
                        driver: source.driver,
                        on: eventLoop)
                }
                
                return promise.futureResult
            }
        }
        
        self.pool = EventLoopGroupConnectionPool(
            source: _source,
            maxConnectionsPerEventLoop: maxConnectionsPerEventLoop,
            requestTimeout: requestTimeout,
            logger: logger,
            on: eventLoopGroup
        )
    }
    
    public func withConnection<Result>(
        _ closure: @escaping (MDConnection) -> EventLoopFuture<Result>
    ) -> EventLoopFuture<Result> {
        return self.pool.withConnection(logger: logger, on: eventLoopGroup.next()) { closure($0.connection) }
    }
    
    public func withConnection<Result>(
        _ closure: @escaping (MDConnection) async throws -> Result
    ) async throws -> Result {
        
        return try await self.withConnection { connection in
            
            let promise = connection.eventLoopGroup.next().makePromise(of: Result.self)
            
            promise.completeWithTask{ try await closure(connection) }
            
            return promise.futureResult
            
        }.get()
    }
    
    func shutdown() {
        Task {
            if let connection = try await self.connection?.get() {
                try await connection.close()
            }
            self.pool.shutdown()
        }
    }
}

public class Databases {
    
    public let eventLoopGroup: EventLoopGroup
    public let threadPool: NIOThreadPool
    public let logger: Logger
    
    private var configurations: [DatabaseID: MDConnectionSource]
    private var defaultID: DatabaseID?
    
    private var pools: [DatabaseID: DatabasePool]
    
    private var lock: Lock
    
    public init(threadPool: NIOThreadPool, logger: Logger, on eventLoopGroup: EventLoopGroup) {
        self.eventLoopGroup = eventLoopGroup
        self.threadPool = threadPool
        self.logger = logger
        self.configurations = [:]
        self.pools = [:]
        self.lock = .init()
    }
}

extension Databases {
    
    private func _requireConfiguration(for id: DatabaseID) -> MDConnectionSource {
        guard let configuration = self.configurations[id] else {
            fatalError("No datatabase configuration registered for \(id).")
        }
        return configuration
    }
    
    private func _requireDefaultID() -> DatabaseID {
        guard let id = self.defaultID else {
            fatalError("No default database configured.")
        }
        return id
    }
}

extension Databases {
    
    public func use(
        _ config: MDConnectionSource,
        as id: DatabaseID,
        isDefault: Bool? = nil
    ) {
        self.lock.lock()
        defer { self.lock.unlock() }
        
        self.configurations[id] = config
        
        if isDefault == true || (self.defaultID == nil && isDefault != false) {
            self.defaultID = id
        }
    }
    
    public func `default`(to id: DatabaseID) {
        self.lock.lock()
        defer { self.lock.unlock() }
        self.defaultID = id
    }
    
    public func configuration(for id: DatabaseID? = nil) -> MDConnectionSource? {
        self.lock.lock()
        defer { self.lock.unlock() }
        return self.configurations[id ?? self._requireDefaultID()]
    }
    
    public func ids() -> Set<DatabaseID> {
        return self.lock.withLock { Set(self.configurations.keys) }
    }
    
    func shutdown() {
        self.lock.lock()
        defer { self.lock.unlock() }
        for driver in self.pools.values {
            driver.shutdown()
        }
        self.pools = [:]
    }
}

extension Databases {
    
    public func database(_ id: DatabaseID? = nil) -> DatabasePool {
        
        self.lock.lock()
        defer { self.lock.unlock() }
        
        let id = id ?? self._requireDefaultID()
        let configuration = self._requireConfiguration(for: id)
        
        var logger = self.logger
        logger[metadataKey: "database-id"] = .string(id.string)
        
        if let existing = self.pools[id] {
            return existing
        }
        
        let pool = DatabasePool(
            source: configuration,
            maxConnectionsPerEventLoop: configuration.maxConnectionsPerEventLoop,
            requestTimeout: configuration.requestTimeout,
            logger: logger,
            on: eventLoopGroup
        )
        self.pools[id] = pool
        
        return pool
    }
}
