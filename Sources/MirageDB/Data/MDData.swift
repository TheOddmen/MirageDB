//
//  MDData.swift
//
//  The MIT License
//  Copyright (c) 2021 - 2023 O2ter Limited. All rights reserved.
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
public enum MDData: Hashable, Sendable {
    
    case null
    
    case boolean(Bool)
    
    case string(String)
    
    case number(Number)
    
    case timestamp(Date)
    
    case binary(Data)
    
    case array([MDData])
    
    case dictionary([String: MDData])
}

extension MDData {
    
    @inlinable
    public init(_ value: Bool) {
        self = .boolean(value)
    }
    
    @inlinable
    public init(_ value: String) {
        self = .string(value)
    }
    
    @inlinable
    public init<S: StringProtocol>(_ value: S) {
        self = .string(String(value))
    }
    
    @inlinable
    public init<T: FixedWidthInteger & SignedInteger>(_ value: T) {
        self = .number(Number(value))
    }
    
    @inlinable
    public init<T: FixedWidthInteger & UnsignedInteger>(_ value: T) {
        self = .number(Number(value))
    }
    
    @inlinable
    public init<T: BinaryFloatingPoint>(_ value: T) {
        self = .number(Number(value))
    }
    
    @inlinable
    public init(_ value: Decimal) {
        self = .number(Number(value))
    }
    
    @inlinable
    public init(_ value: Number) {
        self = .number(value)
    }
    
    @inlinable
    public init(_ value: Date) {
        self = .timestamp(value)
    }
    
    @inlinable
    public init(_ binary: Data) {
        self = .binary(binary)
    }
    
    @inlinable
    public init(_ binary: ByteBuffer) {
        self = .binary(binary.data)
    }
    
    @inlinable
    public init(_ binary: ByteBufferView) {
        self = .binary(Data(binary))
    }
    
    @inlinable
    public init<Wrapped: MDDataConvertible>(_ value: Wrapped?) {
        self = value.toMDData()
    }
    
    @inlinable
    public init<S: Sequence>(_ elements: S) where S.Element: MDDataConvertible {
        self = .array(elements.map { $0.toMDData() })
    }
    
    @inlinable
    public init<Value: MDDataConvertible>(_ elements: [String: Value]) {
        self = .dictionary(elements.mapValues { $0.toMDData() })
    }
    
    @inlinable
    public init<Value: MDDataConvertible>(_ elements: OrderedDictionary<String, Value>) {
        self = .dictionary(Dictionary(elements.mapValues { $0.toMDData() }))
    }
}

extension MDData: ExpressibleByNilLiteral {
    
    @inlinable
    public init(nilLiteral value: Void) {
        self = .null
    }
}

extension MDData: ExpressibleByBooleanLiteral {
    
    @inlinable
    public init(booleanLiteral value: BooleanLiteralType) {
        self.init(value)
    }
}

extension MDData: ExpressibleByIntegerLiteral {
    
    @inlinable
    public init(integerLiteral value: IntegerLiteralType) {
        self.init(value)
    }
}

extension MDData: ExpressibleByFloatLiteral {
    
    @inlinable
    public init(floatLiteral value: FloatLiteralType) {
        self.init(value)
    }
}

extension MDData: ExpressibleByStringInterpolation {
    
    @inlinable
    public init(stringLiteral value: StringLiteralType) {
        self.init(value)
    }
    
    @inlinable
    public init(stringInterpolation: String.StringInterpolation) {
        self.init(String(stringInterpolation: stringInterpolation))
    }
}

extension MDData: ExpressibleByArrayLiteral {
    
    @inlinable
    public init(arrayLiteral elements: MDData ...) {
        self.init(elements)
    }
}

extension MDData: ExpressibleByDictionaryLiteral {
    
    @inlinable
    public init(dictionaryLiteral elements: (String, MDData) ...) {
        self.init(Dictionary(uniqueKeysWithValues: elements))
    }
}

extension MDData: CustomStringConvertible {
    
    @inlinable
    public var description: String {
        switch self {
        case .null: return "nil"
        case let .boolean(value): return "\(value)"
        case let .string(value): return "\"\(value.escaped(asASCII: false))\""
        case let .number(value): return "\(value)"
        case let .timestamp(value): return "\(value)"
        case let .binary(value): return "\(value)"
        case let .array(value): return "\(value)"
        case let .dictionary(value): return "\(value)"
        }
    }
}

extension MDData {
    
    @inlinable
    public var isNil: Bool {
        switch self {
        case .null: return true
        default: return false
        }
    }
    
    @inlinable
    public var isBool: Bool {
        switch self {
        case .boolean: return true
        default: return false
        }
    }
    
    @inlinable
    public var isString: Bool {
        switch self {
        case .string: return true
        default: return false
        }
    }
    
    @inlinable
    public var isNumber: Bool {
        switch self {
        case .number: return true
        default: return false
        }
    }
    
    @inlinable
    public var isTimestamp: Bool {
        switch self {
        case .timestamp: return true
        default: return false
        }
    }
    
    @inlinable
    public var isArray: Bool {
        switch self {
        case .array: return true
        default: return false
        }
    }
    
    @inlinable
    public var isObject: Bool {
        switch self {
        case .dictionary: return true
        default: return false
        }
    }
}

extension MDData {
    
    @inlinable
    public var boolValue: Bool? {
        switch self {
        case let .boolean(value): return value
        default: return nil
        }
    }
    
    @inlinable
    public var int8Value: Int8? {
        switch self {
        case let .number(value): return value.int8Value
        case let .string(string): return Int8(string)
        default: return nil
        }
    }
    
    @inlinable
    public var uint8Value: UInt8? {
        switch self {
        case let .number(value): return value.uint8Value
        case let .string(string): return UInt8(string)
        default: return nil
        }
    }
    
    @inlinable
    public var int16Value: Int16? {
        switch self {
        case let .number(value): return value.int16Value
        case let .string(string): return Int16(string)
        default: return nil
        }
    }
    
    @inlinable
    public var uint16Value: UInt16? {
        switch self {
        case let .number(value): return value.uint16Value
        case let .string(string): return UInt16(string)
        default: return nil
        }
    }
    
    @inlinable
    public var int32Value: Int32? {
        switch self {
        case let .number(value): return value.int32Value
        case let .string(string): return Int32(string)
        default: return nil
        }
    }
    
    @inlinable
    public var uint32Value: UInt32? {
        switch self {
        case let .number(value): return value.uint32Value
        case let .string(string): return UInt32(string)
        default: return nil
        }
    }
    
    @inlinable
    public var int64Value: Int64? {
        switch self {
        case let .number(value): return value.int64Value
        case let .string(string): return Int64(string)
        default: return nil
        }
    }
    
    @inlinable
    public var uint64Value: UInt64? {
        switch self {
        case let .number(value): return value.uint64Value
        case let .string(string): return UInt64(string)
        default: return nil
        }
    }
    
    @inlinable
    public var intValue: Int? {
        switch self {
        case let .number(value): return value.intValue
        case let .string(string): return Int(string)
        default: return nil
        }
    }
    
    @inlinable
    public var uintValue: UInt? {
        switch self {
        case let .number(value): return value.uintValue
        case let .string(string): return UInt(string)
        default: return nil
        }
    }
    
    @inlinable
    public var floatValue: Float? {
        switch self {
        case let .number(value): return value.floatValue
        case let .string(string): return Float(string)
        default: return nil
        }
    }
    
    @inlinable
    public var doubleValue: Double? {
        switch self {
        case let .number(value): return value.doubleValue
        case let .string(string): return Double(string)
        default: return nil
        }
    }
    
    @inlinable
    public var decimalValue: Decimal? {
        switch self {
        case let .number(value): return value.decimalValue
        case let .string(string): return Decimal(exactly: string)
        default: return nil
        }
    }
    
    @inlinable
    public var numberValue: Number? {
        switch self {
        case let .number(value): return value
        default: return nil
        }
    }
    
    @inlinable
    public var string: String? {
        switch self {
        case let .string(value): return value
        default: return nil
        }
    }
    
    @inlinable
    public var timestamp: Date? {
        switch self {
        case let .timestamp(value): return value
        default: return nil
        }
    }
    
    @inlinable
    public var array: [MDData]? {
        switch self {
        case let .array(value): return value
        default: return nil
        }
    }
    
    @inlinable
    public var dictionary: [String: MDData]? {
        switch self {
        case let .dictionary(value): return value
        default: return nil
        }
    }
}

extension MDData {
    
    @inlinable
    public var count: Int {
        switch self {
        case let .array(value): return value.count
        case let .dictionary(value): return value.count
        default: fatalError("Not an array or object.")
        }
    }
    
    @inlinable
    public subscript(index: Int) -> MDData {
        get {
            guard 0..<count ~= index else { return nil }
            switch self {
            case let .array(value): return value[index]
            default: return nil
            }
        }
        set {
            switch self {
            case var .array(value):
                
                replaceValue(&self) {
                    if index >= value.count {
                        value.append(contentsOf: repeatElement(nil, count: index - value.count + 1))
                    }
                    value[index] = newValue
                    return .array(value)
                }
                
            default: fatalError("Not an array.")
            }
        }
    }
    
    @inlinable
    public var keys: Dictionary<String, MDData>.Keys {
        switch self {
        case let .dictionary(value): return value.keys
        default: return [:].keys
        }
    }
    
    @inlinable
    public subscript(key: String) -> MDData {
        get {
            switch self {
            case let .dictionary(value): return value[key] ?? nil
            default: return nil
            }
        }
        set {
            switch self {
            case var .dictionary(value):
                
                replaceValue(&self) {
                    value[key] = newValue.isNil ? nil : newValue
                    return .dictionary(value)
                }
                
            default: fatalError("Not an object.")
            }
        }
    }
}
