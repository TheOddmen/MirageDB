//
//  MDData.swift
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

public enum MDDataType: Hashable {
    
    case null
    case boolean
    case string
    case integer
    case number
    case decimal
    case timestamp
    case date
    case time
    case array
    case dictionary
}

public struct MDData: Hashable {
    
    enum Base: Hashable {
        case null
        case boolean(Bool)
        case string(String)
        case integer(Int64)
        case number(Double)
        case decimal(Decimal)
        case timestamp(Date)
        case date(MDDate)
        case time(MDTime)
        case array([MDData])
        case dictionary(OrderedDictionary<String, MDData>)
    }
    
    let base: Base
    
    public init(_ value: Bool) {
        self.base = .boolean(value)
    }
    
    public init(_ value: String) {
        self.base = .string(value)
    }
    
    public init<S: StringProtocol>(_ value: S) {
        self.base = .string(String(value))
    }
    
    public init<T: FixedWidthInteger>(_ value: T) {
        self.base = .integer(Int64(value))
    }
    
    public init<T: BinaryFloatingPoint>(_ value: T) {
        self.base = .number(Double(value))
    }
    
    public init(_ value: Decimal) {
        self.base = .decimal(value)
    }
    
    public init(_ value: Date) {
        self.base = .timestamp(value)
    }
    
    public init(_ value: MDDate) {
        self.base = .date(value)
    }
    
    public init(_ value: MDTime) {
        self.base = .time(value)
    }
    
    public init<Wrapped: MDDataConvertible>(_ value: Wrapped?) {
        self = value.toMDData()
    }
    
    public init<S: Sequence>(_ elements: S) where S.Element: MDDataConvertible {
        self.base = .array(elements.map { $0.toMDData() })
    }
    
    public init<Value: MDDataConvertible>(_ elements: [String: Value]) {
        self.base = .dictionary(OrderedDictionary(uniqueKeysWithValues: elements.lazy.map { ($0.key, $0.value.toMDData()) }))
    }
    
    public init<Value: MDDataConvertible>(_ elements: OrderedDictionary<String, Value>) {
        self.base = .dictionary(elements.mapValues { $0.toMDData() })
    }
}

extension MDData: ExpressibleByNilLiteral {
    
    public init(nilLiteral value: Void) {
        self.base = .null
    }
}

extension MDData: ExpressibleByBooleanLiteral {
    
    public init(booleanLiteral value: BooleanLiteralType) {
        self.init(value)
    }
}

extension MDData: ExpressibleByIntegerLiteral {
    
    public init(integerLiteral value: IntegerLiteralType) {
        self.init(value)
    }
}

extension MDData: ExpressibleByFloatLiteral {
    
    public init(floatLiteral value: FloatLiteralType) {
        self.init(value)
    }
}

extension MDData: ExpressibleByStringInterpolation {
    
    public init(stringLiteral value: StringLiteralType) {
        self.init(value)
    }
    
    public init(stringInterpolation: String.StringInterpolation) {
        self.init(String(stringInterpolation: stringInterpolation))
    }
}

extension MDData: ExpressibleByArrayLiteral {
    
    public init(arrayLiteral elements: MDData ...) {
        self.init(elements)
    }
}

extension MDData: ExpressibleByDictionaryLiteral {
    
    public init(dictionaryLiteral elements: (String, MDData) ...) {
        self.init(OrderedDictionary(uniqueKeysWithValues: elements))
    }
}

extension MDData: CustomStringConvertible {
    
    public var description: String {
        switch self.base {
        case .null: return "nil"
        case let .boolean(value): return "\(value)"
        case let .string(value): return "\"\(value.escaped(asASCII: false))\""
        case let .integer(value): return "\(value)"
        case let .number(value): return "\(value)"
        case let .decimal(value): return "\(value)"
        case let .timestamp(value): return "\(value)"
        case let .date(value): return "\(value)"
        case let .time(value): return "\(value)"
        case let .array(value): return "\(value)"
        case let .dictionary(value): return "\(value)"
        }
    }
}

extension MDData {
    
    public var type: MDDataType {
        switch self.base {
        case .null: return .null
        case .boolean: return .boolean
        case .string: return .string
        case .integer: return .integer
        case .number: return .number
        case .decimal: return .decimal
        case .timestamp: return .timestamp
        case .date: return .date
        case .time: return .time
        case .array: return .array
        case .dictionary: return .dictionary
        }
    }
    
    public var isNil: Bool {
        switch self.base {
        case .null: return true
        default: return false
        }
    }
    
    public var isBool: Bool {
        switch self.base {
        case .boolean: return true
        default: return false
        }
    }
    
    public var isString: Bool {
        switch self.base {
        case .string: return true
        default: return false
        }
    }
    
    public var isInteger: Bool {
        switch self.base {
        case .integer: return true
        default: return false
        }
    }
    
    public var isNumber: Bool {
        switch self.base {
        case .number: return true
        default: return false
        }
    }
    
    public var isDecimal: Bool {
        switch self.base {
        case .decimal: return true
        default: return false
        }
    }
    
    public var isNumeric: Bool {
        switch self.base {
        case .integer: return true
        case .number: return true
        case .decimal: return true
        default: return false
        }
    }
    
    public var isTimestamp: Bool {
        switch self.base {
        case .timestamp: return true
        default: return false
        }
    }
    
    public var isDate: Bool {
        switch self.base {
        case .date: return true
        default: return false
        }
    }
    
    public var isTime: Bool {
        switch self.base {
        case .time: return true
        default: return false
        }
    }
    
    public var isArray: Bool {
        switch self.base {
        case .array: return true
        default: return false
        }
    }
    
    public var isObject: Bool {
        switch self.base {
        case .dictionary: return true
        default: return false
        }
    }
}

extension MDData {
    
    public var boolValue: Bool? {
        switch self.base {
        case let .boolean(value): return value
        default: return nil
        }
    }
    
    public var int8Value: Int8? {
        switch self.base {
        case let .integer(value): return Int8(exactly: value)
        case let .number(value): return Int8(exactly: value)
        case let .decimal(value): return Int64(exactly: value).flatMap { Int8(exactly: $0) }
        case let .string(string): return Int8(string)
        default: return nil
        }
    }
    
    public var uint8Value: UInt8? {
        switch self.base {
        case let .integer(value): return UInt8(exactly: value)
        case let .number(value): return UInt8(exactly: value)
        case let .decimal(value): return UInt64(exactly: value).flatMap { UInt8(exactly: $0) }
        case let .string(string): return UInt8(string)
        default: return nil
        }
    }
    
    public var int16Value: Int16? {
        switch self.base {
        case let .integer(value): return Int16(exactly: value)
        case let .number(value): return Int16(exactly: value)
        case let .decimal(value): return Int64(exactly: value).flatMap { Int16(exactly: $0) }
        case let .string(string): return Int16(string)
        default: return nil
        }
    }
    
    public var uint16Value: UInt16? {
        switch self.base {
        case let .integer(value): return UInt16(exactly: value)
        case let .number(value): return UInt16(exactly: value)
        case let .decimal(value): return UInt64(exactly: value).flatMap { UInt16(exactly: $0) }
        case let .string(string): return UInt16(string)
        default: return nil
        }
    }
    
    public var int32Value: Int32? {
        switch self.base {
        case let .integer(value): return Int32(exactly: value)
        case let .number(value): return Int32(exactly: value)
        case let .decimal(value): return Int64(exactly: value).flatMap { Int32(exactly: $0) }
        case let .string(string): return Int32(string)
        default: return nil
        }
    }
    
    public var uint32Value: UInt32? {
        switch self.base {
        case let .integer(value): return UInt32(exactly: value)
        case let .number(value): return UInt32(exactly: value)
        case let .decimal(value): return UInt64(exactly: value).flatMap { UInt32(exactly: $0) }
        case let .string(string): return UInt32(string)
        default: return nil
        }
    }
    
    public var int64Value: Int64? {
        switch self.base {
        case let .integer(value): return value
        case let .number(value): return Int64(exactly: value)
        case let .decimal(value): return Int64(exactly: value)
        case let .string(string): return Int64(string)
        default: return nil
        }
    }
    
    public var uint64Value: UInt64? {
        switch self.base {
        case let .integer(value): return UInt64(exactly: value)
        case let .number(value): return UInt64(exactly: value)
        case let .decimal(value): return UInt64(exactly: value)
        case let .string(string): return UInt64(string)
        default: return nil
        }
    }
    
    public var intValue: Int? {
        switch self.base {
        case let .integer(value): return Int(exactly: value)
        case let .number(value): return Int(exactly: value)
        case let .decimal(value): return Int64(exactly: value).flatMap { Int(exactly: $0) }
        case let .string(string): return Int(string)
        default: return nil
        }
    }
    
    public var uintValue: UInt? {
        switch self.base {
        case let .integer(value): return UInt(exactly: value)
        case let .number(value): return UInt(exactly: value)
        case let .decimal(value): return UInt64(exactly: value).flatMap { UInt(exactly: $0) }
        case let .string(string): return UInt(string)
        default: return nil
        }
    }
    
    public var floatValue: Float? {
        switch self.base {
        case let .integer(value): return Float(exactly: value)
        case let .number(value): return Float(value)
        case let .decimal(value): return Double(exactly: value).flatMap { Float(exactly: $0) }
        case let .string(string): return Float(string)
        default: return nil
        }
    }
    
    public var doubleValue: Double? {
        switch self.base {
        case let .integer(value): return Double(exactly: value)
        case let .number(value): return value
        case let .decimal(value): return Double(exactly: value)
        case let .string(string): return Double(string)
        default: return nil
        }
    }
    
    public var decimalValue: Decimal? {
        switch self.base {
        case let .integer(value): return Decimal(value)
        case let .number(value): return Decimal(value)
        case let .decimal(value): return value
        case let .string(string): return Decimal(string: string)
        default: return nil
        }
    }
    
    public var string: String? {
        switch self.base {
        case let .string(value): return value
        default: return nil
        }
    }
    
    public var timestamp: Date? {
        switch self.base {
        case let .timestamp(value): return value
        default: return nil
        }
    }
    
    public var date: MDDate? {
        switch self.base {
        case let .date(value): return value
        default: return nil
        }
    }
    
    public var time: MDTime? {
        switch self.base {
        case let .time(value): return value
        default: return nil
        }
    }
    
    public var array: [MDData]? {
        switch self.base {
        case let .array(value): return value
        default: return nil
        }
    }
    
    public var dictionary: OrderedDictionary<String, MDData>? {
        switch self.base {
        case let .dictionary(value): return value
        default: return nil
        }
    }
}

extension MDData {
    
    public var count: Int {
        switch self.base {
        case let .array(value): return value.count
        case let .dictionary(value): return value.count
        default: fatalError("Not an array or object.")
        }
    }
    
    public subscript(index: Int) -> MDData {
        get {
            guard 0..<count ~= index else { return nil }
            switch self.base {
            case let .array(value): return value[index]
            default: return nil
            }
        }
        set {
            switch self.base {
            case var .array(value):
                
                if index >= value.count {
                    value.append(contentsOf: repeatElement(nil, count: index - value.count + 1))
                }
                value[index] = newValue
                self = MDData(value)
                
            default: fatalError("Not an array.")
            }
        }
    }
    
    public var keys: OrderedSet<String> {
        switch self.base {
        case let .dictionary(value): return value.keys
        default: return []
        }
    }
    
    public subscript(key: String) -> MDData {
        get {
            switch self.base {
            case let .dictionary(value): return value[key] ?? nil
            default: return nil
            }
        }
        set {
            switch self.base {
            case var .dictionary(value):
                
                value[key] = newValue.isNil ? nil : newValue
                self = MDData(value)
                
            default: fatalError("Not an object.")
            }
        }
    }
}
