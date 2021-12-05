//
//  MDFindOneExpression.swift
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

public struct MDFindOneExpression: MDExpressionProtocol {
    
    public let connection: MDConnection
    
    var `class`: String?
    
    var filters: [MDPredicateExpression] = []
    
    var sort: OrderedDictionary<String, MDSortOrderOption> = [:]
    
    var includes: Set<String> = []
    
    var returning: MDReturningOption = .after
}

extension MDQuery {
    
    public func findOne(_ class: String) -> MDFindOneExpression {
        return MDFindOneExpression(connection: connection, class: `class`)
    }
}

extension MDFindOneExpression {
    
    public func update(_ update: [String: MDDataConvertible]) -> EventLoopFuture<MDObject?> {
        return self.update(update.mapValues { .set($0.toMDData()) })
    }
    
    public func update(_ update: [String: MDUpdateOption]) -> EventLoopFuture<MDObject?> {
        return self.connection.driver.findOneAndUpdate(self, update)
    }
}

extension MDFindOneExpression {
    
    public func upsert(_ update: [String: MDDataConvertible], setOnInsert: [String: MDDataConvertible] = [:]) -> EventLoopFuture<MDObject?> {
        return self.upsert(update.mapValues { .set($0.toMDData()) }, setOnInsert: setOnInsert)
    }
    
    public func upsert(_ update: [String: MDUpdateOption], setOnInsert: [String: MDDataConvertible] = [:]) -> EventLoopFuture<MDObject?> {
        return self.connection.driver.findOneAndUpsert(self, update, setOnInsert.mapValues { $0.toMDData() })
    }
}

extension MDFindOneExpression {
    
    public func delete() -> EventLoopFuture<MDObject?> {
        return self.connection.driver.findOneAndDelete(self)
    }
}

extension MDFindOneExpression {
    
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
    
    public func sort(_ sort: OrderedDictionary<String, MDSortOrderOption>) -> Self {
        var result = self
        result.sort = sort
        return result
    }
    
    public func includes(_ keys: String ...) -> Self {
        var result = self
        result.includes = includes.union(keys)
        return result
    }
    
    public func includes<S: Sequence>(_ keys: S) -> Self where S.Element == String {
        var result = self
        result.includes = includes.union(keys)
        return result
    }
    
    public func returning(_ returning: MDReturningOption) -> Self {
        var result = self
        result.returning = returning
        return result
    }
}
