//
//  BSON.swift
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

extension Dictionary where Key == String, Value == MDData {
    
    fileprivate init(_ document: BSONDocument) throws {
        self.init()
        for (key, value) in document {
            self[key] = try MDData(value)
        }
    }
}

extension MDData {
    
    init(_ data: BSON) throws {
        switch data {
        case .null: self = nil
        case .undefined: self = nil
        case let .int32(value): self.init(value)
        case let .int64(value): self.init(value)
        case let .decimal128(value):
            
            let str = value.description
            
            switch str {
            case "Infinity": self.init(Double.infinity)
            case "-Infinity": self.init(-Double.infinity)
            case "NaN": self.init(Decimal.nan)
            default:
                guard let decimal = Decimal(string: str) else { throw MDError.unsupportedType }
                self.init(decimal)
            }
            
        case let .bool(value): self.init(value)
        case let .datetime(value): self.init(value)
        case let .double(value): self.init(value)
        case let .string(value): self.init(value)
        case let .objectID(value): self.init(value.hex)
        case let .binary(value): self.init(value.data)
        case let .array(value): try self.init(value.map(MDData.init))
        case let .document(value): try self.init(Dictionary(value))
        default: throw MDError.unsupportedType
        }
    }
}

extension MDData.Number: BSONConvertible {
    
    @inlinable
    public func toBSON() -> BSON {
        switch self {
        case let .signed(value): return BSON(value)
        case let .unsigned(value): return BSON(value)
        case let .number(value): return BSON(value)
        case let .decimal(value): return BSON(value)
        }
    }
}

extension MDData: BSONConvertible {
    
    @inlinable
    public func toBSON() -> BSON {
        switch self {
        case .null: return .undefined
        case let .boolean(value): return BSON(value)
        case let .string(value): return BSON(value)
        case let .number(value): return BSON(value)
        case let .timestamp(value): return BSON(value)
        case let .binary(value): return BSON(value)
        case let .array(value): return BSON(value.map { $0.toBSON() })
        case let .dictionary(value): return BSON(value.mapValues { $0.toBSON() })
        }
    }
}
