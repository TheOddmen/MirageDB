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
    
    func tables(_ connection: MDConnection) -> EventLoopFuture<[String]> {
        
        return connection.connection.mongoQuery().collections().execute().toArray().map { $0.map { $0.name } }
    }
    
    func count(_ query: MDFindExpression) -> EventLoopFuture<Int> {
        
        do {
            
            let filter = try query.filterBSONDocument()
            
            let _query = query.connection.connection.mongoQuery().collection(query.class)
            
            return _query.count().filter(filter).execute()
            
        } catch {
            
            return query.connection.eventLoopGroup.next().makeFailedFuture(error)
        }
    }
    
    func _find(_ query: MDFindExpression) throws -> DBMongoFindExpression<BSONDocument> {
        
        let filter = try query.filterBSONDocument()
        
        var _query = query.connection.connection.mongoQuery().collection(query.class).find().filter(filter)
        
        if !query.sort.isEmpty {
            _query = _query.sort(query.sort.mapValues(DBMongoSortOrder.init))
        }
        if query.skip > 0 {
            _query = _query.skip(query.skip)
        }
        if query.limit != .max {
            _query = _query.limit(query.limit)
        }
        if let includes = query.includes {
            let projection = Dictionary(uniqueKeysWithValues: includes.union(MDObject._default_fields).map { ($0, 1) })
            _query = _query.projection(BSONDocument(projection))
        }
        
        return _query
    }
    
    func toArray(_ query: MDFindExpression) -> EventLoopFuture<[MDObject]> {
        
        do {
            
            let _query = try self._find(query)
            
            return _query.execute().toArray().flatMapThrowing { try $0.map { try MDObject(class: query.class, data: $0) } }
            
        } catch {
            
            return query.connection.eventLoopGroup.next().makeFailedFuture(error)
        }
    }
    
    func forEach(_ query: MDFindExpression, _ body: @escaping (MDObject) throws -> Void) -> EventLoopFuture<Void> {
        
        do {
            
            let _query = try self._find(query)
            
            return _query.execute().forEach { try body(MDObject(class: query.class, data: $0)) }
            
        } catch {
            
            return query.connection.eventLoopGroup.next().makeFailedFuture(error)
        }
    }
    
    func first(_ query: MDFindExpression) -> EventLoopFuture<MDObject?> {
        
        do {
            
            let filter = try query.filterBSONDocument()
            
            var _query = query.connection.connection.mongoQuery().collection(query.class).findOne().filter(filter)
            
            if !query.sort.isEmpty {
                _query = _query.sort(query.sort.mapValues(DBMongoSortOrder.init))
            }
            if let includes = query.includes {
                let projection = Dictionary(uniqueKeysWithValues: includes.union(MDObject._default_fields).map { ($0, 1) })
                _query = _query.projection(BSONDocument(projection))
            }
            
            return _query.execute().flatMapThrowing { try $0.map { try MDObject(class: query.class, data: $0) } }
            
        } catch {
            
            return query.connection.eventLoopGroup.next().makeFailedFuture(error)
        }
    }
    
    func findOneAndUpdate(_ query: MDFindOneExpression, _ update: [String : MDUpdateOption]) -> EventLoopFuture<MDObject?> {
        
        do {
            
            let filter = try query.filterBSONDocument()
            
            var _query = query.connection.connection.mongoQuery().collection(query.class).findOneAndUpdate().filter(filter)
            
            let now = Date()
            
            var update = update
            update["_id"] = nil
            update["_created_at"] = nil
            update["_updated_at"] = .set(now)
            
            _query = try _query.update(update.toBSONDocument())
            
            switch query.returning {
            case .before: _query = _query.returnDocument(.before)
            case .after: _query = _query.returnDocument(.after)
            }
            
            if !query.sort.isEmpty {
                _query = _query.sort(query.sort.mapValues(DBMongoSortOrder.init))
            }
            if let includes = query.includes {
                let projection = Dictionary(uniqueKeysWithValues: includes.union(MDObject._default_fields).map { ($0, 1) })
                _query = _query.projection(BSONDocument(projection))
            }
            
            return _query.execute().flatMapThrowing { try $0.map { try MDObject(class: query.class, data: $0) } }
            
        } catch {
            
            return query.connection.eventLoopGroup.next().makeFailedFuture(error)
        }
    }
    
    func _findOneAndUpsert(_ query: MDFindOneExpression, _ update: [String : MDUpdateOption], _ setOnInsert: [String : MDDataConvertible]) -> EventLoopFuture<MDObject?> {
        
        do {
            
            let filter = try query.filterBSONDocument()
            
            var _query = query.connection.connection.mongoQuery().collection(query.class).findOneAndUpdate().filter(filter)
            
            let now = Date()
            
            var update = update
            update["_id"] = nil
            update["_created_at"] = nil
            update["_updated_at"] = .set(now)
            
            var setOnInsert = setOnInsert
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
                _query = _query.sort(query.sort.mapValues(DBMongoSortOrder.init))
            }
            if let includes = query.includes {
                let projection = Dictionary(uniqueKeysWithValues: includes.union(MDObject._default_fields).map { ($0, 1) })
                _query = _query.projection(BSONDocument(projection))
            }
            
            return _query.execute().flatMapThrowing { try $0.map { try MDObject(class: query.class, data: $0) } }
            
        } catch {
            
            return query.connection.eventLoopGroup.next().makeFailedFuture(error)
        }
    }
    
    func findOneAndUpsert(_ query: MDFindOneExpression, _ update: [String : MDUpdateOption], _ setOnInsert: [String : MDDataConvertible]) -> EventLoopFuture<MDObject?> {
        
        self._findOneAndUpsert(query, update, setOnInsert).flatMapError { error in
            
            if let error = error as? MongoError.CommandError,
               error.code == 11000 && error.message.contains(" index: _id_ ") {
                
                return self.findOneAndUpsert(query, update, setOnInsert)
            }
            
            return query.connection.eventLoopGroup.next().makeFailedFuture(error)
        }
    }
    
    func findOneAndDelete(_ query: MDFindOneExpression) -> EventLoopFuture<MDObject?> {
        
        do {
            
            let filter = try query.filterBSONDocument()
            
            var _query = query.connection.connection.mongoQuery().collection(query.class).findOneAndDelete().filter(filter)
            
            if !query.sort.isEmpty {
                _query = _query.sort(query.sort.mapValues(DBMongoSortOrder.init))
            }
            if let includes = query.includes {
                let projection = Dictionary(uniqueKeysWithValues: includes.union(MDObject._default_fields).map { ($0, 1) })
                _query = _query.projection(BSONDocument(projection))
            }
            
            return _query.execute().flatMapThrowing { try $0.map { try MDObject(class: query.class, data: $0) } }
            
        } catch {
            
            return query.connection.eventLoopGroup.next().makeFailedFuture(error)
        }
    }
    
    func deleteAll(_ query: MDFindExpression) -> EventLoopFuture<Int?> {
        
        do {
            
            let filter = try query.filterBSONDocument()
            
            let _query = query.connection.connection.mongoQuery().collection(query.class)
            
            return _query.deleteMany().filter(filter).execute().map { $0?.deletedCount }
            
        } catch {
            
            return query.connection.eventLoopGroup.next().makeFailedFuture(error)
        }
    }
    
    func _insert(_ connection: MDConnection, _ class: String, _ values: [String: MDData]) -> EventLoopFuture<MDObject> {
        
        let now = Date()
        
        var data = values
        data["_id"] = MDData(generalObjectIDGenerator())
        data["_created_at"] = MDData(now)
        data["_updated_at"] = MDData(now)
        
        let _values = BSONDocument(data.mapValues { $0.toBSON() })
        
        return connection.connection.mongoQuery().collection(`class`)
            .insertOne()
            .value(_values)
            .execute()
            .flatMapThrowing { result in
                
                guard let id = result?.insertedID.stringValue else { throw MDError.unknown }
                
                return MDObject(
                    class: `class`,
                    id: id,
                    createdAt: now,
                    updatedAt: now,
                    data: values
                )
            }
    }
    
    func insert(_ connection: MDConnection, _ class: String, _ values: [String: MDData]) -> EventLoopFuture<MDObject> {
        
        self._insert(connection, `class`, values).flatMapError { error in
            
            if let error = error as? MongoError.WriteError,
               let writeFailure = error.writeFailure,
               writeFailure.code == 11000 && writeFailure.message.contains(" index: _id_ ") {
                
                return self.insert(connection, `class`, values)
            }
            
            return connection.eventLoopGroup.next().makeFailedFuture(error)
        }
    }
    
    func withTransaction<T>(
        _ connection: MDConnection,
        _ transactionBody: @escaping (MDConnection) throws -> EventLoopFuture<T>
    ) -> EventLoopFuture<T> {
        
        return connection.connection.withTransaction { try transactionBody(MDConnection(connection: $0)) }
    }
    
    #if compiler(>=5.5.2) && canImport(_Concurrency)
    
    @available(macOS 10.15, iOS 13, tvOS 13, watchOS 6, *)
    func withTransaction<T>(
        _ connection: MDConnection,
        _ transactionBody: (MDConnection) async throws -> T
    ) async throws -> T {
        
        return try await connection.connection.withTransaction { try await transactionBody(MDConnection(connection: $0)) }
    }
    
    #endif

}

extension MongoDBDriver {
    
    func createTable(_ connection: MDConnection, _ table: String, _ columns: [String: MDSQLDataType]) -> EventLoopFuture<Void> {
        
        return connection.connection.mongoQuery().createCollection(table).execute().map { _ in }.flatMapErrorThrowing { error in
            
            if let error = error as? MongoError.CommandError, error.code == 48 { // Collection already exists
                return
            }
            
            throw error
        }
    }
    
    func addColumns(_ connection: MDConnection, _ table: String, _ columns: [String: MDSQLDataType]) -> EventLoopFuture<Void> {
        
        return connection.eventLoopGroup.next().makeSucceededVoidFuture()
    }
    
    func dropTable(_ connection: MDConnection, _ table: String) -> EventLoopFuture<Void> {
        
        return connection.connection.mongoQuery().collection(table).drop().execute()
    }
    
    func dropColumns(_ connection: MDConnection, _ table: String, _ columns: Set<String>) -> EventLoopFuture<Void> {
        
        var unset: BSONDocument = [:]
        
        for column in columns {
            unset[column] = 1
        }
        
        return connection.connection.mongoQuery().collection(table).updateMany().update(["$unset": BSON(unset)]).execute().map { _ in }
    }
    
    func addIndex(_ connection: MDConnection, _ table: String, _ index: MDSQLTableIndex) -> EventLoopFuture<Void> {
        
        var keys: BSONDocument = [:]
        
        for (key, option) in index.columns {
            switch option {
            case .ascending: keys[key] = 1
            case .descending: keys[key] = -1
            }
        }
        
        return connection.connection.mongoQuery().collection(table).createIndex().index(keys).name(index.name).unique(index.isUnique).execute().map { _ in }
    }
    
    func dropIndex(_ connection: MDConnection, _ table: String, _ index: String) -> EventLoopFuture<Void> {
        
        return connection.connection.mongoQuery().collection(table).dropIndex().index(index).execute()
    }
}
