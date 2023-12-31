//
//  PostgreSQLDriver.swift
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

import PostgresNIO

struct PostgreSQLDriver: MDSQLDriver {
    
}

extension MDSQLDataType {
    
    init?(type: String) {
        switch type.uppercased() {
        case "CHARACTER VARYING(10)": self = .id
        case "BOOLEAN": self = .boolean
        case "TEXT": self = .string
        case "DOUBLE PRECISION": self = .number
        case "NUMERIC": self = .decimal
        case "TIMESTAMP WITHOUT TIME ZONE": self = .timestamp
        case "BYTEA": self = .binary
        case "JSONB": self = .json
        default: return nil
        }
    }
    
    fileprivate var postgresType: SQLRaw {
        switch self {
        case .id: return "VARCHAR(10)"
        case .boolean: return "BOOLEAN"
        case .string: return "TEXT"
        case .number: return "DOUBLE PRECISION"
        case .decimal: return "NUMERIC"
        case .timestamp: return "TIMESTAMP"
        case .binary: return "BYTEA"
        case .json: return "JSONB"
        }
    }
}

extension PostgreSQLDriver {
    
    func _createTable(_ connection: MDConnection, _ table: String, _ columns: [String: MDSQLDataType]) async throws {
        
        guard let _connection = connection.connection as? DBSQLConnection else { throw MDError.unknown }
        
        let list: [SQLRaw] = ["_id VARCHAR(10) NOT NULL PRIMARY KEY"] + columns.map { "\(identifier: $0.key) \($0.value.postgresType)" }
        
        let sql: SQLRaw = "CREATE TABLE IF NOT EXISTS \(identifier: table) (\(list.joined(separator: ",")))"
        
        do {
            
            try await _connection.execute(sql)
            
        } catch let error as PostgresError {
            
            if case let .server(error) = error {
                
                let sqlState = error.fields[.sqlState] == "23505"
                let schemaName = error.fields[.schemaName] == "pg_catalog"
                let tableName = error.fields[.tableName] == "pg_type"
                let constraintName = error.fields[.constraintName] == "pg_type_typname_nsp_index"
                let routine = error.fields[.routine] == "_bt_check_unique"
                
                if sqlState && schemaName && tableName && constraintName && routine {
                    return try await self._createTable(connection, table, columns)
                }
            }
            
            throw error
        }
    }
    
    func dropTable(_ connection: MDConnection, _ table: String) async throws {
        
        guard let connection = connection.connection as? DBSQLConnection else { throw MDError.unknown }
        
        let sql: SQLRaw = "DROP TABLE IF EXISTS \(identifier: table)"
        
        try await connection.execute(sql)
    }
    
    func addColumns(_ connection: MDConnection, _ table: String, _ columns: [String: MDSQLDataType]) async throws {
        
        guard let connection = connection.connection as? DBSQLConnection else { throw MDError.unknown }
        
        let list: [SQLRaw] = columns.map { "ADD COLUMN IF NOT EXISTS \(identifier: $0.key) \($0.value.postgresType)" }
        
        let sql: SQLRaw = "ALTER TABLE IF EXISTS \(identifier: table) \(list.joined(separator: ","))"
        
        try await connection.execute(sql)
    }
    
    func dropColumns(_ connection: MDConnection, _ table: String, _ columns: Set<String>) async throws {
        
        guard let connection = connection.connection as? DBSQLConnection else { throw MDError.unknown }
        
        let list: [SQLRaw] = columns.map { "DROP COLUMN IF EXISTS \(identifier: $0)" }
        
        let sql: SQLRaw = "ALTER TABLE IF EXISTS \(identifier: table) \(list.joined(separator: ","))"
        
        try await connection.execute(sql)
    }
    
    func addIndex(_ connection: MDConnection, _ table: String, _ index: MDSQLTableIndex) async throws {
        
        guard let connection = connection.connection as? DBSQLConnection else { throw MDError.unknown }
        
        var list: [SQLRaw] = []
        
        for (key, option) in index.columns {
            switch option {
            case .ascending: list.append("\(identifier: key) ASC")
            case .descending: list.append("\(identifier: key) DESC")
            }
        }
        
        let sql: SQLRaw
        
        if index.isUnique {
            sql = "CREATE UNIQUE INDEX IF NOT EXISTS \(identifier: index.name) ON \(identifier: table) (\(list.joined(separator: ",")))"
        } else {
            sql = "CREATE INDEX IF NOT EXISTS \(identifier: index.name) ON \(identifier: table) (\(list.joined(separator: ",")))"
        }
        
        try await connection.execute(sql)
    }
    
    func dropIndex(_ connection: MDConnection, _ table: String, _ index: String) async throws {
        
        guard let connection = connection.connection as? DBSQLConnection else { throw MDError.unknown }
        
        let sql: SQLRaw = "DROP INDEX IF EXISTS \(identifier: index)"
        
        try await connection.execute(sql)
    }
    
    func withTransaction<T>(
        _ connection: MDConnection,
        _ options: MDTransactionOptions,
        _ transactionBody: @escaping (MDConnection) async throws -> T
    ) async throws -> T {
        
        guard let connection = connection.connection as? DBSQLConnection else { throw MDError.unknown }
        
        return try await connection.withTransaction(.init(options)) { try await transactionBody(MDConnection(connection: $0)) }
    }
    
}
