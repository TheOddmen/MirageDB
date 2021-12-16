//
//  MDPredicateExpression.swift
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

@frozen
public indirect enum MDPredicateExpression {
    
    case not(MDPredicateExpression)
    
    case equal(MDPredicateValue, MDPredicateValue)
    
    case notEqual(MDPredicateValue, MDPredicateValue)
    
    case lessThan(MDPredicateValue, MDPredicateValue)
    
    case greaterThan(MDPredicateValue, MDPredicateValue)
    
    case lessThanOrEqualTo(MDPredicateValue, MDPredicateValue)
    
    case greaterThanOrEqualTo(MDPredicateValue, MDPredicateValue)
    
    case containsIn(MDPredicateValue, MDPredicateValue)
    
    case notContainsIn(MDPredicateValue, MDPredicateValue)
    
    case between(MDPredicateValue, MDPredicateValue, MDPredicateValue)
    
    case notBetween(MDPredicateValue, MDPredicateValue, MDPredicateValue)
    
    case startsWith(MDPredicateKey, String)
    
    case endsWith(MDPredicateKey, String)
    
    case contains(MDPredicateKey, String)
    
    case and([MDPredicateExpression])
    
    case or([MDPredicateExpression])
}

@frozen
public enum MDPredicateValue {
    
    case id
    
    case createdAt
    
    case updatedAt
    
    case key(String)
    
    case value(MDDataConvertible)
}

extension MDPredicateValue {
    
    @inlinable
    static func key(_ key: MDPredicateKey) -> MDPredicateValue {
        switch key {
        case .id: return .id
        case .createdAt: return .createdAt
        case .updatedAt: return .updatedAt
        case let .key(key): return .key(key)
        }
    }
}

@inlinable
public func == (lhs: MDPredicateKey, rhs: MDPredicateKey) -> MDPredicateExpression {
    return .equal(.key(lhs), .key(rhs))
}

@inlinable
public func != (lhs: MDPredicateKey, rhs: MDPredicateKey) -> MDPredicateExpression {
    return .notEqual(.key(lhs), .key(rhs))
}

@inlinable
public func < (lhs: MDPredicateKey, rhs: MDPredicateKey) -> MDPredicateExpression {
    return .lessThan(.key(lhs), .key(rhs))
}

@inlinable
public func > (lhs: MDPredicateKey, rhs: MDPredicateKey) -> MDPredicateExpression {
    return .greaterThan(.key(lhs), .key(rhs))
}

@inlinable
public func <= (lhs: MDPredicateKey, rhs: MDPredicateKey) -> MDPredicateExpression {
    return .lessThanOrEqualTo(.key(lhs), .key(rhs))
}

@inlinable
public func >= (lhs: MDPredicateKey, rhs: MDPredicateKey) -> MDPredicateExpression {
    return .greaterThanOrEqualTo(.key(lhs), .key(rhs))
}

@inlinable
public func == (lhs: MDPredicateKey, rhs: _OptionalNilComparisonType) -> MDPredicateExpression {
    return .equal(.key(lhs), .value(nil as MDData))
}

@inlinable
public func != (lhs: MDPredicateKey, rhs: _OptionalNilComparisonType) -> MDPredicateExpression {
    return .notEqual(.key(lhs), .value(nil as MDData))
}

@inlinable
public func == <T: MDDataConvertible>(lhs: MDPredicateKey, rhs: T) -> MDPredicateExpression {
    return .equal(.key(lhs), .value(rhs))
}

@inlinable
public func != <T: MDDataConvertible>(lhs: MDPredicateKey, rhs: T) -> MDPredicateExpression {
    return .notEqual(.key(lhs), .value(rhs))
}

@inlinable
public func < <T: MDDataConvertible>(lhs: MDPredicateKey, rhs: T) -> MDPredicateExpression {
    return .lessThan(.key(lhs), .value(rhs))
}

@inlinable
public func > <T: MDDataConvertible>(lhs: MDPredicateKey, rhs: T) -> MDPredicateExpression {
    return .greaterThan(.key(lhs), .value(rhs))
}

@inlinable
public func <= <T: MDDataConvertible>(lhs: MDPredicateKey, rhs: T) -> MDPredicateExpression {
    return .lessThanOrEqualTo(.key(lhs), .value(rhs))
}

@inlinable
public func >= <T: MDDataConvertible>(lhs: MDPredicateKey, rhs: T) -> MDPredicateExpression {
    return .greaterThanOrEqualTo(.key(lhs), .value(rhs))
}

@inlinable
public func == (lhs: _OptionalNilComparisonType, rhs: MDPredicateKey) -> MDPredicateExpression {
    return .equal(.value(nil as MDData), .key(rhs))
}

@inlinable
public func != (lhs: _OptionalNilComparisonType, rhs: MDPredicateKey) -> MDPredicateExpression {
    return .notEqual(.value(nil as MDData), .key(rhs))
}

@inlinable
public func == <T: MDDataConvertible>(lhs: T, rhs: MDPredicateKey) -> MDPredicateExpression {
    return .equal(.value(lhs), .key(rhs))
}

@inlinable
public func != <T: MDDataConvertible>(lhs: T, rhs: MDPredicateKey) -> MDPredicateExpression {
    return .notEqual(.value(lhs), .key(rhs))
}

@inlinable
public func < <T: MDDataConvertible>(lhs: T, rhs: MDPredicateKey) -> MDPredicateExpression {
    return .lessThan(.value(lhs), .key(rhs))
}

@inlinable
public func > <T: MDDataConvertible>(lhs: T, rhs: MDPredicateKey) -> MDPredicateExpression {
    return .greaterThan(.value(lhs), .key(rhs))
}

@inlinable
public func <= <T: MDDataConvertible>(lhs: T, rhs: MDPredicateKey) -> MDPredicateExpression {
    return .lessThanOrEqualTo(.value(lhs), .key(rhs))
}

@inlinable
public func >= <T: MDDataConvertible>(lhs: T, rhs: MDPredicateKey) -> MDPredicateExpression {
    return .greaterThanOrEqualTo(.value(lhs), .key(rhs))
}

@inlinable
public func ~= (lhs: MDPredicateKey, rhs: MDPredicateKey) -> MDPredicateExpression {
    return .containsIn(.key(rhs), .key(lhs))
}

@inlinable
public func ~= <T: MDDataConvertible>(lhs: MDPredicateKey, rhs: T) -> MDPredicateExpression {
    return .containsIn(.value(rhs), .key(lhs))
}

@inlinable
public func ~= <C: Collection>(lhs: C, rhs: MDPredicateKey) -> MDPredicateExpression where C.Element: MDDataConvertible {
    return .containsIn(.key(rhs), .value(MDData(lhs.map { $0.toMDData() })))
}

@inlinable
public func ~= <T: MDDataConvertible>(lhs: Range<T>, rhs: MDPredicateKey) -> MDPredicateExpression {
    return .between(.key(rhs), .value(lhs.lowerBound), .value(lhs.upperBound))
}

@inlinable
public func ~= <T: MDDataConvertible>(lhs: ClosedRange<T>, rhs: MDPredicateKey) -> MDPredicateExpression {
    return lhs.lowerBound <= rhs && rhs <= lhs.upperBound
}

@inlinable
public func ~= <T: MDDataConvertible>(lhs: PartialRangeFrom<T>, rhs: MDPredicateKey) -> MDPredicateExpression {
    return lhs.lowerBound <= rhs
}

@inlinable
public func ~= <T: MDDataConvertible>(lhs: PartialRangeUpTo<T>, rhs: MDPredicateKey) -> MDPredicateExpression {
    return rhs < lhs.upperBound
}

@inlinable
public func ~= <T: MDDataConvertible>(lhs: PartialRangeThrough<T>, rhs: MDPredicateKey) -> MDPredicateExpression {
    return rhs <= lhs.upperBound
}

@inlinable
public func =~ (lhs: MDPredicateKey, rhs: MDPredicateKey) -> MDPredicateExpression {
    return .containsIn(.key(lhs), .key(rhs))
}

@inlinable
public func =~ <T: MDDataConvertible>(lhs: T, rhs: MDPredicateKey) -> MDPredicateExpression {
    return .containsIn(.value(lhs), .key(rhs))
}

@inlinable
public func =~ <C: Collection>(lhs: MDPredicateKey, rhs: C) -> MDPredicateExpression where C.Element: MDDataConvertible {
    return .containsIn(.key(lhs), .value(MDData(rhs.map { $0.toMDData() })))
}

@inlinable
public func =~ <T: MDDataConvertible>(lhs: MDPredicateKey, rhs: Range<T>) -> MDPredicateExpression {
    return .between(.key(lhs), .value(rhs.lowerBound), .value(rhs.upperBound))
}

@inlinable
public func =~ <T: MDDataConvertible>(lhs: MDPredicateKey, rhs: ClosedRange<T>) -> MDPredicateExpression {
    return rhs.lowerBound <= lhs && lhs <= rhs.upperBound
}

@inlinable
public func =~ <T: MDDataConvertible>(lhs: MDPredicateKey, rhs: PartialRangeFrom<T>) -> MDPredicateExpression {
    return rhs.lowerBound <= lhs
}

@inlinable
public func =~ <T: MDDataConvertible>(lhs: MDPredicateKey, rhs: PartialRangeUpTo<T>) -> MDPredicateExpression {
    return lhs < rhs.upperBound
}

@inlinable
public func =~ <T: MDDataConvertible>(lhs: MDPredicateKey, rhs: PartialRangeThrough<T>) -> MDPredicateExpression {
    return lhs <= rhs.upperBound
}

@inlinable
public prefix func !(x: MDPredicateExpression) -> MDPredicateExpression {
    return .not(x)
}

@inlinable
public func && (lhs: MDPredicateExpression, rhs: MDPredicateExpression) -> MDPredicateExpression {
    return .and([lhs, rhs])
}

@inlinable
public func || (lhs: MDPredicateExpression, rhs: MDPredicateExpression) -> MDPredicateExpression {
    return .or([lhs, rhs])
}
