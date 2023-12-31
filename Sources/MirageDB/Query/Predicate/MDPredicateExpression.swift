//
//  MDPredicateExpression.swift
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

@frozen
public indirect enum MDPredicateExpression: Sendable {
    
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
    
    case startsWith(MDQueryKey, String)
    
    case endsWith(MDQueryKey, String)
    
    case contains(MDQueryKey, String)
    
    case and([MDPredicateExpression])
    
    case or([MDPredicateExpression])
}

@frozen
public enum MDPredicateValue: @unchecked Sendable {
    
    case key(String)
    
    case value(MDDataConvertible)
}

extension MDPredicateValue {
    
    @inlinable
    static func key(_ key: MDQueryKey) -> MDPredicateValue {
        return .key(key.key)
    }
}

extension MDPredicateValue {
    
    @inlinable
    public static var id: MDPredicateValue { .key(.id) }
    
    @inlinable
    public static var createdAt: MDPredicateValue { .key(.createdAt) }
    
    @inlinable
    public static var updatedAt: MDPredicateValue { .key(.updatedAt) }
    
}

@inlinable
public func == (lhs: MDQueryKey, rhs: MDQueryKey) -> MDPredicateExpression {
    return .equal(.key(lhs), .key(rhs))
}

@inlinable
public func != (lhs: MDQueryKey, rhs: MDQueryKey) -> MDPredicateExpression {
    return .notEqual(.key(lhs), .key(rhs))
}

@inlinable
public func < (lhs: MDQueryKey, rhs: MDQueryKey) -> MDPredicateExpression {
    return .lessThan(.key(lhs), .key(rhs))
}

@inlinable
public func > (lhs: MDQueryKey, rhs: MDQueryKey) -> MDPredicateExpression {
    return .greaterThan(.key(lhs), .key(rhs))
}

@inlinable
public func <= (lhs: MDQueryKey, rhs: MDQueryKey) -> MDPredicateExpression {
    return .lessThanOrEqualTo(.key(lhs), .key(rhs))
}

@inlinable
public func >= (lhs: MDQueryKey, rhs: MDQueryKey) -> MDPredicateExpression {
    return .greaterThanOrEqualTo(.key(lhs), .key(rhs))
}

@inlinable
public func == (lhs: MDQueryKey, rhs: _OptionalNilComparisonType) -> MDPredicateExpression {
    return .equal(.key(lhs), .value(nil as MDData))
}

@inlinable
public func != (lhs: MDQueryKey, rhs: _OptionalNilComparisonType) -> MDPredicateExpression {
    return .notEqual(.key(lhs), .value(nil as MDData))
}

@inlinable
public func == <T: MDDataConvertible>(lhs: MDQueryKey, rhs: T) -> MDPredicateExpression {
    return .equal(.key(lhs), .value(rhs))
}

@inlinable
public func != <T: MDDataConvertible>(lhs: MDQueryKey, rhs: T) -> MDPredicateExpression {
    return .notEqual(.key(lhs), .value(rhs))
}

@inlinable
public func < <T: MDDataConvertible>(lhs: MDQueryKey, rhs: T) -> MDPredicateExpression {
    return .lessThan(.key(lhs), .value(rhs))
}

@inlinable
public func > <T: MDDataConvertible>(lhs: MDQueryKey, rhs: T) -> MDPredicateExpression {
    return .greaterThan(.key(lhs), .value(rhs))
}

@inlinable
public func <= <T: MDDataConvertible>(lhs: MDQueryKey, rhs: T) -> MDPredicateExpression {
    return .lessThanOrEqualTo(.key(lhs), .value(rhs))
}

@inlinable
public func >= <T: MDDataConvertible>(lhs: MDQueryKey, rhs: T) -> MDPredicateExpression {
    return .greaterThanOrEqualTo(.key(lhs), .value(rhs))
}

@inlinable
public func == (lhs: _OptionalNilComparisonType, rhs: MDQueryKey) -> MDPredicateExpression {
    return .equal(.value(nil as MDData), .key(rhs))
}

@inlinable
public func != (lhs: _OptionalNilComparisonType, rhs: MDQueryKey) -> MDPredicateExpression {
    return .notEqual(.value(nil as MDData), .key(rhs))
}

@inlinable
public func == <T: MDDataConvertible>(lhs: T, rhs: MDQueryKey) -> MDPredicateExpression {
    return .equal(.value(lhs), .key(rhs))
}

@inlinable
public func != <T: MDDataConvertible>(lhs: T, rhs: MDQueryKey) -> MDPredicateExpression {
    return .notEqual(.value(lhs), .key(rhs))
}

@inlinable
public func < <T: MDDataConvertible>(lhs: T, rhs: MDQueryKey) -> MDPredicateExpression {
    return .lessThan(.value(lhs), .key(rhs))
}

@inlinable
public func > <T: MDDataConvertible>(lhs: T, rhs: MDQueryKey) -> MDPredicateExpression {
    return .greaterThan(.value(lhs), .key(rhs))
}

@inlinable
public func <= <T: MDDataConvertible>(lhs: T, rhs: MDQueryKey) -> MDPredicateExpression {
    return .lessThanOrEqualTo(.value(lhs), .key(rhs))
}

@inlinable
public func >= <T: MDDataConvertible>(lhs: T, rhs: MDQueryKey) -> MDPredicateExpression {
    return .greaterThanOrEqualTo(.value(lhs), .key(rhs))
}

@inlinable
public func ~= (lhs: MDQueryKey, rhs: MDQueryKey) -> MDPredicateExpression {
    return .containsIn(.key(rhs), .key(lhs))
}

@inlinable
public func ~= <T: MDDataConvertible>(lhs: MDQueryKey, rhs: T) -> MDPredicateExpression {
    return .containsIn(.value(rhs), .key(lhs))
}

@inlinable
public func ~= <C: Collection>(lhs: C, rhs: MDQueryKey) -> MDPredicateExpression where C.Element: MDDataConvertible {
    return .containsIn(.key(rhs), .value(MDData(lhs.map { $0.toMDData() })))
}

@inlinable
public func ~= <T: MDDataConvertible>(lhs: Range<T>, rhs: MDQueryKey) -> MDPredicateExpression {
    return .between(.key(rhs), .value(lhs.lowerBound), .value(lhs.upperBound))
}

@inlinable
public func ~= <T: MDDataConvertible>(lhs: ClosedRange<T>, rhs: MDQueryKey) -> MDPredicateExpression {
    return lhs.lowerBound <= rhs && rhs <= lhs.upperBound
}

@inlinable
public func ~= <T: MDDataConvertible>(lhs: PartialRangeFrom<T>, rhs: MDQueryKey) -> MDPredicateExpression {
    return lhs.lowerBound <= rhs
}

@inlinable
public func ~= <T: MDDataConvertible>(lhs: PartialRangeUpTo<T>, rhs: MDQueryKey) -> MDPredicateExpression {
    return rhs < lhs.upperBound
}

@inlinable
public func ~= <T: MDDataConvertible>(lhs: PartialRangeThrough<T>, rhs: MDQueryKey) -> MDPredicateExpression {
    return rhs <= lhs.upperBound
}

@inlinable
public func =~ (lhs: MDQueryKey, rhs: MDQueryKey) -> MDPredicateExpression {
    return .containsIn(.key(lhs), .key(rhs))
}

@inlinable
public func =~ <T: MDDataConvertible>(lhs: T, rhs: MDQueryKey) -> MDPredicateExpression {
    return .containsIn(.value(lhs), .key(rhs))
}

@inlinable
public func =~ <C: Collection>(lhs: MDQueryKey, rhs: C) -> MDPredicateExpression where C.Element: MDDataConvertible {
    return .containsIn(.key(lhs), .value(MDData(rhs.map { $0.toMDData() })))
}

@inlinable
public func =~ <T: MDDataConvertible>(lhs: MDQueryKey, rhs: Range<T>) -> MDPredicateExpression {
    return .between(.key(lhs), .value(rhs.lowerBound), .value(rhs.upperBound))
}

@inlinable
public func =~ <T: MDDataConvertible>(lhs: MDQueryKey, rhs: ClosedRange<T>) -> MDPredicateExpression {
    return rhs.lowerBound <= lhs && lhs <= rhs.upperBound
}

@inlinable
public func =~ <T: MDDataConvertible>(lhs: MDQueryKey, rhs: PartialRangeFrom<T>) -> MDPredicateExpression {
    return rhs.lowerBound <= lhs
}

@inlinable
public func =~ <T: MDDataConvertible>(lhs: MDQueryKey, rhs: PartialRangeUpTo<T>) -> MDPredicateExpression {
    return lhs < rhs.upperBound
}

@inlinable
public func =~ <T: MDDataConvertible>(lhs: MDQueryKey, rhs: PartialRangeThrough<T>) -> MDPredicateExpression {
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
