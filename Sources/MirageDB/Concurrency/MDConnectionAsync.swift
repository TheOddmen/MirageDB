//
//  MDConnectionAsync.swift
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

#if compiler(>=5.5.2) && canImport(_Concurrency)

@available(macOS 10.15, iOS 13, tvOS 13, watchOS 6, *)
extension MDConnection {
    
    public static func connect(
        config: Database.Configuration,
        logger: Logger = .init(label: "com.TheOddmen.MirageDB"),
        driver: DBDriver,
        on eventLoopGroup: EventLoopGroup
    ) async throws -> MDConnection {
        
        return try await self.connect(config: config, logger: logger, driver: driver, on: eventLoopGroup).get()
    }
    
    public static func connect(
        url: URL,
        logger: Logger = .init(label: "com.TheOddmen.MirageDB"),
        on eventLoopGroup: EventLoopGroup
    ) async throws -> MDConnection {
        
        return try await self.connect(url: url, logger: logger, on: eventLoopGroup).get()
    }
    
    public static func connect(
        url: URLComponents,
        logger: Logger = .init(label: "com.TheOddmen.MirageDB"),
        on eventLoopGroup: EventLoopGroup
    ) async throws -> MDConnection {
        
        return try await self.connect(url: url, logger: logger, on: eventLoopGroup).get()
    }
}

@available(macOS 10.15, iOS 13, tvOS 13, watchOS 6, *)
extension MDConnection {
    
    public func close() async throws {
        try await self.close().get()
    }
    
    public func version() async throws -> String {
        return try await self.version().get()
    }
    
    public func databases() async throws -> [String] {
        return try await self.databases().get()
    }
    
    public func tables() async throws -> [String] {
        return try await self.tables().get()
    }
}

@available(macOS 10.15, iOS 13, tvOS 13, watchOS 6, *)
extension MDConnection {
    
    public func withTransaction<T>(
        _ transactionBody: @escaping (MDConnection) async throws -> T
    ) async throws -> T {
        
        let promise = self.eventLoopGroup.next().makePromise(of: T.self)
        
        return try await self.withTransaction { connection in
            
            promise.completeWithTask { try await transactionBody(connection) }
            
            return promise.futureResult
            
        }.get()
    }
}

@available(macOS 10.15, iOS 13, tvOS 13, watchOS 6, *)
extension MDConnection {
    
    public func createTable(_ table: String, _ columns: [String: MDSQLDataType]) async throws {
        return try await self.createTable(table, columns).get()
    }
    
    public func addColumns(_ table: String, _ columns: [String: MDSQLDataType]) async throws {
        return try await self.addColumns(table, columns).get()
    }
    
    public func dropTable(_ table: String) async throws {
        return try await self.dropTable(table).get()
    }
    
    public func dropColumns(_ table: String, _ columns: Set<String>) async throws {
        return try await self.dropColumns(table, columns).get()
    }
    
    public func addIndex(_ table: String, _ index: MDSQLTableIndex) async throws {
        return try await self.addIndex(table, index).get()
    }
    
    public func dropIndex(_ table: String, _ index: String) async throws {
        return try await self.dropIndex(table, index).get()
    }
}

#endif
