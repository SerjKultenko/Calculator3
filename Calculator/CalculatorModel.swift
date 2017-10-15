//
//  CalculatorModel.swift
//  Calculator
//
//  Created by Kultenko Sergey on 18.02.17.
//  Copyright © 2017 Sergey Kultenko. All rights reserved.
//

import Foundation

class CalculatorModel : Copyable/*, NSCoding*/ {
    private var operationsStack:[Operation] = []

    required init(other: CalculatorModel) {
        operationsStack = other.operationsStack
    }

    init() {
    }

    init?(from dictionary: NSDictionary) {
        let sortedDict = dictionary.sorted(by: {
            guard
                let key1String = $0.key as? String,
                let key1Numeric = Int(key1String),
                let key2String = $1.key as? String,
                let key2Numeric = Int(key2String)
                else {
                    return false
            }
            return key1Numeric < key2Numeric
        })
        for (_, value) in sortedDict {
            if let operationDict = value as? NSDictionary,
                let oper = createOperation(from: operationDict) {
                operationsStack.append(oper)
            }
        }
    }
    
    func encodeAsDictionary()->NSDictionary {
        let dictionary = NSMutableDictionary()
        for (index, operation) in operationsStack.enumerated() {
            dictionary.setValue(operation.encodeAsDictionary(), forKey: String(index))
        }
        return dictionary
    }
    
    private static let kOperandNumberKey = "Number"
    private static let kOperandVariableKey = "Variable"
    
    private enum Operand {
        case Number(Double)
        case Variable(String)

        func encodeAsDictionary() -> NSDictionary {
            switch self {
            case .Number(let number):
                return [kOperandNumberKey : number]
            case .Variable(let varName):
                return [kOperandVariableKey : varName]
            }
        }
        init?(from dictionary: NSDictionary) {
            if let number = dictionary[kOperandNumberKey] as? Double {
                self = .Number(number)
            } else if let varName = dictionary[kOperandVariableKey] as? String {
                self = .Variable(varName)
            } else {
                return nil
            }
        }
    }

    func setOperand(operand: Double) {
        operationsStack.append(Operation.Operand("", .Number(operand)))
    }

    func setOperand(variable named:String) {
        operationsStack.append(Operation.Operand("Var", .Variable(named)))
    }

    private enum Operation {
        case Constant(String, Double)
        case OperationWithoutArgument(String, () -> Double)
        case UnaryOperation(String, (Double) -> Double)
        case BinaryOperation(String, (Double, Double) -> Double)
        case PercentOperation(String)
        case Operand(String, Operand)
        case Equals(String)
        case Reset
        
        func encodeAsDictionary() -> NSDictionary {
            switch self {
            case .Constant(let description, let value):
                return ["Constant" : ["description" : description,
                                      "value" : value]]
            case .Operand(let description, let operand):
                return ["Operand" : ["description" : description,
                                     "operand" : operand.encodeAsDictionary()]]
            case .UnaryOperation(let description, _):
                return ["UnaryOperation" : description]
            case .BinaryOperation(let description, _):
                return ["BinaryOperation" : description]
            case .PercentOperation(let description):
                return ["PercentOperation" : description]
            case .OperationWithoutArgument(let description, _):
                return ["OperationWithoutArgument" : description]
            case .Equals:
                return ["Equals" : "="]
            case .Reset:
                return ["Reset" : true]
            }
        }
    }

    private func createOperation(from dictionary: NSDictionary) -> Operation? {
        guard dictionary.count == 1,
            let keyName = dictionary.allKeys[0] as? String else {
                return nil
        }
        guard let operationValue = dictionary[keyName] else {
            return nil
        }
        
        switch keyName {
        case "Constant":
            guard let description = operationValue as? String else {
                return nil
            }
            return operations[description]
        case "Operand":
            guard
                let operationDict = operationValue as? NSDictionary,
                let description = operationDict["description"] as? String,
                let operandDict = operationDict["operand"] as? NSDictionary,
                let operand = CalculatorModel.Operand(from: operandDict)
                else {
                    return nil
            }
            return .Operand(description, operand)
        case "UnaryOperation":
            guard let description = operationValue as? String else {
                return nil
            }
            return operations[description]
        case "BinaryOperation":
            guard let description = operationValue as? String else {
                    return nil
            }
            return operations[description]
        case "PercentOperation":
            guard let description = operationValue as? String else {
                return nil
            }
            return operations[description]
        case "OperationWithoutArgument":
            guard let description = operationValue as? String else {
                return nil
            }
            return operations[description]
        case "Equals":
            guard let description = operationValue as? String else {
                return nil
            }
            return .Equals(description)
        case "Reset":
            return .Reset
        default:
            return nil
        }
    }
    
    private static let powerOf2Description = "\u{00B2}"
    private static let powerOf3Description = "\u{00B3}"

    private var operations: Dictionary<String, Operation> = [
        "π" : Operation.Constant("π", Double.pi),
        "e" : Operation.Constant("e", M_E),
        "√" : Operation.UnaryOperation("√", sqrt),
        "cos" : Operation.UnaryOperation("cos", cos),
        "sin" : Operation.UnaryOperation("sin", sin),
        "x²" : Operation.UnaryOperation(powerOf2Description, {pow($0, 2)}),
        "x³" : Operation.UnaryOperation(powerOf3Description, {pow($0, 3)}),
        "+" : Operation.BinaryOperation("+", {$0+$1}),
        "-" : Operation.BinaryOperation("-", {$0-$1}),
        "×" : Operation.BinaryOperation("×", {$0*$1}),
        "÷" : Operation.BinaryOperation("÷", {$0/$1}),
        "±" : Operation.UnaryOperation("±", {-$0}),
        "=" : Operation.Equals("="),
        "0～1" : Operation.OperationWithoutArgument("0～1", { Double(arc4random())/Double(UINT32_MAX)}),
        "%" : Operation.PercentOperation("%"),
        "C" : Operation.Reset,
    ]
    
    private struct PendingBinaryOperationInfo {
        var binaryFunction: (Double, Double) -> Double
        var firstOperand: Double
    }
    
    private func executePendingOperation(pendingOperation: PendingBinaryOperationInfo?,
                                         withOperand operand: Double,
                                         andDescription description: String) -> (result: Double?, isPending: Bool, description: String) {
        var operationDescription = ""
        var resultValue: Double?
        if pendingOperation != nil {
            operationDescription =  description + " "
            
            resultValue = pendingOperation!.binaryFunction(pendingOperation!.firstOperand, operand)
        }
        return (resultValue, false, operationDescription)
    }
    
    private func resetCalculator() -> Void {
        operationsStack = []
    }
    
    func performOperation(operationString:String) {
        if let currOperation = operations[operationString] {
            if case .Reset = currOperation {
                resetCalculator()
            } else {
                operationsStack.append(currOperation)
            }
        }
    }
    
    func undo() {
        guard operationsStack.count > 0 else {
            return
        }
        operationsStack.remove(at: operationsStack.count-1)
    }
    
    func evaluate(using variables: Dictionary<String,Double>? = nil) -> (result: Double?, isPending: Bool, description: String) {
        var accumulator = 0.0
        var calculatorDescription = ""
        var accumulatorDescription = ""
        var pendingOperation: PendingBinaryOperationInfo?
        
        for currOperation in operationsStack {
            switch currOperation {
            case .Constant(let description, let value):
                accumulator = value
                accumulatorDescription = description
            case .Operand(_, let operand):
                switch operand {
                case .Number(let number):
                    accumulator = number
                    accumulatorDescription = formatNumber(number)
                    if (pendingOperation == nil) {
                        calculatorDescription = ""
                    }
                case .Variable(let varName):
                    accumulatorDescription = varName
                    if let varValue = variables?[varName] {
                        accumulator = varValue
                    } else {
                        accumulator = 0.0
                    }

                    if (pendingOperation == nil) {
                        calculatorDescription = ""
                    }
                }
            case .UnaryOperation(let description, let function):
                accumulator = function(accumulator)
                let prevOperationDescr =  (accumulatorDescription.isEmpty ? calculatorDescription : accumulatorDescription)
                var thisOperationDescr = "(" + prevOperationDescr + ")"
                if description == CalculatorModel.powerOf2Description || description == CalculatorModel.powerOf3Description {
                    thisOperationDescr = thisOperationDescr + description
                } else {
                    thisOperationDescr = description + thisOperationDescr
                }
                if accumulatorDescription.isEmpty {
                    calculatorDescription = thisOperationDescr
                } else {
                    calculatorDescription += " " + thisOperationDescr
                }
                accumulatorDescription = ""
            case .BinaryOperation(let description, let function):
                if !calculatorDescription.isEmpty && !accumulatorDescription.isEmpty {
                    calculatorDescription += " "
                }
                calculatorDescription += accumulatorDescription
                let operationResult = executePendingOperation(pendingOperation: pendingOperation,
                                                              withOperand: accumulator,
                                                              andDescription: calculatorDescription)
                if operationResult.result != nil {
                    accumulator = operationResult.result ?? 0
                }
                pendingOperation = nil

                pendingOperation = PendingBinaryOperationInfo(binaryFunction: function, firstOperand: accumulator)
                calculatorDescription =  calculatorDescription + " " + description
            case .OperationWithoutArgument(let description, let function):
                pendingOperation = nil
                accumulator = function()
                calculatorDescription = description + "(" + accumulatorDescription + ")"
                accumulatorDescription = ""
            case .Equals(_):
                if !accumulatorDescription.isEmpty {
                    calculatorDescription += " " + accumulatorDescription
                    accumulatorDescription = ""
                }

                let operationResult = executePendingOperation(pendingOperation: pendingOperation,
                                                              withOperand: accumulator,
                                                              andDescription: calculatorDescription)
                if operationResult.result != nil {
                    accumulator = operationResult.result ?? 0
                }
                pendingOperation = nil
            case .Reset:
                resetCalculator()
                calculatorDescription = ""
                accumulatorDescription = ""
            case .PercentOperation(let description):
                if (pendingOperation != nil) {
                    accumulator = pendingOperation!.firstOperand / 100 * accumulator
                } else {
                    accumulator = accumulator / 100
                }
                
                if accumulatorDescription.isEmpty {
                    calculatorDescription = description + "(" + calculatorDescription + ")"
                } else {
                    calculatorDescription += " " + description + "(" + accumulatorDescription + ")"
                }
                accumulatorDescription = ""
            }
        }
        return (accumulator, pendingOperation != nil, calculatorDescription)
    }
    
    @available(*, deprecated)
    var result: Double {
        get {
            let evaluateResult = evaluate()
            return evaluateResult.result ?? 0
        }
    }
    
    private func formatNumber(_ number:Double) -> String {
        let formatter=NumberFormatter()
        formatter.maximumFractionDigits = 6
        formatter.minimumIntegerDigits = 1
        return formatter.string(from: NSNumber(value: number)) ?? ""
    }
    
    @available(*, deprecated)
    public var displayValue: String  {
        get {
            return formatNumber(result)
        }
    }
    
    @available(*, deprecated)
    public var resultIsPending: Bool {
        get {
            let evaluateResult = evaluate()
            return evaluateResult.isPending
        }
    }
    
    @available(*, deprecated)
    public var description:String {
        get {
            let evaluateResult = evaluate()
            return evaluateResult.description
        }
    }
    
    // MARK: - NSCoding support
//    required init?(coder aDecoder: NSCoder) {
//        if let operationsStack = aDecoder.decodeObject(forKey: "operationsStack") as? [Operation] {
//            self.operationsStack = operationsStack
//        }
//        //        graphicViewFrame = aDecoder.decodeCGRect(forKey: "graphicViewFrame")
//        //        scrollViewContentSize = aDecoder.decodeCGSize(forKey: "scrollViewContentSize")
//        //        scrollViewContentOffset = aDecoder.decodeCGPoint(forKey: "scrollViewContentOffset")
//        //        scale = CGFloat(aDecoder.decodeFloat(forKey: "scale"))
//    }
//    
//    public func encode(with aCoder: NSCoder) {
//        aCoder.encode(operationsStack, forKey: "operationsStack")
//        //        aCoder.encode(graphicViewFrame, forKey: "graphicViewFrame")
//        //        aCoder.encode(scrollViewContentSize, forKey: "scrollViewContentSize")
//        //        aCoder.encode(scrollViewContentOffset, forKey: "scrollViewContentOffset")
//        //        aCoder.encode(Float(scale), forKey: "scale")
//        let dd: Dictionary<String, Int>
//        
//        
//        let dict: NSMutableDictionary
//        dict.write(toFile: <#T##String#>, atomically: <#T##Bool#>)
//        
//    }

    
}
