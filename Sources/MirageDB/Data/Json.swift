//
//  Json.swift
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

extension MDData {
    
    public init(_ json: Json) {
        switch json.type {
        case .null: self = nil
        case .boolean: self = json.boolValue.map { MDData($0) } ?? nil
        case .string: self = json.stringValue.map { MDData($0) } ?? nil
        case .number: self = json.doubleValue.map { MDData($0) } ?? nil
        case .array: self = json.array.map { MDData($0.map { MDData($0) }) } ?? nil
        case .dictionary: self = json.dictionary.map { MDData($0.mapValues { MDData($0) }) } ?? nil
        }
    }
}

extension Json {
    
    public init?(_ value: MDData) {
        switch value {
        case .null: self = nil
        case let .boolean(value): self.init(value)
        case let .string(value): self.init(value)
        case let .integer(value): self.init(value)
        case let .number(value): self.init(value)
        case let .decimal(value): self.init(value)
        case let .timestamp(value):
            
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = .withInternetDateTime
            
            self.init(formatter.string(from: value))
            
        case let .array(value):
            
            let array = value.compactMap(Json.init)
            guard array.count == value.count else { return nil }
            self.init(array)
            
        case let .dictionary(value):
            
            let dictionary = value.compactMapValues(Json.init)
            guard dictionary.count == value.count else { return nil }
            self.init(dictionary)
        }
    }
}
