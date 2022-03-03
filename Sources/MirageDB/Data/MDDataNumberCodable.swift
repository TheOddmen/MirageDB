//
//  MDDataNumberCodable.swift
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

extension MDData.Number: Encodable {
    
    @inlinable
    public func encode(to encoder: Encoder) throws {
        
        var container = encoder.singleValueContainer()
        
        switch self {
        case let .signed(number): try container.encode(number)
        case let .unsigned(number): try container.encode(number)
        case let .number(number): try container.encode(number)
        case let .decimal(number):
            if "\(type(of: encoder))" == "_BSONEncoder" {
                try container.encode(BSON(number))
            } else {
                try container.encode(number)
            }
        }
    }
}

extension MDData.Number: Decodable {
    
    @inlinable
    static func _decode_number(_ value: BSON) -> MDData.Number? {
        
        switch value {
        case let .int32(value): return .signed(Int64(value))
        case let .int64(value): return .signed(value)
        case let .double(value): return .number(value)
        case let .decimal128(value):
            
            let str = value.description
            
            switch str {
            case "Infinity": return .number(.infinity)
            case "-Infinity": return .number(-.infinity)
            case "NaN": return .number(.nan)
            default:
                guard let decimal = Decimal(string: str, locale: Locale(identifier: "en_US")) else { return nil }
                return .decimal(decimal)
            }
            
        default: return nil
        }
    }
    
    @inlinable
    static func _decode_number(_ container: SingleValueDecodingContainer) -> MDData.Number? {
        
        if let double = try? container.decode(Double.self) {
            
            if let uint64 = try? container.decode(UInt64.self), Double(uint64) == double {
                return .unsigned(uint64)
            } else if let int64 = try? container.decode(Int64.self), Double(int64) == double {
                return .signed(int64)
            } else if let decimal = try? container.decode(Decimal.self), decimal.doubleValue == double {
                return .decimal(decimal)
            } else {
                return .number(double)
            }
        }
        
        if let uint64 = try? container.decode(UInt64.self) {
            return .unsigned(uint64)
        }
        
        if let int64 = try? container.decode(Int64.self) {
            return .signed(int64)
        }
        
        if let decimal = try? container.decode(Decimal.self) {
            return .decimal(decimal)
        }
        
        return nil
    }
    
    @inlinable
    public init(from decoder: Decoder) throws {
        
        let container = try decoder.singleValueContainer()
        
        if "\(type(of: decoder))" == "_BSONDecoder",
            let value = try? container.decode(BSON.self),
            let number = MDData.Number._decode_number(value) {
            
            self = number
            return
        }
        
        guard let number = MDData.Number._decode_number(container) else {
            
            throw DecodingError.dataCorrupted(DecodingError.Context(
                codingPath: decoder.codingPath,
                debugDescription: "Attempted to decode MDData.Number from unknown structure.")
            )
        }
        
        self = number
    }
}
