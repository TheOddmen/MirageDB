//
//  Databases.swift
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
    
    let connection: EventLoopFuture<MDConnection>?
    
    let pool: EventLoopGroupConnectionPool<MDConnectionPoolSource>
    
    public init(
        source: MDConnectionSource,
        maxConnectionsPerEventLoop: Int,
        requestTimeout: TimeAmount,
        logger: Logger,
        on eventLoopGroup: EventLoopGroup
    ) {
        
        if source.driver.isThreadBased {
            
            let connection = MDConnection.connect(
                config: source.configuration,
                logger: logger,
                driver: source.driver,
                on: eventLoopGroup)
            
            self.connection = connection
            
            self.pool = EventLoopGroupConnectionPool(
                source: MDConnectionPoolSource(generator: { _, eventLoop in
                    connection.map { $0.bind(to: eventLoop)  }
                }),
                maxConnectionsPerEventLoop: maxConnectionsPerEventLoop,
                requestTimeout: requestTimeout,
                logger: logger,
                on: eventLoopGroup
            )
            
        } else {
            
            self.connection = nil
            
            self.pool = EventLoopGroupConnectionPool(
                source: MDConnectionPoolSource(generator: { logger, eventLoop in
                    MDConnection.connect(
                        config: source.configuration,
                        logger: logger,
                        driver: source.driver,
                        on: eventLoop)
                }),
                maxConnectionsPerEventLoop: maxConnectionsPerEventLoop,
                requestTimeout: requestTimeout,
                logger: logger,
                on: eventLoopGroup
            )
        }
    }
    
    public func withConnection<Result>(
        _ closure: @escaping (MDConnection) -> EventLoopFuture<Result>
    ) -> EventLoopFuture<Result> {
        return self.pool.withConnection { closure($0.connection) }
    }
    
    func shutdown() {
        if let connection = self.connection {
            connection.flatMap { $0.close() }.whenComplete { _ in self.pool.shutdown() }
        } else {
            pool.shutdown()
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
    
    public func shutdown() {
        self.lock.lock()
        defer { self.lock.unlock() }
        print("shutdown")
        for driver in self.pools.values {
            driver.shutdown()
        }
        self.pools = [:]
    }
}

extension Databases {
    
    public func database(
        _ id: DatabaseID? = nil,
        logger: Logger,
        on eventLoopGroup: EventLoopGroup
    ) -> DatabasePool {
        
        self.lock.lock()
        defer { self.lock.unlock() }
        
        let id = id ?? self._requireDefaultID()
        let configuration = self._requireConfiguration(for: id)
        
        var logger = logger
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
