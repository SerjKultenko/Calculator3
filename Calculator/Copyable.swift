//
//  Copyable.swift
//  Calculator
//
//  Created by Sergei Kultenko on 06/09/2017.
//  Copyright © 2017 Sergey Kultenko. All rights reserved.
//

import Foundation

protocol Copyable
{
    init(other: Self)
}

extension Copyable
{
    func copy() -> Self
    {
        return Self.init(other: self)
    }
}
