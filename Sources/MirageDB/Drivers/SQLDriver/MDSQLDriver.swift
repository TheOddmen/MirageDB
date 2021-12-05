//
//  MDSQLDriver.swift
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

protocol MDSQLDriver: MDDriver {
    
    func createTable(
        _ connection: MDConnection,
        _ table: String,
        _ columns: [String: MDSQLDataType]
    ) -> EventLoopFuture<Void>
    
    func addColumns(
        _ connection: MDConnection,
        _ table: String,
        _ columns: [String: MDSQLDataType]
    ) -> EventLoopFuture<Void>
    
    func _createTable(
        _ connection: MDConnection,
        _ table: String,
        _ columns: [String: MDSQLDataType]
    ) -> EventLoopFuture<Void>
}

extension MDSQLDriver {
    
    func createTable(_ connection: MDConnection, _ table: String, _ columns: [String: MDSQLDataType]) -> EventLoopFuture<Void> {
        var columns = columns
        columns["created_at"] = .timestamp
        columns["updated_at"] = .timestamp
        return self._createTable(connection, table, columns)
    }
}

extension MDData {
    
    var sql_type: MDSQLDataType? {
        switch self.type {
        case .null: return nil
        case .boolean: return .boolean
        case .string: return .string
        case .integer: return .integer
        case .number: return .number
        case .decimal: return .decimal
        case .timestamp: return .timestamp
        case .array: return .json
        case .dictionary: return .json
        }
    }
}

extension MDUpdateOperation {
    
    var sql_type: MDSQLDataType? {
        switch self {
        case let .set(data): return data.sql_type
        case .push, .removeAll, .popFirst, .popLast: return .json
        default: return nil
        }
    }
}

extension MDObject {
    
    fileprivate static let _default_fields = ["id", "created_at", "updated_at"]
    
    fileprivate init(_ object: DBObject) throws {
        var data: [String: MDData] = [:]
        for key in object.keys where !MDObject._default_fields.contains(key) {
            data[key] = try MDData(fromSQLData: object[key])
        }
        self.init(
            class: object.class,
            id: object["id"].string,
            createdAt: object["created_at"].date,
            updatedAt: object["updated_at"].date,
            data: data
        )
    }
}

extension DBQuerySortOrder {
    
    fileprivate init(_ order: MDSortOrder) {
        switch order {
        case .ascending: self = .ascending
        case .descending: self = .descending
        }
    }
}

extension DBQueryUpdateOperation {
    
    fileprivate init(_ operation: MDUpdateOperation) {
        switch operation {
        case let .set(value): self = .set(value.toSQLData())
        case let .increment(value): self = .increment(value.toSQLData())
        case let .multiply(value): self = .multiply(value.toSQLData())
        case let .max(value): self = .max(value.toSQLData())
        case let .min(value): self = .min(value.toSQLData())
        case let .push(value): self = .push([value.toSQLData()])
        case let .removeAll(value): self = .removeAll(value.map { $0.toSQLData() })
        case .popFirst: self = .popFirst
        case .popLast: self = .popLast
        }
    }
}

extension MDSQLDriver {
    
    func tables(_ connection: MDConnection) -> EventLoopFuture<[String]> {
        
        do {
            
            guard let connection = connection.connection as? DBSQLConnection else { throw MDError.unknown }
            
            return connection.tables()
            
        } catch {
            
            return connection.eventLoopGroup.next().makeFailedFuture(error)
        }
    }
    
    func enforceFieldExists(_ connection: MDConnection, _ table: String, _ columns: [String: MDSQLDataType]) -> EventLoopFuture<Void> {
        
        return self.tables(connection).flatMap { tables in
            
            let _table = table.lowercased()
            
            if tables.contains(where: { $0.lowercased() == _table }) {
                
                if columns.isEmpty {
                    
                    return connection.eventLoopGroup.next().makeSucceededVoidFuture()
                }
                
                return self.addColumns(connection, table, columns)
                
            } else {
                
                return self.createTable(connection, table, columns)
            }
        }
    }
}

extension MDSQLDriver {
    
    func count(_ query: MDQueryFindExpression) -> EventLoopFuture<Int> {
        
        do {
            
            guard let `class` = query.class else { throw MDError.classNotSet }
            
            var _query = query.connection.connection.query().find(`class`)
            
            _query = _query.filter(query.filters.map(DBQueryPredicateExpression.init))
            
            return _query.count()
            
        } catch {
            
            return query.connection.eventLoopGroup.next().makeFailedFuture(error)
        }
    }
    
    func _find(_ query: MDQueryFindExpression) throws -> DBQueryFindExpression {
        
        guard let `class` = query.class else { throw MDError.classNotSet }
        
        var _query = query.connection.connection.query().find(`class`)
        
        _query = _query.filter(query.filters.map(DBQueryPredicateExpression.init))
        
        if !query.sort.isEmpty {
            _query = _query.sort(query.sort.mapValues(DBQuerySortOrder.init))
        }
        if query.skip > 0 {
            _query = _query.skip(query.skip)
        }
        if query.limit != .max {
            _query = _query.limit(query.limit)
        }
        if !query.includes.isEmpty {
            _query = _query.includes(query.includes.union(MDObject._default_fields))
        }
        
        return _query
    }
    
    func toArray(_ query: MDQueryFindExpression) -> EventLoopFuture<[MDObject]> {
        
        do {
            
            let _query = try self._find(query)
            
            return _query.toArray().flatMapThrowing { try $0.map(MDObject.init) }
            
        } catch {
            
            return query.connection.eventLoopGroup.next().makeFailedFuture(error)
        }
    }
    
    func forEach(_ query: MDQueryFindExpression, _ body: @escaping (MDObject) throws -> Void) -> EventLoopFuture<Void> {
        
        do {
            
            let _query = try self._find(query)
            
            return _query.forEach { try body(MDObject($0)) }.map { _ in }
            
        } catch {
            
            return query.connection.eventLoopGroup.next().makeFailedFuture(error)
        }
    }
    
    func first(_ query: MDQueryFindExpression) -> EventLoopFuture<MDObject?> {
        return self.toArray(query.limit(1)).map { $0.first }
    }
    
    func findOneAndUpdate(_ query: MDQueryFindOneExpression, _ update: [String : MDUpdateOperation]) -> EventLoopFuture<MDObject?> {
        
        do {
            
            guard let `class` = query.class else { throw MDError.classNotSet }
            
            var _query = query.connection.connection.query().findOne(`class`)
            
            _query = _query.filter(query.filters.map(DBQueryPredicateExpression.init))
            
            switch query.returning {
            case .before: _query = _query.returning(.before)
            case .after: _query = _query.returning(.after)
            }
            
            if !query.sort.isEmpty {
                _query = _query.sort(query.sort.mapValues(DBQuerySortOrder.init))
            }
            if !query.includes.isEmpty {
                _query = _query.includes(query.includes.union(MDObject._default_fields))
            }
            
            let now = Date()
            
            let columns = update.compactMapValues { $0.sql_type }
            
            var _update = update
            _update["updated_at"] = .set(MDData(now))
            
            return self.enforceFieldExists(query.connection, `class`, columns).flatMap {
                
                _query.update(_update.mapValues(DBQueryUpdateOperation.init)).flatMapThrowing { try $0.map(MDObject.init) }
            }
            
        } catch {
            
            return query.connection.eventLoopGroup.next().makeFailedFuture(error)
        }
    }
    
    func findOneAndUpsert(_ query: MDQueryFindOneExpression, _ update: [String : MDUpdateOperation], _ setOnInsert: [String : MDData]) -> EventLoopFuture<MDObject?> {
        
        do {
            
            guard let `class` = query.class else { throw MDError.classNotSet }
            
            var _query = query.connection.connection.query().findOne(`class`)
            
            _query = _query.filter(query.filters.map(DBQueryPredicateExpression.init))
            
            switch query.returning {
            case .before: _query = _query.returning(.before)
            case .after: _query = _query.returning(.after)
            }
            
            if !query.sort.isEmpty {
                _query = _query.sort(query.sort.mapValues(DBQuerySortOrder.init))
            }
            if !query.includes.isEmpty {
                _query = _query.includes(query.includes.union(MDObject._default_fields))
            }
            
            let now = Date()
            
            let columns = update.compactMapValues { $0.sql_type }.merging(setOnInsert.compactMapValues { $0.sql_type }) { _, rhs in rhs }
            
            var _update = update
            _update["updated_at"] = .set(MDData(now))
            
            var _setOnInsert = setOnInsert.mapValues { $0.toSQLData() }
            _setOnInsert["id"] = DBData(objectIDGenerator())
            _setOnInsert["created_at"] = DBData(now)
            
            return self.enforceFieldExists(query.connection, `class`, columns).flatMap {
                
                _query.upsert(_update.mapValues(DBQueryUpdateOperation.init), setOnInsert: _setOnInsert).flatMapThrowing { try $0.map(MDObject.init) }
            }
            
        } catch {
            
            return query.connection.eventLoopGroup.next().makeFailedFuture(error)
        }
    }
    
    func findOneAndDelete(_ query: MDQueryFindOneExpression) -> EventLoopFuture<MDObject?> {
        
        do {
            
            guard let `class` = query.class else { throw MDError.classNotSet }
            
            var _query = query.connection.connection.query().findOne(`class`)
            
            _query = _query.filter(query.filters.map(DBQueryPredicateExpression.init))
            
            if !query.sort.isEmpty {
                _query = _query.sort(query.sort.mapValues(DBQuerySortOrder.init))
            }
            if !query.includes.isEmpty {
                _query = _query.includes(query.includes.union(MDObject._default_fields))
            }
            
            return _query.delete().flatMapThrowing { try $0.map(MDObject.init) }
            
        } catch {
            
            return query.connection.eventLoopGroup.next().makeFailedFuture(error)
        }
    }
    
    func deleteAll(_ query: MDQueryFindExpression) -> EventLoopFuture<Int?> {
        
        do {
            
            guard let `class` = query.class else { throw MDError.classNotSet }
            
            var _query = query.connection.connection.query().find(`class`)
            
            _query = _query.filter(query.filters.map(DBQueryPredicateExpression.init))
            
            return _query.delete()
            
        } catch {
            
            return query.connection.eventLoopGroup.next().makeFailedFuture(error)
        }
    }
    
    func insert(_ connection: MDConnection, _ class: String, _ data: [String: MDData]) -> EventLoopFuture<MDObject> {
        
        let now = Date()
        
        let columns = data.compactMapValues { $0.sql_type }
        
        var _data = data.compactMapValues { $0.isNil ? nil : $0.toSQLData() }
        _data["id"] = DBData(objectIDGenerator())
        _data["created_at"] = DBData(now)
        _data["updated_at"] = DBData(now)
        
        return self.enforceFieldExists(connection, `class`, columns).flatMap {
            
            connection.connection.query().insert(`class`, _data).flatMapThrowing { try MDObject($0) }
        }
    }
    
    func withTransaction<T>(_ connection: MDConnection, _ transactionBody: @escaping () throws -> EventLoopFuture<T>) -> EventLoopFuture<T> {
        
        do {
            
            guard let connection = connection.connection as? DBSQLConnection else { throw MDError.unknown }
            
            return connection.withTransaction { _ in try transactionBody() }
            
        } catch {
            
            return connection.eventLoopGroup.next().makeFailedFuture(error)
        }
    }
}
