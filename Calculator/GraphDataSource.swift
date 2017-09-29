//
//  GraphDataSource.swift
//  Calculator
//
//  Created by Sergei Kultenko on 05/09/2017.
//  Copyright © 2017 Sergey Kultenko. All rights reserved.
//

import Foundation

protocol GraphDataSource {
    var description: String {get}
    func calculateY(forX xValue:Double) -> Double
}
