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
    
    public func toMDData() -> MDData {
        return self
    }
}

extension Optional: MDDataConvertible where Wrapped: MDDataConvertible {
    
    public func toMDData() -> MDData {
        return self?.toMDData() ?? nil
    }
}

extension Bool: MDDataConvertible {
    
    public func toMDData() -> MDData {
        return MDData(self)
    }
}

extension FixedWidthInteger {
    
    public func toMDData() -> MDData {
        return MDData(self)
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
    
    public func toMDData() -> MDData {
        return MDData(self)
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
    
    public func toMDData() -> MDData {
        return MDData(self)
    }
}

extension StringProtocol {
    
    public func toMDData() -> MDData {
        return MDData(String(self))
    }
}

extension String: MDDataConvertible {
    
    public func toMDData() -> MDData {
        return MDData(self)
    }
}

extension Substring: MDDataConvertible { }

extension Date: MDDataConvertible {
    
    public func toMDData() -> MDData {
        return MDData(self)
    }
}

extension MDDate: MDDataConvertible {
    
    public func toMDData() -> MDData {
        return MDData(self)
    }
}

extension MDTime: MDDataConvertible {
    
    public func toMDData() -> MDData {
        return MDData(self)
    }
}

extension Array: MDDataConvertible where Element: MDDataConvertible {
    
    public func toMDData() -> MDData {
        return MDData(self)
    }
}

extension Dictionary: MDDataConvertible where Key == String, Value: MDDataConvertible {
    
    public func toMDData() -> MDData {
        return MDData(self)
    }
}

extension OrderedDictionary: MDDataConvertible where Key == String, Value: MDDataConvertible {
    
    public func toMDData() -> MDData {
        return MDData(self)
    }
}
