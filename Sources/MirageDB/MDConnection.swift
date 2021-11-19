//
//  MDConnection.swift
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

public class MDConnection {
    
    let connection: DBConnection
    
    init(connection: DBConnection) {
        
        self.connection = connection
        
        if let connection = connection as? DBSQLConnection {
            connection.primaryKeyHook = { connection, _ in connection.eventLoopGroup.next().makeSucceededFuture(["id"]) }
        }
    }
}

extension MDConnection {
    
    public var eventLoopGroup: EventLoopGroup {
        return connection.eventLoopGroup
    }
}

extension MDConnection {
    
    public var isClosed: Bool {
        return connection.isClosed
    }
    
    public func close() -> EventLoopFuture<Void> {
        return connection.close()
    }
}

extension MDConnection {
    
    public func version() -> EventLoopFuture<String> {
        return connection.version()
    }
    
    public func databases() -> EventLoopFuture<[String]> {
        return connection.databases()
    }
    
    public func tables() -> EventLoopFuture<[String]> {
        return self.driver.tables(self)
    }
}

extension MDConnection {
    
    public static func connect(
        config: Database.Configuration,
        logger: Logger = .init(label: "com.TheOddmen.MDDB"),
        driver: DBDriver,
        on eventLoopGroup: EventLoopGroup
    ) -> EventLoopFuture<MDConnection> {
        
        return Database.connect(config: config, logger: logger, driver: driver, on: eventLoopGroup).map(MDConnection.init)
    }
    
    public static func connect(
        url: URL,
        logger: Logger = .init(label: "com.TheOddmen.MDDB"),
        on eventLoopGroup: EventLoopGroup
    ) -> EventLoopFuture<MDConnection> {
        
        return Database.connect(url: url, logger: logger, on: eventLoopGroup).map(MDConnection.init)
    }
    
    public static func connect(
        url: URLComponents,
        logger: Logger = .init(label: "com.TheOddmen.MDDB"),
        on eventLoopGroup: EventLoopGroup
    ) -> EventLoopFuture<MDConnection> {
        
        return Database.connect(url: url, logger: logger, on: eventLoopGroup).map(MDConnection.init)
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
    
    public func withTransaction<T>(_ transactionBody: @escaping (MDConnection) throws -> EventLoopFuture<T>) -> EventLoopFuture<T> {
        return self.driver.withTransaction(self) { try transactionBody(self) }
    }
}

extension MDConnection {
    
    public func createTable(_ table: MDSQLTable) -> EventLoopFuture<Void> {
        switch self.driver {
        case let driver as MDSQLDriver: return driver.createTable(self, table)
        default: return self.eventLoopGroup.next().makeSucceededVoidFuture()
        }
    }
    
    public func dropTable(_ table: String) -> EventLoopFuture<Void> {
        switch self.driver {
        case let driver as MDSQLDriver: return driver.dropTable(self, table)
        case let driver as MongoDBDriver: return driver.dropTable(self, table)
        default: return self.eventLoopGroup.next().makeSucceededVoidFuture()
        }
    }
    
    public func addColumns(_ table: String, _ columns: [MDSQLTableColumn]) -> EventLoopFuture<Void> {
        switch self.driver {
        case let driver as MDSQLDriver: return driver.addColumns(self, table, columns)
        default: return self.eventLoopGroup.next().makeSucceededVoidFuture()
        }
    }
    
    public func dropColumns(_ table: String, _ columns: [String]) -> EventLoopFuture<Void> {
        switch self.driver {
        case let driver as MDSQLDriver: return driver.dropColumns(self, table, columns)
        case let driver as MongoDBDriver: return driver.dropColumns(self, table, columns)
        default: return self.eventLoopGroup.next().makeSucceededVoidFuture()
        }
    }
    
    public func addIndex(_ table: String, _ index: MDSQLTableIndex) -> EventLoopFuture<Void> {
        switch self.driver {
        case let driver as MDSQLDriver: return driver.addIndex(self, table, index)
        case let driver as MongoDBDriver: return driver.addIndex(self, table, index)
        default: return self.eventLoopGroup.next().makeSucceededVoidFuture()
        }
    }
    
    public func dropIndex(_ table: String, _ index: String) -> EventLoopFuture<Void> {
        switch self.driver {
        case let driver as MDSQLDriver: return driver.dropIndex(self, table, index)
        case let driver as MongoDBDriver: return driver.dropIndex(self, table, index)
        default: return self.eventLoopGroup.next().makeSucceededVoidFuture()
        }
    }
}
