//
//  MDTime.swift
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

public struct MDTime: Hashable, Equatable, Comparable {
    
    public var hour: Int
    
    public var minute: Int
    
    public var second: Int
    
    public var nanosecond: Int
    
    public init(hour: Int, minute: Int, second: Int, nanosecond: Int = 0) {
        self.hour = hour
        self.minute = minute
        self.second = second
        self.nanosecond = nanosecond
    }
}

extension MDTime {
    
    public static func < (lhs: MDTime, rhs: MDTime) -> Bool {
        return (lhs.hour, lhs.minute, lhs.second, lhs.nanosecond) < (rhs.hour, rhs.minute, rhs.second, rhs.nanosecond)
    }
}

extension MDTime {
    
    public init?(_ dateComponents: DateComponents) {
        guard let hour = dateComponents.hour else { return nil }
        guard let minute = dateComponents.minute else { return nil }
        guard let second = dateComponents.second else { return nil }
        self.hour = hour
        self.minute = minute
        self.second = second
        self.nanosecond = dateComponents.nanosecond ?? 0
    }
    
    public var dateComponents: DateComponents {
        return DateComponents(hour: hour, minute: minute, second: second, nanosecond: nanosecond)
    }
}
