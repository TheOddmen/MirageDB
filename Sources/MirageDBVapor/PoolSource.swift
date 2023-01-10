//
//  PoolSource.swift
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

public class MDConnectionPoolItem: ConnectionPoolItem {
    
    public let connection: MDConnection
    
    public private(set) var isClosed: Bool = false
    
    init(connection: MDConnection) {
        self.connection = connection
    }
    
    public var eventLoop: EventLoop {
        return connection.eventLoopGroup.next()
    }
    
    public func close() -> EventLoopFuture<Void> {
        
        let promise = eventLoop.makePromise(of: Void.self)
        
        promise.completeWithTask {
            try await self.connection.close()
            self.isClosed = true
        }
        
        return promise.futureResult
    }
}

public struct MDConnectionPoolSource: ConnectionPoolSource {
    
    let generator: (Logger, EventLoop) -> EventLoopFuture<MDConnection>
    
    public func makeConnection(logger: Logger, on eventLoop: EventLoop) -> EventLoopFuture<MDConnectionPoolItem> {
        return generator(logger, eventLoop).map { MDConnectionPoolItem(connection: $0) }
    }
}
