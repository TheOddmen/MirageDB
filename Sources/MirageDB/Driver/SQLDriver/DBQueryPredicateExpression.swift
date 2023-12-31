//
//  DBPredicateExpression.swift
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

extension DBPredicateExpression {
    
    init(_ expression: MDPredicateExpression) {
        switch expression {
        case let .not(expr): self = .not(DBPredicateExpression(expr))
        case let .equal(lhs, rhs): self = .equal(DBPredicateValue(lhs), DBPredicateValue(rhs))
        case let .notEqual(lhs, rhs): self = .notEqual(DBPredicateValue(lhs), DBPredicateValue(rhs))
        case let .lessThan(lhs, rhs): self = .lessThan(DBPredicateValue(lhs), DBPredicateValue(rhs))
        case let .greaterThan(lhs, rhs): self = .greaterThan(DBPredicateValue(lhs), DBPredicateValue(rhs))
        case let .lessThanOrEqualTo(lhs, rhs): self = .lessThanOrEqualTo(DBPredicateValue(lhs), DBPredicateValue(rhs))
        case let .greaterThanOrEqualTo(lhs, rhs): self = .greaterThanOrEqualTo(DBPredicateValue(lhs), DBPredicateValue(rhs))
        case let .containsIn(lhs, rhs): self = .containsIn(DBPredicateValue(lhs), DBPredicateValue(rhs))
        case let .notContainsIn(lhs, rhs): self = .notContainsIn(DBPredicateValue(lhs), DBPredicateValue(rhs))
        case let .between(x, from, to): self = .between(DBPredicateValue(x), DBPredicateValue(from), DBPredicateValue(to))
        case let .notBetween(x, from, to): self = .notBetween(DBPredicateValue(x), DBPredicateValue(from), DBPredicateValue(to))
        case let .startsWith(value, pattern): self = .startsWith(DBPredicateKey(value), pattern)
        case let .endsWith(value, pattern): self = .endsWith(DBPredicateKey(value), pattern)
        case let .contains(value, pattern): self = .contains(DBPredicateKey(value), pattern)
        case let .and(list): self = .and(list.map(DBPredicateExpression.init))
        case let .or(list): self = .or(list.map(DBPredicateExpression.init))
        }
    }
}

extension DBPredicateValue {
    
    fileprivate init(_ value: MDPredicateValue) {
        switch value {
        case let .key(key): self = .key(key)
        case let .value(value): self = .value(value.toMDData().toSQLData())
        }
    }
}

extension DBPredicateKey {
    
    fileprivate init(_ value: MDQueryKey) {
        self = .key(value.key)
    }
}
