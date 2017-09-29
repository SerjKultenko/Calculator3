//
//  GraphDataSourceImplementation.swift
//  Calculator
//
//  Created by Sergei Kultenko on 05/09/2017.
//  Copyright © 2017 Sergey Kultenko. All rights reserved.
//

import Foundation

class GraphDataSourceImplementation: GraphDataSource {
    private let dataSource: (_ x: Double) -> Double
    
    let description: String
    
    init(withDataSourceBlock block: @escaping (_ x: Double) -> Double, description: String) {
        dataSource = block
        self.description = description
    }
    
    func calculateY(forX xValue: Double) -> Double {
        return dataSource(xValue)
    }
}
