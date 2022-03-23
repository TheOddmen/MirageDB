//
//  MDConnection.swift
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

public final class MDConnection: Sendable {
    
    let connection: DBConnection
    
    init(connection: DBConnection) {
        
        self.connection = connection
        
        if let connection = connection as? DBSQLConnection {
            Task { await connection.hooks.setPrimaryKeyHook { _, _ in ["_id"] } }
        }
    }
}

extension MDConnection {
    
    public var eventLoopGroup: EventLoopGroup {
        return connection.eventLoopGroup
    }
}

extension MDConnection {
    
    public var logger: Logger {
        return connection.logger
    }
    
    public func bind(to eventLoop: EventLoop) -> MDConnection {
        return MDConnection(connection: connection.bind(to: eventLoop))
    }
    
    public func close() async throws {
        try await connection.close()
    }
}

extension MDConnection {
    
    public func version() async throws -> String {
        return try await connection.version()
    }
    
    public func databases() async throws -> [String] {
        return try await connection.databases()
    }
    
    public func tables() async throws -> [String] {
        return try await self.driver.tables(self)
    }
}

extension MDConnection {
    
    public static func connect(
        config: Database.Configuration,
        logger: Logger = .init(label: "com.o2ter.MirageDB"),
        driver: DBDriver,
        on eventLoopGroup: EventLoopGroup
    ) async throws -> MDConnection {
        
        let connection = try await Database.connect(config: config, logger: logger, driver: driver, on: eventLoopGroup)
        
        return MDConnection(connection: connection)
    }
    
    public static func connect(
        url: URL,
        logger: Logger = .init(label: "com.o2ter.MirageDB"),
        on eventLoopGroup: EventLoopGroup
    ) async throws -> MDConnection {
        
        let connection = try await Database.connect(url: url, logger: logger, on: eventLoopGroup)
        
        return MDConnection(connection: connection)
    }
    
    public static func connect(
        url: URLComponents,
        logger: Logger = .init(label: "com.o2ter.MirageDB"),
        on eventLoopGroup: EventLoopGroup
    ) async throws -> MDConnection {
        
        let connection = try await Database.connect(url: url, logger: logger, on: eventLoopGroup)
        
        return MDConnection(connection: connection)
    }
}

extension MDConnection {
    
    var driver: MDDriver {
        switch connection.driver {
        case .postgreSQL: return PostgreSQLDriver()
        case .mongoDB: return MongoDBDriver()
        default: fatalError("unsupported driver.")
        }
    }
}

extension MDConnection {
    
    public func withTransaction<T>(
        _ transactionBody: @escaping (MDConnection) async throws -> T
    ) async throws -> T {
        return try await self.driver.withTransaction(self) { try await transactionBody($0) }
    }
}

extension MDConnection {
    
    public func createTable(_ table: String, _ columns: [String: MDSQLDataType]) async throws {
        return try await self.driver.createTable(self, table, columns)
    }
    
    public func addColumns(_ table: String, _ columns: [String: MDSQLDataType]) async throws {
        return try await self.driver.addColumns(self, table, columns)
    }
    
    public func dropTable(_ table: String) async throws {
        return try await self.driver.dropTable(self, table)
    }
    
    public func dropColumns(_ table: String, _ columns: Set<String>) async throws {
        return try await self.driver.dropColumns(self, table, columns)
    }
    
    public func addIndex(_ table: String, _ index: MDSQLTableIndex) async throws {
        return try await self.driver.addIndex(self, table, index)
    }
    
    public func dropIndex(_ table: String, _ index: String) async throws {
        return try await self.driver.dropIndex(self, table, index)
    }
}
