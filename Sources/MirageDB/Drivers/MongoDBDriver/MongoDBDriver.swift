//
//  MongoDBDriver.swift
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

import SwiftBSON

extension MDObject {
    
    fileprivate init(class: String, data object: BSONDocument) throws {
        var data: [String: MDData] = [:]
        for (key, value) in object where key != "_id" {
            data[key] = try MDData(value)
        }
        self.init(class: `class`, id: object["_id"]?.stringValue, data: data)
    }
}

extension MDQuery {
    
    fileprivate func filterBSONDocument() throws -> BSONDocument {
        return try filters.reduce { $0 && $1 }.map { try MongoPredicateExpression($0) }?.toBSONDocument() ?? [:]
    }
}

extension DBMongoSortOrder {
    
    fileprivate init(_ order: MDSortOrder) {
        switch order {
        case .ascending: self = .ascending
        case .descending: self = .descending
        }
    }
}

extension Dictionary where Key == String, Value == MDUpdateOperation {
    
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
            case let .set(value): set[key] = value.toBSON()
            case let .increment(value): inc[key] = value.toBSON()
            case let .multiply(value): mul[key] = value.toBSON()
            case let .max(value): max[key] = value.toBSON()
            case let .min(value): min[key] = value.toBSON()
            case let .push(value): push[key] = value.toBSON()
            case let .removeAll(value): pullAll[key] = value.toBSON()
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
    
    func count(_ query: MDQuery) -> EventLoopFuture<Int> {
        
        do {
            
            guard let `class` = query.class else { throw MDError.classNotSet }
            
            let filter = try query.filterBSONDocument()
            
            let _query = query.connection.connection.mongoQuery().collection(`class`)
            
            return _query.count().filter(filter).execute()
            
        } catch {
            
            return query.connection.eventLoopGroup.next().makeFailedFuture(error)
        }
    }
    
    func _find(_ query: MDQuery) throws -> DBMongoFindExpression<BSONDocument> {
        
        guard let `class` = query.class else { throw MDError.classNotSet }
        
        let filter = try query.filterBSONDocument()
        
        var _query = query.connection.connection.mongoQuery().collection(`class`).find().filter(filter)
        
        if let sort = query.sort {
            _query = _query.sort(sort.mapValues(DBMongoSortOrder.init))
        }
        if let skip = query.skip {
            _query = _query.skip(skip)
        }
        if let limit = query.limit {
            _query = _query.limit(limit)
        }
        
        if let includes = query.includes {
            let projection = Dictionary(uniqueKeysWithValues: includes.map { ($0, 1) })
            _query = _query.projection(BSONDocument(projection))
        }
        
        return _query
    }
    
    func toArray(_ query: MDQuery) -> EventLoopFuture<[MDObject]> {
        
        do {
            
            guard let `class` = query.class else { throw MDError.classNotSet }
            
            let _query = try self._find(query)
            
            return _query.execute().toArray().flatMapThrowing { try $0.map { try MDObject(class: `class`, data: $0) } }
            
        } catch {
            
            return query.connection.eventLoopGroup.next().makeFailedFuture(error)
        }
    }
    
    func forEach(_ query: MDQuery, _ body: @escaping (MDObject) throws -> Void) -> EventLoopFuture<Void> {
        
        do {
            
            guard let `class` = query.class else { throw MDError.classNotSet }
            
            let _query = try self._find(query)
            
            return _query.execute().forEach { try body(MDObject(class: `class`, data: $0)) }
            
        } catch {
            
            return query.connection.eventLoopGroup.next().makeFailedFuture(error)
        }
    }
    
    func first(_ query: MDQuery) -> EventLoopFuture<MDObject?> {
        
        do {
            
            guard let `class` = query.class else { throw MDError.classNotSet }
            
            let filter = try query.filterBSONDocument()
            
            var _query = query.connection.connection.mongoQuery().collection(`class`).findOne().filter(filter)
            
            if let sort = query.sort {
                _query = _query.sort(sort.mapValues(DBMongoSortOrder.init))
            }
            
            if let includes = query.includes {
                let projection = Dictionary(uniqueKeysWithValues: includes.map { ($0, 1) })
                _query = _query.projection(BSONDocument(projection))
            }
            
            return _query.execute().flatMapThrowing { try $0.map { try MDObject(class: `class`, data: $0) } }
            
        } catch {
            
            return query.connection.eventLoopGroup.next().makeFailedFuture(error)
        }
    }
    
    func findOneAndUpdate(_ query: MDQuery, _ update: [String : MDUpdateOperation], _ returning: MDQueryReturning) -> EventLoopFuture<MDObject?> {
        
        do {
            
            guard let `class` = query.class else { throw MDError.classNotSet }
            
            let filter = try query.filterBSONDocument()
            
            var _query = query.connection.connection.mongoQuery().collection(`class`).findOneAndUpdate().filter(filter)
            
            _query = try _query.update(update.toBSONDocument())
            
            switch returning {
            case .before: _query = _query.returnDocument(.before)
            case .after: _query = _query.returnDocument(.after)
            }
            
            if let sort = query.sort {
                _query = _query.sort(sort.mapValues(DBMongoSortOrder.init))
            }
            
            if let includes = query.includes {
                let projection = Dictionary(uniqueKeysWithValues: includes.map { ($0, 1) })
                _query = _query.projection(BSONDocument(projection))
            }
            
            return _query.execute().flatMapThrowing { try $0.map { try MDObject(class: `class`, data: $0) } }
            
        } catch {
            
            return query.connection.eventLoopGroup.next().makeFailedFuture(error)
        }
    }
    
    func findOneAndUpsert(_ query: MDQuery, _ update: [String : MDUpdateOperation], _ setOnInsert: [String : MDData], _ returning: MDQueryReturning) -> EventLoopFuture<MDObject?> {
        
        do {
            
            guard let `class` = query.class else { throw MDError.classNotSet }
            
            let filter = try query.filterBSONDocument()
            
            var _query = query.connection.connection.mongoQuery().collection(`class`).findOneAndUpdate().filter(filter)
            
            var _update = try update.toBSONDocument()
            
            if !setOnInsert.isEmpty {
                var setOnInsert = setOnInsert
                setOnInsert["_id"] = MDData(objectIDGenerator())
                _update["$setOnInsert"] = setOnInsert.toBSON()
            }
            
            _query = _query.update(_update)
            _query = _query.upsert(true)
            
            switch returning {
            case .before: _query = _query.returnDocument(.before)
            case .after: _query = _query.returnDocument(.after)
            }
            
            if let sort = query.sort {
                _query = _query.sort(sort.mapValues(DBMongoSortOrder.init))
            }
            
            if let includes = query.includes {
                let projection = Dictionary(uniqueKeysWithValues: includes.map { ($0, 1) })
                _query = _query.projection(BSONDocument(projection))
            }
            
            return _query.execute().flatMapThrowing { try $0.map { try MDObject(class: `class`, data: $0) } }
            
        } catch {
            
            return query.connection.eventLoopGroup.next().makeFailedFuture(error)
        }
    }
    
    func findOneAndDelete(_ query: MDQuery) -> EventLoopFuture<MDObject?> {
        
        do {
            
            guard let `class` = query.class else { throw MDError.classNotSet }
            
            let filter = try query.filterBSONDocument()
            
            var _query = query.connection.connection.mongoQuery().collection(`class`).findOneAndDelete().filter(filter)
            
            if let sort = query.sort {
                _query = _query.sort(sort.mapValues(DBMongoSortOrder.init))
            }
            
            if let includes = query.includes {
                let projection = Dictionary(uniqueKeysWithValues: includes.map { ($0, 1) })
                _query = _query.projection(BSONDocument(projection))
            }
            
            return _query.execute().flatMapThrowing { try $0.map { try MDObject(class: `class`, data: $0) } }
            
        } catch {
            
            return query.connection.eventLoopGroup.next().makeFailedFuture(error)
        }
    }
    
    func deleteAll(_ query: MDQuery) -> EventLoopFuture<Int?> {
        
        do {
            
            guard let `class` = query.class else { throw MDError.classNotSet }
            
            let filter = try query.filterBSONDocument()
            
            let _query = query.connection.connection.mongoQuery().collection(`class`)
            
            return _query.deleteMany().filter(filter).execute().map { $0?.deletedCount }
            
        } catch {
            
            return query.connection.eventLoopGroup.next().makeFailedFuture(error)
        }
    }
    
    func insert(_ connection: MDConnection, _ class: String, _ values: [String: MDData]) -> EventLoopFuture<MDObject> {
        
        var data = values
        data["_id"] = MDData(objectIDGenerator())
        
        let _values = BSONDocument(data.mapValues { $0.toBSON() })
        
        return connection.connection.mongoQuery().collection(`class`)
            .insertOne()
            .value(_values)
            .execute()
            .flatMapThrowing { result in
                
                guard let id = result?.insertedID.stringValue else { throw MDError.unknown }
                
                return MDObject(class: `class`, id: id, data: values)
            }
    }
    
    func withTransaction<T>(_ connection: MDConnection, _ transactionBody: @escaping () throws -> EventLoopFuture<T>) -> EventLoopFuture<T> {
        
        return connection.connection.mongoQuery().withTransaction { _ in try transactionBody() }
    }
}

extension MongoDBDriver {
    
    func createTable(_ connection: MDConnection, _ table: MDSQLTable) -> EventLoopFuture<Void> {
        
        return connection.connection.mongoQuery().createCollection(table.name).execute().map { _ in }
    }
    
    func dropTable(_ connection: MDConnection, _ table: String) -> EventLoopFuture<Void> {
        
        return connection.connection.mongoQuery().collection(table).drop().execute()
    }
    
    func dropColumns(_ connection: MDConnection, _ table: String, _ columns: [String]) -> EventLoopFuture<Void> {
        
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
        
        return connection.connection.mongoQuery().collection(table).createIndex().index(keys).name(index.name).execute().map { _ in }
    }
    
    func dropIndex(_ connection: MDConnection, _ table: String, _ index: String) -> EventLoopFuture<Void> {
        
        return connection.connection.mongoQuery().collection(table).dropIndex().index(index).execute()
    }
}
