//
//  PostgreSQLDriver.swift
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
    
    func _createTable(_ connection: MDConnection, _ table: String, _ columns: [String: MDSQLDataType]) -> EventLoopFuture<Void> {
        
        do {
            
            guard let _connection = connection.connection as? DBSQLConnection else { throw MDError.unknown }
            
            let list: [SQLRaw] = ["id VARCHAR(10) NOT NULL PRIMARY KEY"] + columns.map { "\(identifier: $0.key) \($0.value.postgresType)" }
            
            let sql: SQLRaw = "CREATE TABLE IF NOT EXISTS \(identifier: table) (\(list.joined(separator: ",")))"
            
            return _connection.execute(sql)
                .map { _ in }
                .flatMapError { error in
                    
                    if case let .server(error) = error as? PostgresError {
                        
                        let sqlState = error.fields[.sqlState]
                        let schemaName = error.fields[.schemaName]
                        let tableName = error.fields[.tableName]
                        let constraintName = error.fields[.constraintName]
                        let routine = error.fields[.routine]
                        
                        if sqlState == "23505" &&
                            schemaName == "pg_catalog" &&
                            tableName == "pg_type" &&
                            constraintName == "pg_type_typname_nsp_index" &&
                            routine == "_bt_check_unique" {
                            
                            return self._createTable(connection, table, columns)
                        }
                    }
                    
                    return _connection.eventLoopGroup.next().makeFailedFuture(error)
                }
            
        } catch {
            
            return connection.eventLoopGroup.next().makeFailedFuture(error)
        }
    }
    
    func dropTable(_ connection: MDConnection, _ table: String) -> EventLoopFuture<Void> {
        
        do {
            
            guard let connection = connection.connection as? DBSQLConnection else { throw MDError.unknown }
            
            let sql: SQLRaw = "DROP TABLE IF EXISTS \(identifier: table)"
            
            return connection.execute(sql).map { _ in }
            
        } catch {
            
            return connection.eventLoopGroup.next().makeFailedFuture(error)
        }
    }
    
    func addColumns(_ connection: MDConnection, _ table: String, _ columns: [String: MDSQLDataType]) -> EventLoopFuture<Void> {
        
        do {
            
            guard let connection = connection.connection as? DBSQLConnection else { throw MDError.unknown }
            
            let list: [SQLRaw] = columns.map { "ADD COLUMN IF NOT EXISTS \(identifier: $0.key) \($0.value.postgresType)" }
            
            let sql: SQLRaw = "ALTER TABLE IF EXISTS \(identifier: table) \(list.joined(separator: ","))"
            
            return connection.execute(sql).map { _ in }
            
        } catch {
            
            return connection.eventLoopGroup.next().makeFailedFuture(error)
        }
    }
    
    func dropColumns(_ connection: MDConnection, _ table: String, _ columns: Set<String>) -> EventLoopFuture<Void> {
        
        do {
            
            guard let connection = connection.connection as? DBSQLConnection else { throw MDError.unknown }
            
            let list: [SQLRaw] = columns.map { "DROP COLUMN IF EXISTS \(identifier: $0)" }
            
            let sql: SQLRaw = "ALTER TABLE IF EXISTS \(identifier: table) \(list.joined(separator: ","))"
            
            return connection.execute(sql).map { _ in }
            
        } catch {
            
            return connection.eventLoopGroup.next().makeFailedFuture(error)
        }
    }
    
    func addIndex(_ connection: MDConnection, _ table: String, _ index: MDSQLTableIndex) -> EventLoopFuture<Void> {
        
        do {
            
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
            
            return connection.execute(sql).map { _ in }
            
        } catch {
            
            return connection.eventLoopGroup.next().makeFailedFuture(error)
        }
    }
    
    func dropIndex(_ connection: MDConnection, _ table: String, _ index: String) -> EventLoopFuture<Void> {
        
        do {
            
            guard let connection = connection.connection as? DBSQLConnection else { throw MDError.unknown }
            
            let sql: SQLRaw = "DROP INDEX IF EXISTS \(identifier: index)"
            
            return connection.execute(sql).map { _ in }
            
        } catch {
            
            return connection.eventLoopGroup.next().makeFailedFuture(error)
        }
    }
}
