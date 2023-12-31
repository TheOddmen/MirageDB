//
//  MDQuery.swift
//
//  The MIT License
//  Copyright (c) 2021 - 2024 O2ter Limited. All rights reserved.
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

public struct MDQuery: Sendable {
    
    public let connection: MDConnection
    
    init(connection: MDConnection) {
        self.connection = connection
    }
}

extension MDConnection {
    
    public func query() -> MDQuery {
        return MDQuery(connection: self)
    }
}

extension MDQuery {
    
    @discardableResult
    public func insert(_ class: String, _ data: [MDQueryKey: MDData]) async throws -> MDObject {
        return try await self.connection.driver.insert(connection, `class`, data)
    }
}

extension MDQuery {
    
    @discardableResult
    public func insert(_ class: String, _ data: [String: MDData]) async throws -> MDObject {
        return try await self.insert(`class`, Dictionary(data.map { (MDQueryKey(key: $0), $1) }) { _, rhs in rhs })
    }
}

public struct MDTableStats {
    
    public var table: Int
    
    public var indexes: Int
    
    public var total: Int
    
}

extension MDTableStats {
    
    init(_ stats: DBSQLTableStats) {
        self.table = stats.table
        self.indexes = stats.indexes
        self.total = stats.total
    }
}

extension MDQuery {
    
    public func size(of class: String) async throws -> MDTableStats {
        return try await self.connection.driver.stats(connection, `class`)
    }
}
