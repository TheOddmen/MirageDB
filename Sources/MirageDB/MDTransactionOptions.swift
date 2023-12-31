//
//  MDTransactionOptions.swift
//
//  The MIT License
//  Copyright (c) 2015 - 2024 Susan Cheng. All rights reserved.
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

public struct MDTransactionOptions {
    
    public var mode: Mode
    
    public var retryOnConflict: Bool
    
    public init(
        mode: MDTransactionOptions.Mode = .default,
        retryOnConflict: Bool = false
    ) {
        self.mode = mode
        self.retryOnConflict = retryOnConflict
    }
}

extension MDTransactionOptions {
    
    public static var `default`: MDTransactionOptions { return MDTransactionOptions() }
}

extension MDTransactionOptions {
    
    public enum Mode {
        
        case `default`
        
        case committed
        
        case repeatable
        
        case serializable
        
    }
    
}

extension DBTransactionOptions {
    
    init(_ options: MDTransactionOptions) {
        self.init(mode: .init(options.mode), retryOnConflict: options.retryOnConflict)
    }
}

extension DBTransactionOptions.Mode {
    
    init(_ mode: MDTransactionOptions.Mode) {
        switch mode {
        case .default: self = .default
        case .committed: self = .committed
        case .repeatable: self = .repeatable
        case .serializable: self = .serializable
        }
    }
}
