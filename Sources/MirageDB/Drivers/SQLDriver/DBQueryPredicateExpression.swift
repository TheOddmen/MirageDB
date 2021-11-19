//
//  DBQueryPredicateExpression.swift
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

extension DBQueryPredicateExpression {
    
    init(_ expression: MDPredicateExpression) {
        switch expression {
        case let .not(expr): self = .not(DBQueryPredicateExpression(expr))
        case let .equal(lhs, rhs): self = .equal(DBQueryPredicateValue(lhs), DBQueryPredicateValue(rhs))
        case let .notEqual(lhs, rhs): self = .notEqual(DBQueryPredicateValue(lhs), DBQueryPredicateValue(rhs))
        case let .lessThan(lhs, rhs): self = .lessThan(DBQueryPredicateValue(lhs), DBQueryPredicateValue(rhs))
        case let .greaterThan(lhs, rhs): self = .greaterThan(DBQueryPredicateValue(lhs), DBQueryPredicateValue(rhs))
        case let .lessThanOrEqualTo(lhs, rhs): self = .lessThanOrEqualTo(DBQueryPredicateValue(lhs), DBQueryPredicateValue(rhs))
        case let .greaterThanOrEqualTo(lhs, rhs): self = .greaterThanOrEqualTo(DBQueryPredicateValue(lhs), DBQueryPredicateValue(rhs))
        case let .containsIn(lhs, rhs): self = .containsIn(DBQueryPredicateValue(lhs), DBQueryPredicateValue(rhs))
        case let .notContainsIn(lhs, rhs): self = .notContainsIn(DBQueryPredicateValue(lhs), DBQueryPredicateValue(rhs))
        case let .between(x, from, to): self = .between(DBQueryPredicateValue(x), DBQueryPredicateValue(from), DBQueryPredicateValue(to))
        case let .notBetween(x, from, to): self = .notBetween(DBQueryPredicateValue(x), DBQueryPredicateValue(from), DBQueryPredicateValue(to))
        case let .startsWith(value, pattern): self = .startsWith(DBQueryPredicateKey(value), pattern)
        case let .endsWith(value, pattern): self = .endsWith(DBQueryPredicateKey(value), pattern)
        case let .contains(value, pattern): self = .contains(DBQueryPredicateKey(value), pattern)
        case let .and(list): self = .and(list.map(DBQueryPredicateExpression.init))
        case let .or(list): self = .or(list.map(DBQueryPredicateExpression.init))
        }
    }
}

extension DBQueryPredicateValue {
    
    fileprivate init(_ value: MDPredicateValue) {
        switch value {
        case .id: self = .objectId
        case let .key(key): self = .key(key)
        case let .value(value): self = .value(value.toMDData().toSQLData())
        }
    }
}

extension DBQueryPredicateKey {
    
    fileprivate init(_ value: MDPredicateKey) {
        switch value {
        case .id: self = .objectId
        case let .key(key): self = .key(key)
        }
    }
}
