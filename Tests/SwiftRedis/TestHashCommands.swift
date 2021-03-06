/**
 * Copyright IBM Corporation 2016
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 **/

import SwiftRedis

import Foundation
import XCTest

public class TestHashCommands: XCTestCase {
    static var allTests : [(String, (TestHashCommands) -> () throws -> Void)] {
        return [
            ("test_hashSetAndGet", test_hashSetAndGet),
            ("test_Incr", test_Incr),
            ("test_bulkCommands", test_bulkCommands),
            ("test_binarySafeHsetAndHmset", test_binarySafeHsetAndHmset)
        ]
    }
    
    let key1 = "test1"
    
    let field1 = "f1"
    let field2 = "f2"
    let field3 = "f3"
    let field4 = "f4"
    
    func test_hashSetAndGet() {
        setupTests() {
            let expVal1 = "testing, testing, 1 2 3"
            let expVal2 = "hi hi, hi ho, its off to test we go"
            
            redis.hset(self.key1, field: self.field1, value: expVal1) {(newField: Bool, error: NSError?) in
                XCTAssertNil(error, "\(error != nil ? error!.localizedDescription : "")")
                XCTAssert(newField, "\(self.field1) wasn't a new field in \(self.key1)")
                
                redis.hset(self.key1, field: self.field1, value: expVal2) {(newField: Bool, error: NSError?) in
                    XCTAssertNil(error, "\(error != nil ? error!.localizedDescription : "")")
                    XCTAssertFalse(newField, "\(self.field1) wasn't an existing field in \(self.key1)")
                    
                    redis.hget(self.key1, field: self.field1) {(value: RedisString?, error: NSError?) in
                        XCTAssertNil(error, "\(error != nil ? error!.localizedDescription : "")")
                        XCTAssertNotNil(value, "\(self.field1) in \(self.key1) had no value")
                        XCTAssertEqual(value!.asString, expVal2, "The value of \(self.field1) in \(self.key1) wasn't '\(expVal2)'")
                        
                        redis.hexists(self.key1, field: self.field2) {(exists: Bool, error: NSError?) in
                            XCTAssertNil(error, "\(error != nil ? error!.localizedDescription : "")")
                            XCTAssertFalse(exists, "\(self.field2) isn't suppose to exist in \(self.key1)")
                            
                            redis.hset(self.key1, field: self.field2, value: expVal1) {(newField: Bool, error: NSError?) in
                                XCTAssertNil(error, "\(error != nil ? error!.localizedDescription : "")")
                                XCTAssert(newField, "\(self.field2) wasn't a new field in \(self.key1)")
                                
                                redis.hlen(self.key1) {(count: Int?, error: NSError?) in
                                    XCTAssertNil(error, "\(error != nil ? error!.localizedDescription : "")")
                                    XCTAssertNotNil(count, "Count value shouldn't be nil")
                                    XCTAssertEqual(count!, 2, "There should be two fields in \(self.key1)")
                                    
                                    redis.hset(self.key1, field: self.field1, value: expVal2, exists: false) {(newField: Bool, error: NSError?) in
                                        XCTAssertNil(error, "\(error != nil ? error!.localizedDescription : "")")
                                        XCTAssertFalse(newField, "\(self.field1) wasn't an existing field in \(self.key1)")
                                    
                                        redis.hdel(self.key1, fields: self.field1, self.field2) {(deleted: Int?, error: NSError?) in
                                            XCTAssertNil(error, "\(error != nil ? error!.localizedDescription : "")")
                                            XCTAssertNotNil(deleted, "Deleted count value shouldn't be nil")
                                            XCTAssertEqual(deleted!, 2, "Two fields in \(self.key1) should have been deleted")
                                        
                                            redis.hget(self.key1, field: self.field1) {(value: RedisString?, error: NSError?) in
                                                XCTAssertNil(error, "\(error != nil ? error!.localizedDescription : "")")
                                                XCTAssertNil(value, "\(self.field1) in \(self.key1) should have no value")
                                                
                                                redis.hset(self.key1, field: self.field1, value: expVal1, exists: false) {(newField: Bool, error: NSError?) in
                                                    XCTAssertNil(error, "\(error != nil ? error!.localizedDescription : "")")
                                                    XCTAssert(newField, "\(self.field1) wasn't a new field in \(self.key1)")
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    func test_Incr() {
        setupTests() {
            let incInt = 10
            let incFloat: Float = 8.5
                    
            redis.hincr(self.key1, field: self.field3, by: incInt) {(value: Int?, error: NSError?) in
                XCTAssertNil(error, "\(error != nil ? error!.localizedDescription : "")")
                XCTAssertNotNil(value, "Value of field shouldn't be nil")
                XCTAssertEqual(value!, incInt, "Value of field should be \(incInt), was \(value!)")
                        
                redis.hincr(self.key1, field: self.field2, byFloat: incFloat) {(value: RedisString?, error: NSError?) in
                    XCTAssertNil(error, "\(error != nil ? error!.localizedDescription : "")")
                    XCTAssertNotNil(value, "Value of field shouldn't be nil")
                    XCTAssertEqual(value!.asDouble, Double(incFloat), "Value of field should be \(incFloat), was \(value!.asDouble)")
                            
                        /* ****************
                         *   HSTRLEN is only on Redis 3.2 and above *
                     
                    let expVal1 = "testing, testing, 1 2 3"
                     
                    redis.hset(self.key1, field: self.field1, value: expVal1) {(newField: Bool, error: NSError?) in
                        XCTAssertNil(error, "\(error != nil ? error!.localizedDescription : "")")
                        XCTAssert(newField, "\(self.field1) wasn't a new field in \(self.key1)")
                                
                        redis.hstrlen(self.key1, field: self.field1) {(length: Int?, error: NSError?) in
                            XCTAssertNil(error, "\(error != nil ? error!.localizedDescription : "")")
                            XCTAssertNotNil(length, "Length of field shouldn't be nil")
                            XCTAssertEqual(length!, expVal1.characters.count, "Length of field should be \(expVal1.characters.count), was \(length!)")
                        }
                    }
                          **************** */
                }
            }
        }
    }
    
    func test_bulkCommands() {
        setupTests() {
            let expVal1 = "Hi ho, hi ho"
            let expVal2 = "it's off to test"
            let expVal3 = "we go"
            
            redis.hmset(self.key1, fieldValuePairs: (self.field1, expVal1), (self.field2, expVal2), (self.field3, expVal3)) {(wereSet: Bool, error: NSError?) in
                XCTAssertNil(error, "\(error != nil ? error!.localizedDescription : "")")
                XCTAssert(wereSet, "Fields 1,2,3 should have been set")
                
                redis.hget(self.key1, field: self.field1) {(value: RedisString?, error:NSError?) in
                    XCTAssertNil(error, "\(error != nil ? error!.localizedDescription : "")")
                    XCTAssertEqual(value!.asString, expVal1, "\(self.key1).\(self.field1) wasn't set to \(expVal1). Instead was \(value)")
                    
                    redis.hmget(self.key1, fields: self.field1, self.field2, self.field4, self.field3) {(values: [RedisString?]?, error: NSError?) in
                        XCTAssertNil(error, "\(error != nil ? error!.localizedDescription : "")")
                        XCTAssertNotNil(values, "Received a nil values array")
                        XCTAssertEqual(values!.count, 4, "Values array didn't have four elements. Had \(values!.count) elements")
                        XCTAssertNotNil(values![0], "Values array [0] was nil")
                        XCTAssertEqual(values![0]!.asString, expVal1, "Values array [0] wasn't equal to \(expVal1), was \(values![0]!)")
                        XCTAssertNotNil(values![1], "Values array [1] was nil")
                        XCTAssertEqual(values![1]!.asString, expVal2, "Values array [1] wasn't equal to \(expVal2), was \(values![1]!)")
                        XCTAssertNil(values![2], "Values array [2] wasn't nil. Was \(values![2])")
                        XCTAssertNotNil(values![3], "Values array [3] was nil")
                        XCTAssertEqual(values![3]!.asString, expVal3, "Values array [3] wasn't equal to \(expVal3), was \(values![3]!)")
                        
                        redis.hkeys(self.key1) {(fields: [String]?, error : NSError?) in
                            XCTAssertNil(error, "\(error != nil ? error!.localizedDescription : "")")
                            XCTAssertNotNil(fields, "Received a nil field names array")
                            XCTAssertEqual(fields!.count, 3, "Field names array didn't have three elements. Had \(fields!.count) elements")
                            
                            redis.hvals(self.key1) {(values: [RedisString?]?, error: NSError?) in
                                XCTAssertNil(error, "\(error != nil ? error!.localizedDescription : "")")
                                XCTAssertNotNil(values, "Received a nil values array")
                                XCTAssertEqual(values!.count, 3, "Values array didn't have three elements. Had \(values!.count) elements")
                                
                                redis.hgetall(self.key1) {(values: [String: RedisString], error: NSError?) in
                                    XCTAssertNil(error, "\(error != nil ? error!.localizedDescription : "")")
                                    XCTAssertEqual(values.count, 3, "There should have been 3 fields in \(self.key1), there were \(values.count) fields")
                                    
                                    let fieldNames = [self.field1, self.field2, self.field3]
                                    let fieldValues = [expVal1, expVal2, expVal3]
                                    for idx in 0..<fieldNames.count {
                                        let field = values[fieldNames[idx]]
                                        XCTAssertNotNil(field, "\(fieldNames[idx]) in \(self.key1) was nil")
                                        XCTAssertEqual(field!.asString, fieldValues[idx], "\(fieldNames[idx]) in \(self.key1) wasn't '\(fieldValues[idx])', it was \(field)")
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    func test_binarySafeHsetAndHmset() {
        setupTests() {
            var bytes: [UInt8] = [0xff, 0x00, 0xfe, 0x02]
            #if os(Linux)
                let expData1 = NSData(bytes: bytes, length: bytes.count)
            #else
                let expData1 = Data(bytes: bytes, count: bytes.count)
            #endif
            redis.hset(self.key1, field: self.field1, value: RedisString(expData1)) {(wasSet: Bool, error: NSError?) in
                XCTAssertNil(error, "\(error != nil ? error!.localizedDescription : "")")
                XCTAssert(wasSet, "\(self.key1).\(self.field1) wasn't set")
                
                bytes = [0x00, 0x01, 0x02, 0x03, 0x04]
                #if os(Linux)
                    let expData2 = NSData(bytes: bytes, length: bytes.count)
                #else
                    let expData2 = Data(bytes: bytes, count: bytes.count)
                #endif
                bytes = [0xf0, 0xf1, 0xf2, 0xf3, 0xf4]
                #if os(Linux)
                    let expData3 = NSData(bytes: bytes, length: bytes.count)
                #else
                    let expData3 = Data(bytes: bytes, count: bytes.count)
                #endif
                
                redis.hmset(self.key1, fieldValuePairs: (self.field2, RedisString(expData2)), (self.field3, RedisString(expData3))){(wereSet: Bool, error: NSError?) in
                    XCTAssertNil(error, "\(error != nil ? error!.localizedDescription : "")")
                    XCTAssert(wereSet, "\(self.key1).\(self.field2)/\(self.field3) weren't set")
                    
                    redis.hgetall(self.key1) {(values: [String: RedisString], error: NSError?) in
                        XCTAssertNil(error, "\(error != nil ? error!.localizedDescription : "")")
                        XCTAssertEqual(values.count, 3, "There should have been 3 fields in \(self.key1), there were \(values.count) fields")
                        
                        let fieldNames = [self.field1, self.field2, self.field3]
                        let fieldValues = [expData1, expData2, expData3]
                        for idx in 0..<fieldNames.count {
                            let field = values[fieldNames[idx]]
                            XCTAssertNotNil(field, "\(fieldNames[idx]) in \(self.key1) was nil")
                            XCTAssertEqual(field!.asData, fieldValues[idx], "\(fieldNames[idx]) in \(self.key1) wasn't '\(fieldValues[idx])', it was \(field)")
                        }
                    }
                }
            }
        }
    }
    
    
    private func setupTests(callback: () -> Void) {
        connectRedis() {(error: NSError?) in
            XCTAssertNil(error, "\(error != nil ? error!.localizedDescription : "")")
            
            redis.del(self.key1) {(deleted: Int?, error: NSError?) in
                callback()
            }
        }
    }
}
