//
//  MDQueryKey.swift
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

@frozen
public struct MDQueryKey: Hashable, Sendable {
    
    public var key: String
    
    @inlinable
    public init(key: String) {
        switch key {
        case "id": self.key = "_id"
        case "createdAt": self.key = "_created_at"
        case "updatedAt": self.key = "_updated_at"
        default: self.key = key
        }
    }
}

extension MDQueryKey {
    
    @inlinable
    public static var id: MDQueryKey { MDQueryKey(key: "id") }
    
    @inlinable
    public static var createdAt: MDQueryKey { MDQueryKey(key: "createdAt") }
    
    @inlinable
    public static var updatedAt: MDQueryKey { MDQueryKey(key: "updatedAt") }
    
    @inlinable
    public static func key(_ key: String) -> MDQueryKey { MDQueryKey(key: key) }
}

extension Set where Element == MDQueryKey {
    
    var stringKeys: Set<String> {
        return Set<String>(self.map { $0.key })
    }
}

extension Dictionary where Key == MDQueryKey {
    
    var stringKeys: Dictionary<String, Value> {
        return Dictionary<String, Value>(self.map { ($0.key, $1) }) { _, rhs in rhs }
    }
}

extension OrderedDictionary where Key == MDQueryKey {
    
    var stringKeys: OrderedDictionary<String, Value> {
        return OrderedDictionary<String, Value>(self.map { ($0.key, $1) }) { _, rhs in rhs }
    }
}
