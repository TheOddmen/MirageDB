//
//  MDObject.swift
//
//  The MIT License
//  Copyright (c) 2021 - 2022 The Oddmen Technology Limited. All rights reserved.
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
    
    public let `class`: String
    
    public let id: String?
    
    public let createdAt: Date?
    
    public let updatedAt: Date?
    
    var data: [String: MDData]
    
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
        self.data = data
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
    
    public func fetch<S: Sequence>(_ keys: S, on connection: MDConnection) -> EventLoopFuture<MDObject> where S.Element == String {
        
        if let id = self.id {
            
            return connection.query()
                .find(self.class)
                .filter { $0.id == id }
                .includes(keys)
                .first()
                .flatMapThrowing { object in
                    guard let object = object else { throw MDError.objectNotFound }
                    return object
                }
            
        } else {
            return connection.eventLoopGroup.next().makeFailedFuture(MDError.invalidObjectId)
        }
    }
    
    public func fetch(on connection: MDConnection) -> EventLoopFuture<MDObject> {
        
        if let id = self.id {
            
            return connection.query()
                .find(self.class)
                .filter { $0.id == id }
                .first()
                .flatMapThrowing { object in
                    guard let object = object else { throw MDError.objectNotFound }
                    return object
                }
            
        } else {
            return connection.eventLoopGroup.next().makeFailedFuture(MDError.invalidObjectId)
        }
    }
    
    public func save(on connection: MDConnection) -> EventLoopFuture<MDObject> {
        
        if let id = self.id {
            
            return connection.query()
                .findOne(self.class)
                .filter { $0.id == id }
                .includes(self.keys)
                .update(mutated)
                .flatMapThrowing { object in
                    guard let object = object else { throw MDError.objectNotFound }
                    return object
                }
            
        } else {
            
            return connection.driver.insert(connection, `class`, mutated.compactMapValues { $0.value })
        }
    }
    
    public func delete(on connection: MDConnection) -> EventLoopFuture<MDObject> {
        
        if let id = self.id {
            
            return connection.query()
                .findOne(self.class)
                .filter { $0.id == id }
                .includes(self.keys)
                .delete()
                .flatMapThrowing { object in
                    guard let object = object else { throw MDError.objectNotFound }
                    return object
                }
            
        } else {
            return connection.eventLoopGroup.next().makeFailedFuture(MDError.invalidObjectId)
        }
    }
}
