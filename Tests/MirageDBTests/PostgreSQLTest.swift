//
//  PostgreSQLTest.swift
//
//  The MIT License
//  Copyright (c) 2021 - 2022 The Oddmen Technology Limited. All rights reserved.
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

class PostgreSQLTest: XCTestCase {
    
    var eventLoopGroup: MultiThreadedEventLoopGroup!
    var connection: MDConnection!
    
    override func setUpWithError() throws {
        
        do {
            
            eventLoopGroup = MultiThreadedEventLoopGroup(numberOfThreads: 1)
            
            var url = URLComponents()
            url.scheme = "postgres"
            url.host = env("POSTGRES_HOST") ?? "localhost"
            url.user = env("POSTGRES_USERNAME")
            url.password = env("POSTGRES_PASSWORD")
            url.path = "/\(env("POSTGRES_DATABASE") ?? "")"
            
            if let ssl_mode = env("POSTGRES_SSLMODE") {
                url.queryItems = [
                    URLQueryItem(name: "ssl", value: "true"),
                    URLQueryItem(name: "sslmode", value: ssl_mode),
                ]
            }
            
            var logger = Logger(label: "com.TheOddmen.MirageDB")
            logger.logLevel = .debug
            
            self.connection = try MDConnection.connect(url: url, logger: logger, on: eventLoopGroup).wait()
            
            print("POSTGRES:", try connection.version().wait())
            
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
    
    func testCreateTable() throws {
        
        do {
            
            let obj1 = try connection.query()
                .insert("testCreateTable", [
                    "name": "John",
                    "age": 10,
                ]).wait()
            
            XCTAssertEqual(obj1.id?.count, 10)
            XCTAssertEqual(obj1["name"], "John")
            XCTAssertEqual(obj1["age"], 10)
            
        } catch {
            
            print(error)
            throw error
        }
    }
    
    func testCustomObjectIDGenerator() throws {
        
        let OBJECT_ID_CHARS = "abcdefghijklmnopqrstuvwxyz0123456789"
        
        func objectIDGenerator() -> String {
            return (0..<10).reduce(into: "") { str, _ in str.append(OBJECT_ID_CHARS.randomElement()!) }
        }

        do {
            
            let obj = try connection.query()
                .findOne("testUpsertQuery")
                .filter { $0["col"] == "text_1" }
                .objectID(with: objectIDGenerator)
                .upsert([
                    "col": .set("text_1")
                ]).wait()
            
            XCTAssertEqual(obj?.id?.count, 10)
            XCTAssertEqual(obj?.id, obj?.id?.lowercased())
            XCTAssertEqual(obj?["col"].string, "text_1")
            
        } catch {
            
            print(error)
            throw error
        }
    }
    
    func testSetNil() throws {
        
        do {
            
            var obj = try connection.query().insert("testSetNil", ["col": 1]).wait()
            
            XCTAssertEqual(obj.id?.count, 10)
            XCTAssertEqual(obj["col"], 1)
            
            obj.set("col", nil)
            
            obj = try obj.save(on: connection).wait()
            
            XCTAssertEqual(obj["col"], nil)
            
        } catch {
            
            print(error)
            throw error
        }
    }
    
    func testExtendedJSON() throws {
        
        do {
            
            let json: MDData = [
                "boolean": true,
                "string": "",
                "integer": 1,
                "number": 2.0,
                "decimal": MDData(3 as Decimal),
                "timestamp": MDData(Date(timeIntervalSince1970: 10000)),
                "array": [],
                "dictionary": [:],
            ]
            
            let obj1 = try connection.query().insert("testExtendedJSON", ["col": json]).wait()
            
            XCTAssertEqual(obj1.id?.count, 10)
            XCTAssertEqual(obj1["col"], json)
            
        } catch {
            
            print(error)
            throw error
        }
    }
    
    func testPatternMatchingQuery() throws {
        
        do {
            
            let obj1 = try connection.query().insert("testPatternMatchingQuery", ["col": "text to be search"]).wait()
            let obj2 = try connection.query().insert("testPatternMatchingQuery", ["col": "long long' string%"]).wait()
            _ = try connection.query().insert("testPatternMatchingQuery", ["col": "long long' string%, hello"]).wait()
            
            let res1 = try connection.query()
                .find("testPatternMatchingQuery")
                .filter { .startsWith($0["col"], "text to ") }
                .toArray().wait()
            
            XCTAssertEqual(res1.count, 1)
            XCTAssertEqual(res1.first?.id, obj1.id)
            
            let res2 = try connection.query()
                .find("testPatternMatchingQuery")
                .filter { .endsWith($0["col"], "ong' string%") }
                .toArray().wait()
            
            XCTAssertEqual(res2.count, 1)
            XCTAssertEqual(res2.first?.id, obj2.id)
            
            let res3 = try connection.query()
                .find("testPatternMatchingQuery")
                .filter { .contains($0["col"], "long' s") }
                .toArray().wait()
            
            XCTAssertEqual(res3.count, 2)
            
        } catch {
            
            print(error)
            throw error
        }
    }
    
    func testUpdateQuery() throws {
        
        do {
            
            var obj = MDObject(class: "testUpdateQuery")
            obj = try obj.save(on: connection).wait()
            
            XCTAssertEqual(obj.id?.count, 10)
            
            obj["col"] = "text_1"
            
            obj = try obj.save(on: connection).wait()
            
            XCTAssertEqual(obj["col"].string, "text_1")
            
            let obj2 = try connection.query()
                .findOne("testUpdateQuery")
                .filter { $0.id == obj.id }
                .update([
                    "col": .set("text_2")
                ]).wait()
            
            XCTAssertEqual(obj2?.id, obj.id)
            XCTAssertEqual(obj2?["col"].string, "text_2")
            
            let obj3 = try connection.query()
                .findOne("testUpdateQuery")
                .filter { $0.id == obj.id }
                .returning(.before)
                .update([
                    "col": .set("text_3")
                ]).wait()
            
            XCTAssertEqual(obj3?.id, obj.id)
            XCTAssertEqual(obj3?["col"].string, "text_2")
            
        } catch {
            
            print(error)
            throw error
        }
    }
    
    func testUpsertQuery() throws {
        
        do {
            
            let obj = try connection.query()
                .findOne("testUpsertQuery")
                .filter { $0["col"] == "text_1" }
                .upsert([
                    "col": .set("text_1")
                ]).wait()
            
            XCTAssertEqual(obj?.id?.count, 10)
            XCTAssertEqual(obj?["col"].string, "text_1")
            
            let obj2 = try connection.query()
                .findOne("testUpsertQuery")
                .filter { $0.id == obj?.id }
                .upsert([
                    "col": .set("text_2")
                ]).wait()
            
            XCTAssertEqual(obj2?.id, obj?.id)
            XCTAssertEqual(obj2?["col"].string, "text_2")
            
            let obj3 = try connection.query()
                .findOne("testUpsertQuery")
                .filter { $0.id == obj?.id }
                .returning(.before)
                .upsert([
                    "col": .set("text_3")
                ]).wait()
            
            XCTAssertEqual(obj3?.id, obj?.id)
            XCTAssertEqual(obj3?["col"].string, "text_2")
            
        } catch {
            
            print(error)
            throw error
        }
    }
    
    func testIncludesQuery() throws {
        
        do {
            
            let obj = try connection.query()
                .findOne("testIncludesQuery")
                .filter { $0["dummy1"] == 1 }
                .includes(["dummy1", "dummy2"])
                .upsert([
                    "dummy1": .set(1),
                    "dummy2": .set(2),
                    "dummy3": .set(3),
                    "dummy4": .set(4),
                ]).wait()
            
            XCTAssertEqual(obj?.keys, ["dummy1", "dummy2"])
            
        } catch {
            
            print(error)
            throw error
        }
    }
    
    func testQueryNumberOperation() throws {
        
        do {
            
            var obj = MDObject(class: "testQueryNumberOperation")
            obj["col_1"] = 1
            obj["col_2"] = 1
            obj["col_3"] = 1
            
            obj = try obj.save(on: connection).wait()
            
            obj.increment("col_1", by: 2)
            obj.increment("col_2", by: 2)
            obj.increment("col_3", by: 2)
            
            obj = try obj.save(on: connection).wait()
            
            XCTAssertEqual(obj["col_1"].intValue, 3)
            XCTAssertEqual(obj["col_2"].intValue, 3)
            XCTAssertEqual(obj["col_3"].intValue, 3)
            
        } catch {
            
            print(error)
            throw error
        }
    }
    
}
