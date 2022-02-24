//
//  MDFindExpression.swift
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

public struct MDFindExpression: MDExpressionProtocol {
    
    public let connection: MDConnection
    
    public let `class`: String
    
    var filters: [MDPredicateExpression] = []
    
    var sort: OrderedDictionary<MDQueryKey, MDSortOrderOption> = [:]
    
    var skip: Int = 0
    
    var limit: Int = .max
    
    var includes: Set<MDQueryKey>?
}

extension MDQuery {
    
    public func find(_ class: String) -> MDFindExpression {
        return MDFindExpression(connection: connection, class: `class`)
    }
}

extension MDFindExpression {
    
    public func count() -> EventLoopFuture<Int> {
        return self.connection.driver.count(self)
    }
}

extension MDFindExpression {
    
    public func toArray() -> EventLoopFuture<[MDObject]> {
        return self.connection.driver.toArray(self)
    }
    
    public func forEach(_ body: @escaping (MDObject) throws -> Void) -> EventLoopFuture<Void> {
        return self.connection.driver.forEach(self, body)
    }
    
    public func first() -> EventLoopFuture<MDObject?> {
        return self.connection.driver.first(self)
    }
}

extension MDFindExpression {
    
    public func delete() -> EventLoopFuture<Int?> {
        return self.connection.driver.deleteAll(self)
    }
}

extension MDFindExpression {
    
    public func filter(_ filter: MDPredicateExpression) -> Self {
        var result = self
        result.filters.append(filter)
        return result
    }
    
    public func filter(_ filter: [MDPredicateExpression]) -> Self {
        var result = self
        result.filters.append(contentsOf: filter)
        return result
    }
    
    public func filter(_ predicate: (MDPredicateBuilder) -> MDPredicateExpression) -> Self {
        var result = self
        result.filters.append(predicate(MDPredicateBuilder()))
        return result
    }
    
    public func skip(_ skip: Int) -> Self {
        var result = self
        result.skip = skip
        return result
    }
    
    public func limit(_ limit: Int) -> Self {
        var result = self
        result.limit = limit
        return result
    }
    
    public func sort(_ sort: OrderedDictionary<MDQueryKey, MDSortOrderOption>) -> Self {
        var result = self
        result.sort = sort
        return result
    }
    
    public func includes(_ keys: MDQueryKey ...) -> Self {
        var result = self
        result.includes = includes?.union(keys) ?? Set(keys)
        return result
    }
    
    public func includes<S: Sequence>(_ keys: S) -> Self where S.Element == MDQueryKey {
        var result = self
        result.includes = includes?.union(keys) ?? Set(keys)
        return result
    }
}

extension MDFindExpression {
    
    public func sort(_ sort: OrderedDictionary<String, MDSortOrderOption>) -> Self {
        return self.sort(OrderedDictionary(sort.map { (MDQueryKey(key: $0), $1) }) { _, rhs in rhs })
    }
    
    public func includes(_ keys: String ...) -> Self {
        return self.includes(keys.map { MDQueryKey(key: $0) })
    }
    
    public func includes<S: Sequence>(_ keys: S) -> Self where S.Element == String {
        return self.includes(keys.map { MDQueryKey(key: $0) })
    }
}
