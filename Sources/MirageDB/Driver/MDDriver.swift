//
//  MDDriver.swift
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

protocol MDDriver {
    
    func createTable(
        _ connection: MDConnection,
        _ table: String,
        _ columns: [String: MDSQLDataType]
    ) -> EventLoopFuture<Void>
    
    func addColumns(
        _ connection: MDConnection,
        _ table: String,
        _ columns: [String: MDSQLDataType]
    ) -> EventLoopFuture<Void>
    
    func dropTable(
        _ connection: MDConnection,
        _ table: String
    ) -> EventLoopFuture<Void>
    
    func dropColumns(
        _ connection: MDConnection,
        _ table: String,
        _ columns: Set<String>
    ) -> EventLoopFuture<Void>
    
    func addIndex(
        _ connection: MDConnection,
        _ table: String,
        _ index: MDSQLTableIndex
    ) -> EventLoopFuture<Void>
    
    func dropIndex(
        _ connection: MDConnection,
        _ table: String,
        _ index: String
    ) -> EventLoopFuture<Void>
    
    func tables(_ connection: MDConnection) -> EventLoopFuture<[String]>
    
    func count(_ query: MDFindExpression) -> EventLoopFuture<Int>
    
    func toArray(_ query: MDFindExpression) -> EventLoopFuture<[MDObject]>
    
    func forEach(
        _ query: MDFindExpression,
        _ body: @escaping (MDObject) throws -> Void
    ) -> EventLoopFuture<Void>
    
    func first(_ query: MDFindExpression) -> EventLoopFuture<MDObject?>
    
    func findOneAndUpdate(
        _ query: MDFindOneExpression,
        _ update: [String: MDUpdateOption]
    ) -> EventLoopFuture<MDObject?>
    
    func findOneAndUpsert(
        _ query: MDFindOneExpression,
        _ upsert: [String: MDUpsertOption]
    ) -> EventLoopFuture<MDObject?>
    
    func findOneAndDelete(_ query: MDFindOneExpression) -> EventLoopFuture<MDObject?>
    
    func deleteAll(_ query: MDFindExpression) -> EventLoopFuture<Int?>
    
    func insert(
        _ connection: MDConnection,
        _ class: String,
        _ data: [String: MDData]
    ) -> EventLoopFuture<MDObject>
    
    func withTransaction<T>(
        _ connection: MDConnection,
        _ transactionBody: @escaping () throws -> EventLoopFuture<T>
    ) -> EventLoopFuture<T>
    
}
