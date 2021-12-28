//
//  MDDataConvertible.swift
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

public protocol MDDataConvertible {
    
    func toMDData() -> MDData
}

extension MDData: MDDataConvertible {
    
    @inlinable
    public func toMDData() -> MDData {
        return self
    }
}

extension Optional: MDDataConvertible where Wrapped: MDDataConvertible {
    
    @inlinable
    public func toMDData() -> MDData {
        return self?.toMDData() ?? .null
    }
}

extension Bool: MDDataConvertible {
    
    @inlinable
    public func toMDData() -> MDData {
        return .boolean(self)
    }
}

extension SignedInteger where Self: FixedWidthInteger {
    
    @inlinable
    public func toMDData() -> MDData {
        return .number(MDData.Number(self))
    }
}

extension UnsignedInteger where Self: FixedWidthInteger {
    
    @inlinable
    public func toMDData() -> MDData {
        return .number(MDData.Number(self))
    }
}

extension UInt: MDDataConvertible { }
extension UInt8: MDDataConvertible { }
extension UInt16: MDDataConvertible { }
extension UInt32: MDDataConvertible { }
extension UInt64: MDDataConvertible { }
extension Int: MDDataConvertible { }
extension Int8: MDDataConvertible { }
extension Int16: MDDataConvertible { }
extension Int32: MDDataConvertible { }
extension Int64: MDDataConvertible { }

extension BinaryFloatingPoint {
    
    @inlinable
    public func toMDData() -> MDData {
        return .number(MDData.Number(self))
    }
}

#if swift(>=5.3) && !os(macOS) && !targetEnvironment(macCatalyst)

@available(iOS 14.0, tvOS 14.0, watchOS 7.0, *)
extension Float16: MDDataConvertible { }

#endif

extension float16: MDDataConvertible { }
extension Float: MDDataConvertible { }
extension Double: MDDataConvertible { }

extension Decimal: MDDataConvertible {
    
    @inlinable
    public func toMDData() -> MDData {
        return .number(.decimal(self))
    }
}

extension StringProtocol {
    
    @inlinable
    public func toMDData() -> MDData {
        return .string(String(self))
    }
}

extension String: MDDataConvertible {
    
    @inlinable
    public func toMDData() -> MDData {
        return .string(self)
    }
}

extension Substring: MDDataConvertible { }

extension Date: MDDataConvertible {
    
    @inlinable
    public func toMDData() -> MDData {
        return .timestamp(self)
    }
}

extension Array: MDDataConvertible where Element: MDDataConvertible {
    
    @inlinable
    public func toMDData() -> MDData {
        return .array(self.map { $0.toMDData() })
    }
}

extension Dictionary: MDDataConvertible where Key == String, Value: MDDataConvertible {
    
    @inlinable
    public func toMDData() -> MDData {
        return .dictionary(self.mapValues { $0.toMDData() })
    }
}

extension OrderedDictionary: MDDataConvertible where Key == String, Value: MDDataConvertible {
    
    @inlinable
    public func toMDData() -> MDData {
        return .dictionary(Dictionary(self.mapValues { $0.toMDData() }))
    }
}
