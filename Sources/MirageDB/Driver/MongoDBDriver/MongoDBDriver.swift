//
//  MongoDBDriver.swift
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

import MongoSwift

extension MDObject {
    
    fileprivate init(class: String, data object: BSONDocument) throws {
        var data: [String: MDData] = [:]
        for (key, value) in object where !MDObject._default_fields.contains(key) {
            data[key] = try MDData(value)
        }
        self.init(
            class: `class`,
            id: object["_id"]?.stringValue,
            createdAt: object["_created_at"]?.dateValue,
            updatedAt: object["_updated_at"]?.dateValue,
            data: data
        )
    }
}

extension MDFindExpression {
    
    fileprivate func filterBSONDocument() throws -> BSONDocument {
        return try filters.reduce { $0 && $1 }.map { try MongoPredicateExpression($0) }?.toBSONDocument() ?? [:]
    }
}

extension MDFindOneExpression {
    
    fileprivate func filterBSONDocument() throws -> BSONDocument {
        return try filters.reduce { $0 && $1 }.map { try MongoPredicateExpression($0) }?.toBSONDocument() ?? [:]
    }
}

extension DBMongoSortOrder {
    
    fileprivate init(_ order: MDSortOrderOption) {
        switch order {
        case .ascending: self = .ascending
        case .descending: self = .descending
        }
    }
}

extension Dictionary where Key == String, Value == MDUpdateOption {
    
    func toBSONDocument() throws -> BSONDocument {
        
        var set: BSONDocument = [:]
        var unset: BSONDocument = [:]
        var inc: BSONDocument = [:]
        var mul: BSONDocument = [:]
        var max: BSONDocument = [:]
        var min: BSONDocument = [:]
        var push: BSONDocument = [:]
        var pullAll: BSONDocument = [:]
        var pop: BSONDocument = [:]
        
        for (key, value) in self {
            switch value {
            case .set(nil): unset[key] = ""
            case let .set(value): set[key] = value.toMDData().toBSON()
            case let .increment(value): inc[key] = value.toMDData().toBSON()
            case let .multiply(value): mul[key] = value.toMDData().toBSON()
            case let .max(value): max[key] = value.toMDData().toBSON()
            case let .min(value): min[key] = value.toMDData().toBSON()
            case let .push(value): push[key] = value.toMDData().toBSON()
            case let .removeAll(value): pullAll[key] = value.map { $0.toMDData() }.toBSON()
            case .popFirst: pop[key] = -1
            case .popLast: pop[key] = 1
            }
        }
        
        var update: BSONDocument = [:]
        if !set.isEmpty { update["$set"] = BSON(set) }
        if !unset.isEmpty { update["$unset"] = BSON(unset) }
        if !inc.isEmpty { update["$inc"] = BSON(inc) }
        if !mul.isEmpty { update["$mul"] = BSON(mul) }
        if !max.isEmpty { update["$max"] = BSON(max) }
        if !min.isEmpty { update["$min"] = BSON(min) }
        if !push.isEmpty { update["$push"] = BSON(push) }
        if !pullAll.isEmpty { update["$pullAll"] = BSON(pullAll) }
        if !pop.isEmpty { update["$pop"] = BSON(pop) }
        return update
    }
}

struct MongoDBDriver: MDDriver {
    
    func tables(_ connection: MDConnection) async throws -> [String] {
        
        return try await connection.connection.mongoQuery().collections().execute().toArray().map { $0.name }
    }
    
    func stats(_ connection: MDConnection, _ class: String) async throws -> MDTableStats {
        
        let stats = try await connection.connection.mongoQuery().collStats(`class`)
        
        guard let storageSize = stats["storageSize"]?.toInt() else { throw MDError.unsupportedOperation }
        guard let totalIndexSize = stats["totalIndexSize"]?.toInt() else { throw MDError.unsupportedOperation }
        guard let totalSize = stats["totalSize"]?.toInt() else { throw MDError.unsupportedOperation }
        
        return MDTableStats(table: storageSize, indexes: totalIndexSize, total: totalSize)
    }
    
    func count(_ query: MDFindExpression) async throws -> Int {
        
        let filter = try query.filterBSONDocument()
        
        let _query = query.connection.connection.mongoQuery().collection(query.class)
        
        return try await _query.count().filter(filter).execute()
    }
    
    private func _find(_ query: MDFindExpression) throws -> DBMongoFindExpression<BSONDocument> {
        
        let filter = try query.filterBSONDocument()
        
        var _query = query.connection.connection.mongoQuery().collection(query.class).find().filter(filter)
        
        if !query.sort.isEmpty {
            _query = _query.sort(query.sort.stringKeys.mapValues(DBMongoSortOrder.init))
        }
        if query.skip > 0 {
            _query = _query.skip(query.skip)
        }
        if query.limit != .max {
            _query = _query.limit(query.limit)
        }
        if let includes = query.includes {
            let projection = Dictionary(uniqueKeysWithValues: includes.stringKeys.union(MDObject._default_fields).map { ($0, 1) })
            _query = _query.projection(BSONDocument(projection))
        }
        
        return _query
    }
    
    func toArray(_ query: MDFindExpression) async throws -> [MDObject] {
        
        let _query = try self._find(query)
        
        return try await _query.execute().toArray().map { try MDObject(class: query.class, data: $0) }
    }
    
    func forEach(_ query: MDFindExpression, _ body: @escaping (MDObject) throws -> Void) async throws {
        
        let _query = try self._find(query)
        
        return try await _query.execute().forEach { try body(MDObject(class: query.class, data: $0)) }
    }
    
    func first(_ query: MDFindExpression) async throws -> MDObject? {
        
        let filter = try query.filterBSONDocument()
        
        var _query = query.connection.connection.mongoQuery().collection(query.class).findOne().filter(filter)
        
        if !query.sort.isEmpty {
            _query = _query.sort(query.sort.stringKeys.mapValues(DBMongoSortOrder.init))
        }
        if let includes = query.includes {
            let projection = Dictionary(uniqueKeysWithValues: includes.stringKeys.union(MDObject._default_fields).map { ($0, 1) })
            _query = _query.projection(BSONDocument(projection))
        }
        
        return try await _query.execute().map { try MDObject(class: query.class, data: $0) }
    }
    
    func findOneAndUpdate(_ query: MDFindOneExpression, _ update: [MDQueryKey: MDUpdateOption]) async throws -> MDObject? {
        
        let filter = try query.filterBSONDocument()
        
        var _query = query.connection.connection.mongoQuery().collection(query.class).findOneAndUpdate().filter(filter)
        
        let now = Date()
        
        var update = update.stringKeys
        update["_id"] = nil
        update["_created_at"] = nil
        update["_updated_at"] = .set(now)
        
        _query = try _query.update(update.toBSONDocument())
        
        switch query.returning {
        case .before: _query = _query.returnDocument(.before)
        case .after: _query = _query.returnDocument(.after)
        }
        
        if !query.sort.isEmpty {
            _query = _query.sort(query.sort.stringKeys.mapValues(DBMongoSortOrder.init))
        }
        if let includes = query.includes {
            let projection = Dictionary(uniqueKeysWithValues: includes.stringKeys.union(MDObject._default_fields).map { ($0, 1) })
            _query = _query.projection(BSONDocument(projection))
        }
        
        return try await _query.execute().map { try MDObject(class: query.class, data: $0) }
    }
    
    private func _findOneAndUpsert(_ query: MDFindOneExpression, _ update: [MDQueryKey: MDUpdateOption], _ setOnInsert: [MDQueryKey: MDDataConvertible]) async throws -> MDObject? {
        
        let filter = try query.filterBSONDocument()
        
        var _query = query.connection.connection.mongoQuery().collection(query.class).findOneAndUpdate().filter(filter)
        
        let now = Date()
        
        var update = update.stringKeys
        update["_id"] = nil
        update["_created_at"] = nil
        update["_updated_at"] = .set(now)
        
        var setOnInsert = setOnInsert.stringKeys
        setOnInsert["_id"] = query.objectIDGenerator?() ?? generalObjectIDGenerator()
        setOnInsert["_created_at"] = now
        setOnInsert["_updated_at"] = nil
        
        var _update = try update.toBSONDocument()
        var _setOnInsert: BSONDocument = [:]
        for case let (key, value) in setOnInsert where value.toMDData() != nil {
            _setOnInsert[key] = value.toMDData().toBSON()
        }
        if !_setOnInsert.isEmpty { _update["$setOnInsert"] = BSON(_setOnInsert) }
        
        _query = _query.update(_update)
        _query = _query.upsert(true)
        
        switch query.returning {
        case .before: _query = _query.returnDocument(.before)
        case .after: _query = _query.returnDocument(.after)
        }
        
        if !query.sort.isEmpty {
            _query = _query.sort(query.sort.stringKeys.mapValues(DBMongoSortOrder.init))
        }
        if let includes = query.includes {
            let projection = Dictionary(uniqueKeysWithValues: includes.stringKeys.union(MDObject._default_fields).map { ($0, 1) })
            _query = _query.projection(BSONDocument(projection))
        }
        
        return try await _query.execute().map { try MDObject(class: query.class, data: $0) }
    }
    
    func findOneAndUpsert(_ query: MDFindOneExpression, _ update: [MDQueryKey: MDUpdateOption], _ setOnInsert: [MDQueryKey: MDDataConvertible]) async throws -> MDObject? {
        
        do {
            
            return try await self._findOneAndUpsert(query, update, setOnInsert)
            
        } catch let error as MongoError.CommandError {
            
            if error.code == 11000 && error.message.contains(" index: _id_ ") {
                
                return try await self.findOneAndUpsert(query, update, setOnInsert)
            }
            
            throw error
        }
    }
    
    func findOneAndDelete(_ query: MDFindOneExpression) async throws -> MDObject? {
        
        let filter = try query.filterBSONDocument()
        
        var _query = query.connection.connection.mongoQuery().collection(query.class).findOneAndDelete().filter(filter)
        
        if !query.sort.isEmpty {
            _query = _query.sort(query.sort.stringKeys.mapValues(DBMongoSortOrder.init))
        }
        if let includes = query.includes {
            let projection = Dictionary(uniqueKeysWithValues: includes.stringKeys.union(MDObject._default_fields).map { ($0, 1) })
            _query = _query.projection(BSONDocument(projection))
        }
        
        return try await _query.execute().map { try MDObject(class: query.class, data: $0) }
    }
    
    func deleteAll(_ query: MDFindExpression) async throws -> Int? {
        
        let filter = try query.filterBSONDocument()
        
        let _query = query.connection.connection.mongoQuery().collection(query.class)
        
        return try await _query.deleteMany().filter(filter).execute()?.deletedCount
    }
    
    private func _insert(_ connection: MDConnection, _ class: String, _ values: [MDQueryKey: MDData]) async throws -> MDObject {
        
        let now = Date()
        
        var data = values.stringKeys
        data["_id"] = MDData(generalObjectIDGenerator())
        data["_created_at"] = MDData(now)
        data["_updated_at"] = MDData(now)
        
        let _values = BSONDocument(data.mapValues { $0.toBSON() })
        
        let result = try await connection.connection.mongoQuery().collection(`class`)
            .insertOne()
            .value(_values)
            .execute()
        
        guard let id = result?.insertedID.stringValue else { throw MDError.unknown }
        
        return MDObject(
            class: `class`,
            id: id,
            createdAt: now,
            updatedAt: now,
            data: data
        )
    }
    
    func insert(_ connection: MDConnection, _ class: String, _ values: [MDQueryKey: MDData]) async throws -> MDObject {
        
        do {
            
            return try await self._insert(connection, `class`, values)
            
        } catch let error as MongoError.WriteError {
            
            if let writeFailure = error.writeFailure, writeFailure.code == 11000 && writeFailure.message.contains(" index: _id_ ") {
                
                return try await self.insert(connection, `class`, values)
            }
            
            throw error
        }
    }
    
    func withTransaction<T>(
        _ connection: MDConnection,
        _ transactionBody: @escaping (MDConnection) async throws -> T
    ) async throws -> T {
        
        return try await connection.connection.withTransaction { try await transactionBody(MDConnection(connection: $0)) }
    }
    
}

extension MongoDBDriver {
    
    func createTable(_ connection: MDConnection, _ table: String, _ columns: [String: MDSQLDataType]) async throws {
        
        do {
            
            _ = try await connection.connection.mongoQuery().createCollection(table).execute()
            
        } catch let error as MongoError.CommandError {
            
            if error.code == 48 { // Collection already exists
                return
            }
            
            throw error
        }
    }
    
    func addColumns(_ connection: MDConnection, _ table: String, _ columns: [String: MDSQLDataType]) async throws {
        
    }
    
    func dropTable(_ connection: MDConnection, _ table: String) async throws {
        
        try await connection.connection.mongoQuery().collection(table).drop().execute()
    }
    
    func dropColumns(_ connection: MDConnection, _ table: String, _ columns: Set<String>) async throws {
        
        var unset: BSONDocument = [:]
        
        for column in columns {
            unset[column] = 1
        }
        
        _ = try await connection.connection.mongoQuery().collection(table).updateMany().update(["$unset": BSON(unset)]).execute()
    }
    
    func addIndex(_ connection: MDConnection, _ table: String, _ index: MDSQLTableIndex) async throws {
        
        var keys: BSONDocument = [:]
        
        for (key, option) in index.columns {
            switch option {
            case .ascending: keys[key] = 1
            case .descending: keys[key] = -1
            }
        }
        
        _ = try await connection.connection.mongoQuery().collection(table).createIndex().index(keys).name(index.name).unique(index.isUnique).execute()
    }
    
    func dropIndex(_ connection: MDConnection, _ table: String, _ index: String) async throws {
        
        try await connection.connection.mongoQuery().collection(table).dropIndex().index(index).execute()
    }
}
