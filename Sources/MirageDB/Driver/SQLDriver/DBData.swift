//
//  DBData.swift
//
//  The MIT License
//  Copyright (c) 2021 - 2022 The Oddmen Technology Limited. All rights reserved.
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

private func decodeInt32(_ obj: [String: DBData]) -> Int32? {
    guard obj.count == 1 else { return nil }
    guard obj.keys.first == "$numberInt" else { return nil }
    guard let value = obj["$numberInt"]?.string else { return nil }
    return Int32(value)
}

private func decodeInt64(_ obj: [String: DBData]) -> Int64? {
    guard obj.count == 1 else { return nil }
    guard obj.keys.first == "$numberLong" else { return nil }
    guard let value = obj["$numberLong"]?.string else { return nil }
    return Int64(value)
}

private func decodeDouble(_ obj: [String: DBData]) -> Double? {
    
    guard obj.count == 1 else { return nil }
    guard obj.keys.first == "$numberDouble" else { return nil }
    guard let value = obj["$numberDouble"]?.string else { return nil }
    
    switch value {
    case "Infinity": return .infinity
    case "-Infinity": return -.infinity
    case "NaN": return .nan
    default: return Double(value)
    }
}

private func decodeDecimal(_ obj: [String: DBData]) -> Decimal? {
    guard obj.count == 1 else { return nil }
    guard obj.keys.first == "$numberDecimal" else { return nil }
    guard let value = obj["$numberDecimal"]?.string else { return nil }
    return Decimal(string: value)
}

private func decodeDate(_ obj: [String: DBData]) -> Date? {
    guard obj.count == 1 else { return nil }
    guard obj.keys.first == "$date" else { return nil }
    guard let value = obj["$date"]?.dictionary else { return nil }
    guard let millis = decodeInt64(value) else { return nil }
    return Date(timeIntervalSince1970: Double(millis) / 1000)
}

private func decodeBinary(_ obj: [String: DBData]) -> Data? {
    guard obj.count == 1 else { return nil }
    guard obj.keys.first == "$binary" else { return nil }
    guard let value = obj["base64"]?.string else { return nil }
    return Data(base64Encoded: value)
}

extension MDData.Number {
    
    fileprivate init(_ value: DBData.Number) {
        switch value {
        case let .signed(value): self.init(value)
        case let .unsigned(value): self.init(value)
        case let .number(value): self.init(value)
        case let .decimal(value): self.init(value)
        }
    }
}

extension MDData {
    
    private static let extendedJSONTypes = [
        "$numberInt": { decodeInt32($0).map(MDData.init) },
        "$numberLong": { decodeInt64($0).map(MDData.init) },
        "$numberDouble": { decodeDouble($0).map(MDData.init) },
        "$numberDecimal": { decodeDecimal($0).map(MDData.init) },
        "$binary": { decodeBinary($0).map(MDData.init) },
        "$date": { decodeDate($0).map(MDData.init) },
    ]
    
    private init(fromExtendedJSON data: DBData) throws {
        switch data {
        case .null: self = nil
        case let .boolean(value): self.init(value)
        case let .string(value): self.init(value)
        case let .number(value): self = .number(Number(value))
        case let .timestamp(value): self.init(value)
        case let .array(value): try self.init(value.map(MDData.init(fromExtendedJSON:)))
        case let .dictionary(obj):
            
            if let key = obj.keys.first,
               let decoder = MDData.extendedJSONTypes[key],
               let value = decoder(obj) {
                
                self = value
                
            } else {
                
                try self.init(obj.mapValues(MDData.init(fromExtendedJSON:)))
            }
            
        default: throw MDError.unsupportedType
        }
    }
    
    private func toExtendedJSON() -> DBData {
        switch self {
        case .null: return nil
        case let .boolean(value): return DBData(value)
        case let .string(value): return DBData(value)
        case let .number(value):
            switch value {
            case let .signed(value): return ["$numberLong": "\(value)"]
            case let .unsigned(value): return ["$numberLong": "\(value)"]
            case let .number(value): return DBData(value)
            case let .decimal(value): return ["$numberDecimal": "\(value)"]
            }
        case let .timestamp(value): return ["$date": ["$numberLong": "\(Int64(value.timeIntervalSince1970 * 1000))"]]
        case let .binary(value): return ["$binary": ["base64": DBData(value.base64EncodedString()), "subType": "00"]]
        case let .array(value): return DBData(value.map { $0.toExtendedJSON() })
        case let .dictionary(value): return DBData(value.mapValues { $0.toExtendedJSON() })
        }
    }
}

extension MDData {
    
    init(fromSQLData data: DBData) throws {
        switch data {
        case .null: self = nil
        case let .boolean(value): self.init(value)
        case let .string(value): self.init(value)
        case let .number(value): self = .number(Number(value))
        case let .timestamp(value): self.init(value)
        case let .binary(value): self.init(value)
        case let .array(value): try self.init(value.map(MDData.init(fromExtendedJSON:)))
        case let .dictionary(value): try self.init(value.mapValues(MDData.init(fromExtendedJSON:)))
        default: throw MDError.unsupportedType
        }
    }
    
    func toSQLData() -> DBData {
        switch self {
        case .null: return nil
        case let .boolean(value): return DBData(value)
        case let .string(value): return DBData(value)
        case let .number(value):
            switch value {
            case let .signed(value): return DBData(value)
            case let .unsigned(value): return DBData(value)
            case let .number(value): return DBData(value)
            case let .decimal(value): return DBData(value)
            }
        case let .timestamp(value): return DBData(value)
        case let .binary(value): return DBData(value)
        case let .array(value): return DBData(value.map { $0.toExtendedJSON() })
        case let .dictionary(value): return DBData(value.mapValues { $0.toExtendedJSON() })
        }
    }
}
