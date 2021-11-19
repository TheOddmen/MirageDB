//
//  MongoPredicateExpression.swift
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

extension MongoPredicateExpression {
    
    init(_ expression: MDPredicateExpression) throws {
        switch expression {
        case let .not(expr): self = try .not(MongoPredicateExpression(expr))
        case let .equal(lhs, rhs): self = try .equal(MongoPredicateValue(lhs), MongoPredicateValue(rhs))
        case let .notEqual(lhs, rhs): self = try .notEqual(MongoPredicateValue(lhs), MongoPredicateValue(rhs))
        case let .lessThan(lhs, rhs): self = try .lessThan(MongoPredicateValue(lhs), MongoPredicateValue(rhs))
        case let .greaterThan(lhs, rhs): self = try .greaterThan(MongoPredicateValue(lhs), MongoPredicateValue(rhs))
        case let .lessThanOrEqualTo(lhs, rhs): self = try .lessThanOrEqualTo(MongoPredicateValue(lhs), MongoPredicateValue(rhs))
        case let .greaterThanOrEqualTo(lhs, rhs): self = try .greaterThanOrEqualTo(MongoPredicateValue(lhs), MongoPredicateValue(rhs))
        case let .containsIn(lhs, rhs): self = try .containsIn(MongoPredicateValue(lhs), MongoPredicateValue(rhs))
        case let .notContainsIn(lhs, rhs): self = try .notContainsIn(MongoPredicateValue(lhs), MongoPredicateValue(rhs))
            
        case let .between(x, from, to):
            
            self = try .and([
                .greaterThanOrEqualTo(MongoPredicateValue(from), MongoPredicateValue(x)),
                .lessThanOrEqualTo(MongoPredicateValue(to), MongoPredicateValue(x)),
            ])
            
        case let .notBetween(x, from, to):
            
            self = try .or([
                .lessThan(MongoPredicateValue(from), MongoPredicateValue(x)),
                .greaterThan(MongoPredicateValue(to), MongoPredicateValue(x)),
            ])
            
        case let .and(list): self = try .and(list.map(MongoPredicateExpression.init))
        case let .or(list): self = try .or(list.map(MongoPredicateExpression.init))
        }
    }
}

extension MongoPredicateValue {
    
    fileprivate init(_ value: MDPredicateValue) throws {
        switch value {
        case .id: self = .key("_id")
        case let .key(key): self = .key(key)
        case let .value(value): self = .value(BSON(value.toMDData()))
        }
    }
}
