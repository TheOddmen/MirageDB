//
//  MongoDBTest.swift
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

import MirageDB
import XCTest

class MongoDBTest: XCTestCase {
    
    var eventLoopGroup: MultiThreadedEventLoopGroup!
    var connection: MDConnection!
    
    override func setUpWithError() throws {
        
        do {
            
            eventLoopGroup = MultiThreadedEventLoopGroup(numberOfThreads: 1)
            
            var url = URLComponents()
            url.scheme = "mongodb"
            url.host = env("MONGO_HOST") ?? "localhost"
            url.user = env("MONGO_USERNAME")
            url.password = env("MONGO_PASSWORD")
            url.path = "/\(env("MONGO_DATABASE") ?? "")"
            
            var queryItems: [URLQueryItem] = []
            
            if let authSource = env("MONGO_AUTHSOURCE") {
                queryItems.append(URLQueryItem(name: "authSource", value: authSource))
            }
            
            if let ssl_mode = env("MONGO_SSLMODE") {
                queryItems.append(URLQueryItem(name: "ssl", value: "true"))
                queryItems.append(URLQueryItem(name: "sslmode", value: ssl_mode))
            }
            
            url.queryItems = queryItems.isEmpty ? nil : queryItems
            
            self.connection = try MDConnection.connect(url: url, on: eventLoopGroup).wait()
            
            print("MONGO:", try connection.version().wait())
            
        } catch {
            
            print(error)
            throw error
        }
    }
    
    override func tearDownWithError() throws {
        
        do {
            
            try self.connection.close().wait()
            try eventLoopGroup.syncShutdownGracefully()
            
        } catch {
            
            print(error)
            throw error
        }
    }
    
}
