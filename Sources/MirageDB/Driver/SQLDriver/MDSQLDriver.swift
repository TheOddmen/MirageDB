//
//  MDSQLDriver.swift
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

protocol MDSQLDriver: MDDriver {
    
    func _createTable(
        _ connection: MDConnection,
        _ table: String,
        _ columns: [String: MDSQLDataType]
    ) async throws -> Void
}

extension MDSQLDriver {
    
    func createTable(_ connection: MDConnection, _ table: String, _ columns: [String: MDSQLDataType]) async throws {
        
        connection.logger.trace("Generating table \(table) if necessary.")
        
        do {
            
            var columns = columns
            columns["_created_at"] = .timestamp
            columns["_updated_at"] = .timestamp
            
            try await self._createTable(connection, table, columns)
            
            connection.logger.trace("Generate table \(table) completed.")
            
        } catch {
            
            connection.logger.trace("Generate table \(table) failed. Error: \(error)")
            
            throw error
        }
    }
}

extension MDData {
    
    var sql_type: MDSQLDataType? {
        switch self {
        case .null: return nil
        case .boolean: return .boolean
        case .string: return .string
        case let .number(value):
            switch value {
            case .signed: return .number
            case .unsigned: return .number
            case .number: return .number
            case .decimal: return .decimal
            }
        case .timestamp: return .timestamp
        case .binary: return .binary
        case .array: return .json
        case .dictionary: return .json
        }
    }
}

extension MDUpdateOption {
    
    var sql_type: MDSQLDataType? {
        switch self {
        case let .set(data): return data.toMDData().sql_type
        case .push, .removeAll, .popFirst, .popLast: return .json
        default: return nil
        }
    }
}

extension MDUpsertOption {
    
    var sql_type: MDSQLDataType? {
        switch self {
        case let .set(data): return data.toMDData().sql_type
        case let .setOnInsert(data): return data.toMDData().sql_type
        case .push, .removeAll, .popFirst, .popLast: return .json
        default: return nil
        }
    }
}

extension MDObject {
    
    fileprivate init(_ object: DBObject) throws {
        var data: [String: MDData] = [:]
        for key in object.keys where !MDObject._default_fields.contains(key) {
            data[key] = try MDData(fromSQLData: object[key])
        }
        self.init(
            class: object.class,
            id: object["_id"].string,
            createdAt: object["_created_at"].date,
            updatedAt: object["_updated_at"].date,
            data: data
        )
    }
}

extension DBSortOrderOption {
    
    fileprivate init(_ order: MDSortOrderOption) {
        switch order {
        case .ascending: self = .ascending
        case .descending: self = .descending
        }
    }
}

extension DBUpdateOption {
    
    fileprivate init(_ operation: MDUpdateOption) {
        switch operation {
        case let .set(value): self = .set(value.toMDData().toSQLData())
        case let .increment(value): self = .increment(value.toMDData().toSQLData())
        case let .multiply(value): self = .multiply(value.toMDData().toSQLData())
        case let .max(value): self = .max(value.toMDData().toSQLData())
        case let .min(value): self = .min(value.toMDData().toSQLData())
        case let .push(value): self = .push([value.toMDData().toSQLData()])
        case let .removeAll(value): self = .removeAll(value.map { $0.toMDData().toSQLData() })
        case .popFirst: self = .popFirst
        case .popLast: self = .popLast
        }
    }
}

extension DBUpsertOption {
    
    fileprivate init(_ operation: MDUpsertOption) {
        switch operation {
        case let .set(value): self = .set(value.toMDData().toSQLData())
        case let .setOnInsert(value): self = .setOnInsert(value.toMDData().toSQLData())
        case let .increment(value): self = .increment(value.toMDData().toSQLData())
        case let .multiply(value): self = .multiply(value.toMDData().toSQLData())
        case let .max(value): self = .max(value.toMDData().toSQLData())
        case let .min(value): self = .min(value.toMDData().toSQLData())
        case let .push(value): self = .push([value.toMDData().toSQLData()])
        case let .removeAll(value): self = .removeAll(value.map { $0.toMDData().toSQLData() })
        case .popFirst: self = .popFirst
        case .popLast: self = .popLast
        }
    }
}

extension MDSQLDriver {
    
    func tables(_ connection: MDConnection) async throws -> [String] {
        
        guard let connection = connection.connection as? DBSQLConnection else { throw MDError.unknown }
        
        return try await connection.tables()
    }
    
    func stats(_ connection: MDConnection, _ class: String) async throws -> MDTableStats {
        
        guard let connection = connection.connection as? DBSQLConnection else { throw MDError.unknown }
        
        let stats = try await connection.size(of: `class`)
        
        return MDTableStats(stats)
    }
    
    func checkTableExists(_ connection: MDConnection, _ table: String) async throws -> Bool {
        
        let _table = table.lowercased()
        
        return try await self.tables(connection).contains(where: { $0.lowercased() == _table })
    }
    
    func enforceFieldExists(_ connection: MDConnection, _ table: String, _ columns: [String: MDSQLDataType]) async throws {
        
        if try await self.checkTableExists(connection, table) {
            
            if columns.isEmpty { return }
            
            connection.logger.trace("Generating columns for table \(table) if necessary.")
            
            do {
                
                try await self.addColumns(connection, table, columns)
                
                connection.logger.trace("Generate columns for table \(table) completed.")
                
            } catch {
                
                connection.logger.trace("Generate columns for table \(table) failed. Error: \(error)")
                
                throw error
            }
            
        } else {
            
            connection.logger.trace("Generating table \(table)")
            
            do {
                
                try await self.createTable(connection, table, columns)
                
                connection.logger.trace("Generate table \(table) completed.")
                
            } catch {
                
                connection.logger.trace("Generate table \(table) failed. Error: \(error)")
                
                throw error
            }
        }
    }
}

extension MDSQLDriver {
    
    func count(_ query: MDFindExpression) async throws -> Int {
        
        var _query = query.connection.connection.query().find(query.class)
        
        _query = _query.filter(query.filters.map(DBPredicateExpression.init))
        
        guard try await self.checkTableExists(query.connection, query.class) else { return 0 }
        
        return try await _query.count()
    }
    
    private func _find(_ query: MDFindExpression) throws -> DBFindExpression {
        
        var _query = query.connection.connection.query().find(query.class)
        
        _query = _query.filter(query.filters.map(DBPredicateExpression.init))
        
        if !query.sort.isEmpty {
            _query = _query.sort(query.sort.stringKeys.mapValues(DBSortOrderOption.init))
        }
        if query.skip > 0 {
            _query = _query.skip(query.skip)
        }
        if query.limit != .max {
            _query = _query.limit(query.limit)
        }
        if let includes = query.includes {
            _query = _query.includes(includes.stringKeys.union(MDObject._default_fields))
        }
        
        return _query
    }
    
    func toArray(_ query: MDFindExpression) async throws -> [MDObject] {
        
        let _query = try self._find(query)
        
        guard try await self.checkTableExists(query.connection, query.class) else { return [] }
        
        return try await _query.toArray().map(MDObject.init)
    }
    
    func forEach(_ query: MDFindExpression, _ body: @escaping (MDObject) throws -> Void) async throws {
        
        let _query = try self._find(query)
        
        guard try await self.checkTableExists(query.connection, query.class) else { return }
        
        return try await _query.forEach { try body(MDObject($0)) }
    }
    
    func first(_ query: MDFindExpression) async throws -> MDObject? {
        return try await self.toArray(query.limit(1)).first
    }
    
    func findOneAndUpdate(_ query: MDFindOneExpression, _ update: [MDQueryKey: MDUpdateOption]) async throws -> MDObject? {
        
        var _query = query.connection.connection.query().findOne(query.class)
        
        _query = _query.filter(query.filters.map(DBPredicateExpression.init))
        
        switch query.returning {
        case .before: _query = _query.returning(.before)
        case .after: _query = _query.returning(.after)
        }
        
        if !query.sort.isEmpty {
            _query = _query.sort(query.sort.stringKeys.mapValues(DBSortOrderOption.init))
        }
        if let includes = query.includes {
            _query = _query.includes(includes.stringKeys.union(MDObject._default_fields))
        }
        
        let now = Date()
        
        let update = update.stringKeys
        let columns = update.compactMapValues { $0.sql_type }
        
        var _update = update
        _update["_id"] = nil
        _update["_created_at"] = nil
        _update["_updated_at"] = .set(now)
        
        try await self.enforceFieldExists(query.connection, query.class, columns)
        
        return try await _query.update(_update.mapValues(DBUpdateOption.init)).map(MDObject.init)
    }
    
    private func _findOneAndUpsert(_ query: MDFindOneExpression, _ update: [MDQueryKey: MDUpdateOption], _ setOnInsert: [MDQueryKey: MDDataConvertible]) async throws -> MDObject? {
        
        var _query = query.connection.connection.query().findOne(query.class)
        
        _query = _query.filter(query.filters.map(DBPredicateExpression.init))
        
        switch query.returning {
        case .before: _query = _query.returning(.before)
        case .after: _query = _query.returning(.after)
        }
        
        if !query.sort.isEmpty {
            _query = _query.sort(query.sort.stringKeys.mapValues(DBSortOrderOption.init))
        }
        if let includes = query.includes {
            _query = _query.includes(includes.stringKeys.union(MDObject._default_fields))
        }
        
        let now = Date()
        
        let update = update.stringKeys
        let setOnInsert = setOnInsert.stringKeys
        
        let columns = update.compactMapValues { $0.sql_type }
            .merging(setOnInsert.compactMapValues { $0.toMDData().sql_type }) { _, rhs in rhs }
        
        var _update = update.mapValues(DBUpdateOption.init)
        _update["_id"] = nil
        _update["_created_at"] = nil
        _update["_updated_at"] = .set(now)
        
        var _setOnInsert = setOnInsert.mapValues { $0.toMDData().toSQLData() }
        _setOnInsert["_id"] = DBData(query.objectIDGenerator?() ?? generalObjectIDGenerator())
        _setOnInsert["_created_at"] = DBData(now)
        _setOnInsert["_updated_at"] = nil
        
        try await self.enforceFieldExists(query.connection, query.class, columns)
        
        return try await _query.upsert(_update, setOnInsert: _setOnInsert).map(MDObject.init)
    }
    
    func findOneAndUpsert(_ query: MDFindOneExpression, _ update: [MDQueryKey: MDUpdateOption], _ setOnInsert: [MDQueryKey: MDDataConvertible]) async throws -> MDObject? {
        
        do {
            
            return try await self._findOneAndUpsert(query, update, setOnInsert)
            
        } catch let error as Database.Error {
            
            if error == .duplicatedPrimaryKey {
                
                return try await self.findOneAndUpsert(query, update, setOnInsert)
            }
            
            throw error
        }
    }
    
    func findOneAndDelete(_ query: MDFindOneExpression) async throws -> MDObject? {
        
        var _query = query.connection.connection.query().findOne(query.class)
        
        _query = _query.filter(query.filters.map(DBPredicateExpression.init))
        
        if !query.sort.isEmpty {
            _query = _query.sort(query.sort.stringKeys.mapValues(DBSortOrderOption.init))
        }
        if let includes = query.includes {
            _query = _query.includes(includes.stringKeys.union(MDObject._default_fields))
        }
        
        return try await _query.delete().map(MDObject.init)
    }
    
    func deleteAll(_ query: MDFindExpression) async throws -> Int? {
        
        var _query = query.connection.connection.query().find(query.class)
        
        _query = _query.filter(query.filters.map(DBPredicateExpression.init))
        
        return try await _query.delete()
    }
    
    private func _insert(_ connection: MDConnection, _ class: String, _ data: [MDQueryKey: MDData]) async throws -> MDObject {
        
        let now = Date()
        
        let data = data.stringKeys
        let columns = data.compactMapValues { $0.sql_type }
        
        var _data = data.compactMapValues { $0.isNil ? nil : $0.toSQLData() }
        _data["_id"] = DBData(generalObjectIDGenerator())
        _data["_created_at"] = DBData(now)
        _data["_updated_at"] = DBData(now)
        
        try await self.enforceFieldExists(connection, `class`, columns)
        
        let result = try await connection.connection.query().insert(`class`, _data)
        
        return try MDObject(result)
    }
    
    func insert(_ connection: MDConnection, _ class: String, _ values: [MDQueryKey: MDData]) async throws -> MDObject {
        
        do {
            
            return try await self._insert(connection, `class`, values)
            
        } catch let error as Database.Error {
            
            if error == .duplicatedPrimaryKey {
                
                return try await self.insert(connection, `class`, values)
            }
            
            throw error
        }
    }
    
}
