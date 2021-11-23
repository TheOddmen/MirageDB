// swift-tools-version:5.3
//
//  Package.swift
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

import PackageDescription

let package = Package(
    name: "MirageDB",
    platforms: [
        .macOS(.v10_15),
    ],
    products: [
        .library(name: "MirageDB", targets: ["MirageDB"]),
        .library(name: "MirageDBVapor", targets: ["MirageDBVapor"]),
    ],
    dependencies: [
        .package(url: "https://github.com/vapor/vapor.git", from: "4.50.0"),
        .package(url: "https://github.com/SusanDoggie/swift-vapor-react.git", from: "0.0.1"),
        .package(url: "https://github.com/SusanDoggie/DoggieDB.git", from: "0.0.25"),
    ],
    targets: [
        .target(
            name: "MirageDB",
            dependencies: [
                .product(name: "DoggieDB", package: "DoggieDB"),
                .product(name: "DBMongo", package: "DoggieDB"),
            ]
        ),
        .target(
            name: "MirageDBVapor",
            dependencies: [
                .target(name: "MirageDB"),
                .product(name: "Vapor", package: "vapor"),
            ]
        ),
        .testTarget(
            name: "MirageDBTests",
            dependencies: [
                .target(name: "MirageDB"),
            ]
        ),
    ]
)
