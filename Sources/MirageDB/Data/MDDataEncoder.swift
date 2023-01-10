//
//  MDDataEncoder.swift
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

public class MDDataEncoder {
    
    let userInfo: [CodingUserInfoKey: Any]
    
    public init(userInfo: [CodingUserInfoKey: Any] = [:]) {
        self.userInfo = userInfo
    }
}

extension MDDataEncoder {
    
    public func encode<T: Encodable>(_ value: T) throws -> MDData {
        
        let encoder = _Encoder(codingPath: [], userInfo: userInfo, storage: nil)
        try value.encode(to: encoder)
        
        return encoder.storage?.value ?? nil
    }
}

extension MDDataEncoder {
    
    class _Encoder: Encoder {
        
        var codingPath: [Swift.CodingKey]
        
        let userInfo: [CodingUserInfoKey: Any]
        
        var storage: _EncoderStorage?
        
        init(codingPath: [Swift.CodingKey], userInfo: [CodingUserInfoKey: Any], storage: _EncoderStorage?) {
            self.codingPath = codingPath
            self.userInfo = userInfo
            self.storage = storage
        }
    }
    
    enum _EncoderValue {
        
        case value(MDData)
        
        case storage(_EncoderStorage)
        
        var value: MDData {
            switch self {
            case let .value(value): return value
            case let .storage(storage): return storage.value
            }
        }
    }
    
    class _EncoderStorage {
        
        let codingPath: [CodingKey]
        
        let userInfo: [CodingUserInfoKey: Any]
        
        var value: MDData { return nil }
        
        init(codingPath: [CodingKey], userInfo: [CodingUserInfoKey: Any]) {
            self.codingPath = codingPath
            self.userInfo = userInfo
        }
    }
    
    struct _KeyedEncodingContainer<Key: CodingKey> {
        
        let ref: _RefObject
        
        var codingPath: [CodingKey] { ref.codingPath }
        
    }
    
    class _RefObject: _EncoderStorage {
        
        var object: [String: _EncoderValue] = [:]
        
        override var value: MDData { return MDData(object.mapValues { $0.value }) }
        
    }
    
    class _RefArray: _EncoderStorage {
        
        var array: [_EncoderValue] = []
        
        var count: Int { array.count }
        
        override var value: MDData { return MDData(array.map { $0.value }) }
        
    }
    
    class _RefValue: _EncoderStorage {
        
        var _value: _EncoderValue?
        
        override var value: MDData { return _value?.value ?? nil }
        
    }
}

extension MDDataEncoder._Encoder {
    
    func container<Key: CodingKey>(keyedBy type: Key.Type) -> KeyedEncodingContainer<Key> {
        
        if let storage = self.storage as? MDDataEncoder._RefObject {
            return KeyedEncodingContainer(MDDataEncoder._KeyedEncodingContainer(ref: storage))
        }
        
        guard storage == nil else { preconditionFailure() }
        
        let value = MDDataEncoder._RefObject(codingPath: codingPath, userInfo: userInfo)
        self.storage = value
        return KeyedEncodingContainer(MDDataEncoder._KeyedEncodingContainer(ref: value))
    }
    
    func unkeyedContainer() -> UnkeyedEncodingContainer {
        
        if let storage = self.storage as? MDDataEncoder._RefArray {
            return storage
        }
        
        guard storage == nil else { preconditionFailure() }
        
        let value = MDDataEncoder._RefArray(codingPath: codingPath, userInfo: userInfo)
        self.storage = value
        return value
    }
    
    func singleValueContainer() -> SingleValueEncodingContainer {
        
        if let storage = self.storage as? MDDataEncoder._RefValue {
            return storage
        }
        
        guard storage == nil else { preconditionFailure() }
        
        let value = MDDataEncoder._RefValue(codingPath: codingPath, userInfo: userInfo)
        self.storage = value
        return value
    }
}

extension MDDataEncoder._EncoderStorage {
    
    func _encode(_ value: Encodable) throws -> MDData {
        switch value {
        case let value as MDData: return value
        case let value as Bool: return MDData(value)
        case let value as Float: return MDData(value)
        case let value as Double: return MDData(value)
        case let value as Int: return MDData(value)
        case let value as Int8: return MDData(value)
        case let value as Int16: return MDData(value)
        case let value as Int32: return MDData(value)
        case let value as Int64: return MDData(value)
        case let value as UInt: return MDData(value)
        case let value as UInt8: return MDData(value)
        case let value as UInt16: return MDData(value)
        case let value as UInt32: return MDData(value)
        case let value as UInt64: return MDData(value)
        case let value as Decimal: return MDData(value)
        case let value as String: return MDData(value)
        case let value as Date: return MDData(value)
        case let value as Data: return MDData(value)
        case let value as Json.Number: return .number(.init(value))
        case let value as MDData.Number: return MDData(value)
        case let value as MDDataConvertible: return value.toMDData()
        default:
            
            let encoder = MDDataEncoder._Encoder(codingPath: codingPath, userInfo: userInfo, storage: nil)
            try value.encode(to: encoder)
            
            guard let encoded = encoder.storage?.value else { throw Database.Error.unsupportedType }
            
            return encoded
        }
    }
}

extension MDDataEncoder._KeyedEncodingContainer: KeyedEncodingContainerProtocol {
    
    func encodeNil(forKey key: Key) throws {
        ref.object[key.stringValue] = nil
    }
    
    func encode<T: Encodable>(_ value: T, forKey key: Key) throws {
        ref.object[key.stringValue] = try .value(ref._encode(value))
    }
    
    func nestedContainer<NestedKey: CodingKey>(keyedBy keyType: NestedKey.Type, forKey key: Key) -> KeyedEncodingContainer<NestedKey> {
        let codingPath = self.codingPath + [key]
        let value = MDDataEncoder._RefObject(codingPath: codingPath, userInfo: ref.userInfo)
        ref.object[key.stringValue] = .storage(value)
        return KeyedEncodingContainer<NestedKey>(MDDataEncoder._KeyedEncodingContainer(ref: value))
    }
    
    func nestedUnkeyedContainer(forKey key: Key) -> UnkeyedEncodingContainer {
        let codingPath = self.codingPath + [key]
        let value = MDDataEncoder._RefArray(codingPath: codingPath, userInfo: ref.userInfo)
        ref.object[key.stringValue] = .storage(value)
        return value
    }
    
    func superEncoder() -> Encoder {
        fatalError("unimplemented")
    }
    
    func superEncoder(forKey key: Key) -> Encoder {
        fatalError("unimplemented")
    }
}

extension MDDataEncoder._RefArray: UnkeyedEncodingContainer {
    
    func encodeNil() throws {
        array.append(.value(nil))
    }
    
    func encode<T: Encodable>(_ value: T) throws {
        try array.append(.value(self._encode(value)))
    }
    
    func nestedContainer<NestedKey>(keyedBy keyType: NestedKey.Type) -> KeyedEncodingContainer<NestedKey> where NestedKey : CodingKey {
        let codingPath = self.codingPath + [MDData.CodingKey(intValue: array.count)]
        let value = MDDataEncoder._RefObject(codingPath: codingPath, userInfo: userInfo)
        array.append(.storage(value))
        return KeyedEncodingContainer<NestedKey>(MDDataEncoder._KeyedEncodingContainer(ref: value))
    }
    
    func nestedUnkeyedContainer() -> UnkeyedEncodingContainer {
        let codingPath = self.codingPath + [MDData.CodingKey(intValue: array.count)]
        let value = MDDataEncoder._RefArray(codingPath: codingPath, userInfo: userInfo)
        array.append(.storage(value))
        return value
    }
    
    func superEncoder() -> Encoder {
        fatalError("unimplemented")
    }
}

extension MDDataEncoder._RefValue: SingleValueEncodingContainer {
    
    func encodeNil() throws {
        self.preconditionCanEncodeNewValue()
        self._value = .value(nil)
    }
    
    func encode<T: Encodable>(_ value: T) throws {
        self.preconditionCanEncodeNewValue()
        self._value = try .value(self._encode(value))
    }
    
    func preconditionCanEncodeNewValue() {
        precondition(self._value == nil, "Attempt to encode value through single value container when previously value already encoded.")
    }
    
}
