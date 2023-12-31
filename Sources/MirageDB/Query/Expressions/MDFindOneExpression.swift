//
//  MDFindOneExpression.swift
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

public struct MDFindOneExpression: MDExpressionProtocol, @unchecked Sendable {
    
    public let connection: MDConnection
    
    public let `class`: String
    
    var filters: [MDPredicateExpression] = []
    
    var sort: OrderedDictionary<MDQueryKey, MDSortOrderOption> = [:]
    
    var includes: Set<MDQueryKey>?
    
    var returning: MDReturningOption = .after
    
    var objectIDGenerator: (() -> String)?
}

extension MDQuery {
    
    public func findOne(_ class: String) -> MDFindOneExpression {
        return MDFindOneExpression(connection: connection, class: `class`)
    }
}

extension MDFindOneExpression {
    
    @discardableResult
    public func update(_ update: [MDQueryKey: MDDataConvertible]) async throws -> MDObject? {
        return try await self.update(update.mapValues { .set($0.toMDData()) })
    }
    
    @discardableResult
    public func update(_ update: [MDQueryKey: MDUpdateOption]) async throws -> MDObject? {
        return try await self.connection.driver.findOneAndUpdate(self, update)
    }
}

extension MDFindOneExpression {
    
    @discardableResult
    public func upsert(_ upsert: [MDQueryKey: MDDataConvertible]) async throws -> MDObject? {
        return try await self.upsert(upsert.mapValues { .set($0.toMDData()) })
    }
    
    @discardableResult
    public func upsert(_ upsert: [MDQueryKey: MDUpsertOption]) async throws -> MDObject? {
        return try await self.upsert(upsert.compactMapValues { $0.update }, setOnInsert: upsert.compactMapValues { $0.setOnInsert })
    }
    
    @discardableResult
    public func upsert(_ update: [MDQueryKey: MDDataConvertible], setOnInsert: [MDQueryKey: MDDataConvertible]) async throws -> MDObject? {
        return try await self.upsert(update.mapValues { .set($0) }, setOnInsert: setOnInsert)
    }
    
    @discardableResult
    public func upsert(_ update: [MDQueryKey: MDUpdateOption], setOnInsert: [MDQueryKey: MDDataConvertible]) async throws -> MDObject? {
        return try await self.connection.driver.findOneAndUpsert(self, update, setOnInsert)
    }
}

extension MDFindOneExpression {
    
    @discardableResult
    public func delete() async throws -> MDObject? {
        return try await self.connection.driver.findOneAndDelete(self)
    }
}

extension MDFindOneExpression {
    
    public func objectID(with generator: @escaping () -> String) -> Self {
        var result = self
        result.objectIDGenerator = generator
        return result
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
    
    public func returning(_ returning: MDReturningOption) -> Self {
        var result = self
        result.returning = returning
        return result
    }
}

extension MDFindOneExpression {
    
    @discardableResult
    public func update(_ update: [String: MDDataConvertible]) async throws -> MDObject? {
        return try await self.update(Dictionary(update.map { (MDQueryKey(key: $0), $1) }) { _, rhs in rhs })
    }
    
    @discardableResult
    public func update(_ update: [String: MDUpdateOption]) async throws -> MDObject? {
        return try await self.update(Dictionary(update.map { (MDQueryKey(key: $0), $1) }) { _, rhs in rhs })
    }
}

extension MDFindOneExpression {
    
    @discardableResult
    public func upsert(_ upsert: [String: MDDataConvertible]) async throws -> MDObject? {
        return try await self.upsert(Dictionary(upsert.map { (MDQueryKey(key: $0), $1) }) { _, rhs in rhs })
    }
    
    @discardableResult
    public func upsert(_ upsert: [String: MDUpsertOption]) async throws -> MDObject? {
        return try await self.upsert(Dictionary(upsert.map { (MDQueryKey(key: $0), $1) }) { _, rhs in rhs })
    }
    
    @discardableResult
    public func upsert(_ update: [String: MDDataConvertible], setOnInsert: [String: MDDataConvertible]) async throws -> MDObject? {
        return try await self.upsert(
            Dictionary(update.map { (MDQueryKey(key: $0), $1) }) { _, rhs in rhs },
            setOnInsert: Dictionary(setOnInsert.map { (MDQueryKey(key: $0), $1) }) { _, rhs in rhs }
        )
    }
    
    @discardableResult
    public func upsert(_ update: [String: MDUpdateOption], setOnInsert: [String: MDDataConvertible]) async throws -> MDObject? {
        return try await self.upsert(
            Dictionary(update.map { (MDQueryKey(key: $0), $1) }) { _, rhs in rhs },
            setOnInsert: Dictionary(setOnInsert.map { (MDQueryKey(key: $0), $1) }) { _, rhs in rhs }
        )
    }
}

extension MDFindOneExpression {
    
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
