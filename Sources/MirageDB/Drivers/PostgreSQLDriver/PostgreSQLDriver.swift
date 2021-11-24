//
//  PostgreSQLDriver.swift
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

struct PostgreSQLDriver: MDSQLDriver {
    
}

extension MDSQLDataType {
    
    fileprivate var postgresType: SQLRaw {
        switch self {
        case .id: return "VARCHAR(10)"
        case .boolean: return "BOOLEAN"
        case .string: return "TEXT"
        case .integer: return "INTEGER"
        case .number: return "DOUBLE PRECISION"
        case .decimal: return "DECIMAL"
        case .timestamp: return "TIMESTAMP"
        case .json: return "JSONB"
        }
    }
}

extension PostgreSQLDriver {
    
    func _createTable(_ connection: MDConnection, _ table: MDSQLTable) -> EventLoopFuture<Void> {
        
        do {
            
            guard let connection = connection.connection as? DBSQLConnection else { throw MDError.unknown }
            
            let list: [SQLRaw] = ["id VARCHAR(10) NOT NULL PRIMARY KEY"] + table.columns.map { "\(identifier: $0.name) \($0.type.postgresType)" }
            
            let sql: SQLRaw = "CREATE TABLE IF NOT EXISTS \(identifier: table.name) (\(list.joined(separator: ",")))"
            
            return connection.execute(sql).map { _ in }
            
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
    
    func addColumns(_ connection: MDConnection, _ table: String, _ columns: [MDSQLTableColumn]) -> EventLoopFuture<Void> {
        
        do {
            
            guard let connection = connection.connection as? DBSQLConnection else { throw MDError.unknown }
            
            let list: [SQLRaw] = columns.map { "ADD COLUMN IF NOT EXISTS \(identifier: $0.name) \($0.type.postgresType)" }
            
            let sql: SQLRaw = "ALTER TABLE IF EXISTS \(identifier: table) \(list.joined(separator: ","))"
            
            return connection.execute(sql).map { _ in }
            
        } catch {
            
            return connection.eventLoopGroup.next().makeFailedFuture(error)
        }
    }
    
    func dropColumns(_ connection: MDConnection, _ table: String, _ columns: [String]) -> EventLoopFuture<Void> {
        
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
