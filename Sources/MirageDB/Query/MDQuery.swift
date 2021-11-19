//
//  MDQuery.swift
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

public struct MDQuery {
    
    public let connection: MDConnection
    
    var `class`: String?
    
    var filters: [MDPredicateExpression] = []
    
    var sort: OrderedDictionary<String, MDSortOrder>?
    
    var skip: Int?
    
    var limit: Int?
    
    var includes: Set<String>?
}

extension MDConnection {
    
    public func query() -> MDQuery {
        return MDQuery(connection: self)
    }
}

extension MDQuery {
    
    public func `class`(_ class: String) -> MDQuery {
        var result = self
        result.class = `class`
        return result
    }
}

extension MDQuery {
    
    public func insert(_ data: [String: MDData]) -> EventLoopFuture<MDObject> {
        
        do {
            
            guard let `class` = self.class else { throw MDError.classNotSet }
            
            return self.connection.driver.insert(connection, `class`, data)
            
        } catch {
            
            return self.connection.eventLoopGroup.next().makeFailedFuture(error)
        }
    }
}

extension MDQuery {
    
    public func filter(
        _ predicate: (MDPredicateBuilder) -> MDPredicateExpression
    ) -> MDQuery {
        var result = self
        result.filters = filters + [predicate(.init())]
        return result
    }
}

extension MDQuery {
    
    public func sort(_ sort: OrderedDictionary<String, MDSortOrder>) -> MDQuery {
        var result = self
        result.sort = sort
        return result
    }
    
    public func ascending(_ keys: String ...) -> MDQuery {
        var sort: OrderedDictionary<String, MDSortOrder> = [:]
        for key in keys {
            sort[key] = .ascending
        }
        return self.sort(sort)
    }
    
    public func descending(_ keys: String ...) -> MDQuery {
        var sort: OrderedDictionary<String, MDSortOrder> = [:]
        for key in keys {
            sort[key] = .descending
        }
        return self.sort(sort)
    }
}

extension MDQuery {
    
    public func skip(_ skip: Int) -> MDQuery {
        var result = self
        result.skip = skip
        return result
    }
    
    public func limit(_ limit: Int) -> MDQuery {
        var result = self
        result.limit = limit
        return result
    }
}

extension MDQuery {
    
    public func includes(_ keys: String ...) -> MDQuery {
        var result = self
        result.includes = includes?.union(keys) ?? Set(keys)
        return result
    }
    
    public func includes<S: Sequence>(_ keys: S) -> MDQuery where S.Element == String {
        var result = self
        result.includes = includes?.union(keys) ?? Set(keys)
        return result
    }
}

extension MDQuery {
    
    public func count() -> EventLoopFuture<Int> {
        return self.connection.driver.count(self)
    }
    
    public func toArray() -> EventLoopFuture<[MDObject]> {
        return self.connection.driver.toArray(self)
    }
    
    public func forEach(_ body: @escaping (MDObject) throws -> Void) -> EventLoopFuture<Void> {
        return self.connection.driver.forEach(self, body)
    }
}

extension MDQuery {
    
    public func first() -> EventLoopFuture<MDObject?> {
        return self.connection.driver.first(self)
    }
}

extension MDQuery {
    
    public func findOneAndUpdate(_ update: [String: MDUpdateOperation], returning: MDQueryReturning = .after) -> EventLoopFuture<MDObject?> {
        return self.connection.driver.findOneAndUpdate(self, update, returning)
    }
    
    public func findOneAndUpdate<T: MDDataConvertible>(_ update: [String: T], returning: MDQueryReturning = .after) -> EventLoopFuture<MDObject?> {
        return self.findOneAndUpdate(update.mapValues { .set($0.toMDData()) }, returning: returning)
    }
    
    public func findOneAndUpsert(_ update: [String: MDUpdateOperation] = [:], setOnInsert: [String: MDData] = [:], returning: MDQueryReturning = .after) -> EventLoopFuture<MDObject?> {
        return self.connection.driver.findOneAndUpsert(self, update, setOnInsert, returning)
    }
    
    public func findOneAndUpsert<T: MDDataConvertible>(_ update: [String: T], setOnInsert: [String: MDData], returning: MDQueryReturning = .after) -> EventLoopFuture<MDObject?> {
        return self.findOneAndUpsert(update.mapValues { .set($0.toMDData()) }, setOnInsert: setOnInsert, returning: returning)
    }
}

extension MDQuery {
    
    public func findOneAndDelete() -> EventLoopFuture<MDObject?> {
        return self.connection.driver.findOneAndDelete(self)
    }
    
    public func deleteAll() -> EventLoopFuture<Int?> {
        return self.connection.driver.deleteAll(self)
    }
    
}
