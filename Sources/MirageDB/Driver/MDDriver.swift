//
//  MDDriver.swift
//
//  The MIT License
//  Copyright (c) 2021 - 2024 O2ter Limited. All rights reserved.
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
    ) async throws -> Void
    
    func addColumns(
        _ connection: MDConnection,
        _ table: String,
        _ columns: [String: MDSQLDataType]
    ) async throws -> Void
    
    func dropTable(
        _ connection: MDConnection,
        _ table: String
    ) async throws -> Void
    
    func dropColumns(
        _ connection: MDConnection,
        _ table: String,
        _ columns: Set<String>
    ) async throws -> Void
    
    func addIndex(
        _ connection: MDConnection,
        _ table: String,
        _ index: MDSQLTableIndex
    ) async throws -> Void
    
    func dropIndex(
        _ connection: MDConnection,
        _ table: String,
        _ index: String
    ) async throws -> Void
    
    func tables(_ connection: MDConnection) async throws -> [String]
    
    func stats(_ connection: MDConnection, _ class: String) async throws -> MDTableStats
    
    func count(_ query: MDFindExpression) async throws -> Int
    
    func toArray(_ query: MDFindExpression) async throws -> [MDObject]
    
    func forEach(
        _ query: MDFindExpression,
        _ body: @escaping (MDObject) throws -> Void
    ) async throws -> Void
    
    func first(_ query: MDFindExpression) async throws -> MDObject?
    
    func findOneAndUpdate(
        _ query: MDFindOneExpression,
        _ update: [MDQueryKey: MDUpdateOption]
    ) async throws -> MDObject?
    
    func findOneAndUpsert(
        _ query: MDFindOneExpression,
        _ update: [MDQueryKey: MDUpdateOption],
        _ setOnInsert: [MDQueryKey: MDDataConvertible]
    ) async throws -> MDObject?
    
    func findOneAndDelete(_ query: MDFindOneExpression) async throws -> MDObject?
    
    func deleteAll(_ query: MDFindExpression) async throws -> Int?
    
    func insert(
        _ connection: MDConnection,
        _ class: String,
        _ data: [MDQueryKey: MDData]
    ) async throws -> MDObject
    
    func withTransaction<T>(
        _ connection: MDConnection,
        _ options: MDTransactionOptions,
        _ transactionBody: @escaping (MDConnection) async throws -> T
    ) async throws -> T
    
}
