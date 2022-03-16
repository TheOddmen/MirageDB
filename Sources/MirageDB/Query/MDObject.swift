//
//  MDObject.swift
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

public struct MDObject: Hashable, Equatable, Identifiable {
    
    static let _default_fields = ["_id", "_created_at", "_updated_at"]
    
    public let `class`: String
    
    public let id: String?
    
    public let createdAt: Date?
    
    public let updatedAt: Date?
    
    let data: [String: MDData]
    
    var mutated: [String: MDUpdateOption] = [:]
    
    init(
        class: String,
        id: String?,
        createdAt: Date?,
        updatedAt: Date?,
        data: [String: MDData]
    ) {
        self.class = `class`
        self.id = id
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.data = data.filter { !MDObject._default_fields.contains($0.key) }
    }
    
    public init(class: String, id: String? = nil) {
        self.class = `class`
        self.id = id
        self.createdAt = nil
        self.updatedAt = nil
        self.data = [:]
    }
}

extension MDObject {
    
    public static func == (lhs: MDObject, rhs: MDObject) -> Bool {
        return lhs.class == rhs.class && lhs.id == rhs.id
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(self.class)
        hasher.combine(self.id)
    }
}

extension MDObject {
    
    public var keys: Set<String> {
        return Set(data.keys).union(mutated.keys)
    }
    
    public subscript(_ key: String) -> MDData {
        get {
            return mutated[key]?.value ?? data[key] ?? nil
        }
        set {
            mutated[key] = .set(newValue)
        }
    }
}

extension MDObject {
    
    public mutating func set<T: MDDataConvertible>(_ key: String, _ value: T) {
        mutated[key] = .set(value.toMDData())
    }
    
    public mutating func set(_ key: String, _ object: MDObject?) {
        mutated[key] = .set((object?.id).toMDData())
    }
    
    public mutating func increment<T: MDDataConvertible & Numeric>(_ key: String, by amount: T) {
        mutated[key] = .increment(amount.toMDData())
    }
    
    public mutating func multiply<T: MDDataConvertible & Numeric>(_ key: String, by amount: T) {
        mutated[key] = .multiply(amount.toMDData())
    }
    
    public mutating func max<T: MDDataConvertible>(_ key: String, by value: T) {
        mutated[key] = .max(value.toMDData())
    }
    
    public mutating func min<T: MDDataConvertible>(_ key: String, by value: T) {
        mutated[key] = .min(value.toMDData())
    }
    
    public mutating func push<T: MDDataConvertible>(_ key: String, with value: T) {
        mutated[key] = .push(value.toMDData())
    }
    
    public mutating func removeAll<T: MDDataConvertible>(_ key: String, values: [T]) {
        mutated[key] = .removeAll(values.map { $0.toMDData() })
    }
    
    public mutating func popFirst(for key: String) {
        mutated[key] = .popFirst
    }
    
    public mutating func popLast(for key: String) {
        mutated[key] = .popLast
    }
}

extension MDObject {
    
    public mutating func fetch<S: Sequence>(_ keys: S, on connection: MDConnection) async throws where S.Element == MDQueryKey {
        
        guard let id = self.id else { throw MDError.invalidObjectId }
        
        let query = connection.query()
            .find(self.class)
            .filter { $0.id == id }
            .includes(keys)
        
        guard let result = try await query.first() else { throw MDError.objectNotFound }
        
        self = result
    }
    
    public mutating func fetch(on connection: MDConnection) async throws {
        
        guard let id = self.id else { throw MDError.invalidObjectId }
        
        let query = connection.query()
            .find(self.class)
            .filter { $0.id == id }
        
        guard let result = try await query.first() else { throw MDError.objectNotFound }
        
        self = result
    }
    
    public mutating func save(on connection: MDConnection) async throws {
        
        let mutated = Dictionary(self.mutated.map { (MDQueryKey(key: $0), $1) }) { _, rhs in rhs }
        
        if let id = self.id {
            
            let query = connection.query()
                .findOne(self.class)
                .filter { $0.id == id }
                .includes(self.keys.map { MDQueryKey(key: $0) })
            
            guard let result = try await query.update(mutated) else { throw MDError.objectNotFound }
            
            self = result
            
        } else {
            
            self = try await connection.driver.insert(connection, `class`, mutated.compactMapValues { $0.value })
        }
    }
    
    public mutating func delete(on connection: MDConnection) async throws {
        
        guard let id = self.id else { throw MDError.invalidObjectId }
        
        let query = connection.query()
            .findOne(self.class)
            .filter { $0.id == id }
            .includes(self.keys.map { MDQueryKey(key: $0) })
        
        guard let result = try await query.delete() else { throw MDError.objectNotFound }
        
        self = result
    }
}

extension MDObject {
    
    public mutating func fetch<S: Sequence>(_ keys: S, on connection: MDConnection) async throws where S.Element == String {
        try await self.fetch(keys.map { MDQueryKey(key: $0) }, on: connection)
    }
}
