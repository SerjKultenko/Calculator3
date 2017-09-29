//
//  ViewController.swift
//  Calculator
//
//  Created by Kultenko Sergey on 18.02.17.
//  Copyright © 2017 Sergey Kultenko. All rights reserved.
//

import UIKit


class CalculatorViewController: UIViewController {
    @IBOutlet weak var displayLabel: UILabel!
    @IBOutlet weak var historyLabel: UILabel!
    @IBOutlet weak var variablesLabel: UILabel!
    @IBOutlet weak var errorsLabel: UILabel!
    @IBOutlet weak var updateGraphicButton: UIButton!

    var calculatorNumbersTaping = false
    var calculatorModel = CalculatorModel()
    var calculatorVariables = Dictionary<String, Double>()
    
    @IBAction func backSpaceAction(_ sender: UIButton) {
        if calculatorNumbersTaping {
            guard calculatorNumbersTaping,
                var enteredString:String = displayLabel.text else {
                    return
            }
            
            if enteredString.characters.count==0 {
                return
            }
            enteredString = String(enteredString[..<enteredString.index(before: enteredString.endIndex)])
            if enteredString != "" &&
                enteredString[enteredString.index(before: enteredString.endIndex)...]=="."
            {
                enteredString = String(enteredString[..<enteredString.index(before: enteredString.endIndex)])
            }
            if enteredString.isEmpty {
                enteredString = " "
            }
            displayLabel.text = enteredString
            calculatorNumbersTaping = true
        } else {
            calculatorModel.undo()
            updateLabels()
        }
    }
    
    @IBAction func buttonAction(_ sender: UIButton) {
        if !calculatorNumbersTaping {
            displayLabel.text = ""
        }
        if displayLabel.text == " " {
            displayLabel.text = ""
        }
       
        guard (displayLabel.text != nil) else {
            return
        }
        
        let buttonString = sender.currentTitle!
        
        guard !(buttonString == "." && displayLabel.text!.contains("."))  else {
            return
        }
        
        if buttonString == "." && !calculatorNumbersTaping {
            displayLabel.text = "0."
        } else {
            displayLabel.text = displayLabel.text! + buttonString
        }
        
        calculatorNumbersTaping = true

        updateLabels()
    }

    private func formatNumber(_ number:Double) -> String {
        let formatter=NumberFormatter()
        formatter.maximumFractionDigits = 6
        formatter.minimumIntegerDigits = 1
        return formatter.string(from: NSNumber(value: number)) ?? ""
    }
    
    @IBAction func performOperationAction(_ sender: UIButton) {
        guard let operationTitle = sender.currentTitle,
            !operationTitle.isEmpty else {
                return
        }
        
        if calculatorNumbersTaping {
            if let currentValue = Double(displayLabel.text!) {
                calculatorModel.setOperand(operand: currentValue)
            }
        }
        
        calculatorNumbersTaping = false
        
        if operationTitle == "C" {
            calculatorVariables.removeAll()
        }
        
        calculatorModel.performOperation(operationString: operationTitle)
        updateLabels()
    }

    @IBAction func setVariableOperandAction(_ sender: UIButton) {
        guard let buttonString = sender.currentTitle  else {
            return
        }

        calculatorModel.setOperand(variable: buttonString)
        
        updateLabels()
    }
  
    
    @IBAction func saveToVariable(_ sender: UIButton) {
        guard let buttonString = sender.currentTitle  else {
            return
        }
        
        let variableName = buttonString.replacingOccurrences(of: "->", with: "")
        
        
        if calculatorNumbersTaping {
            if let currentValue = Double(displayLabel.text!) {
                calculatorVariables[variableName] = currentValue
            }
            calculatorNumbersTaping = false
        } else {
            let result = calculatorModel.evaluate(using: calculatorVariables)
            calculatorVariables[variableName] = result.result ?? 0
        }
        
        updateLabels()
    }
    
    override func viewDidLoad() {
        historyLabel.text = " "
        errorsLabel.text = " "
//        loadCalculatorModel()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        updateLabels()
    }
    
    private func updateLabels() {
        let result = calculatorModel.evaluate(using: calculatorVariables)
        let resultNumber = result.result ?? 0
        
        if !calculatorNumbersTaping {
            displayLabel.text = formatNumber(resultNumber)
        }
        
        let text = result.description + (result.isPending ? " ..." : " =")
        historyLabel.text = text
        
        if result.isPending {
            updateGraphicButton.isEnabled = false
            updateGraphicButton.backgroundColor = UIColor.red
        } else {
            updateGraphicButton.isEnabled = true
            updateGraphicButton.backgroundColor = UIColor.blue
        }
        
        updateErrorsLabel(forNumber: resultNumber)
        updateVariablesLabels()
    }
    
    func updateErrorsLabel(forNumber number: Double) {
        if number.isInfinite || number.isNaN {
            errorsLabel.isHidden = false
            errorsLabel.text = "Error: " + formatNumber(number)
        } else {
            errorsLabel.isHidden = true
        }
    }
    
    func updateVariablesLabels() {
        var textToDisplay = ""
        for variable in calculatorVariables {
            textToDisplay += "\(variable.key) = \(variable.value) "
        }
        
        variablesLabel.text = textToDisplay
    }
    
    private let kSaveCalculatorModelKey = "SaveCalculatorModelKey"

    func loadCalculatorModel() {
        guard
            let dict = UserDefaults.standard.object(forKey: kSaveCalculatorModelKey) as? NSDictionary,
            let savedCalculatorModel = CalculatorModel(from: dict)
            else {
                return
        }
        calculatorModel = savedCalculatorModel
    }
    
    func saveCalculatorModel() {
        let dict = calculatorModel.encodeAsDictionary()
        UserDefaults.standard.set(dict, forKey: kSaveCalculatorModelKey)
        UserDefaults.standard.synchronize()
    }
    
    func getGraphDataSource() -> GraphDataSource {
        let savedCalculatorModel = self.calculatorModel.copy()
        let result = self.calculatorModel.evaluate()
        let description = result.description
        return GraphDataSourceImplementation(withDataSourceBlock: { (varSubstitute) -> Double in
            let variables = ["M" : varSubstitute]
            let result = savedCalculatorModel.evaluate(using: variables)
            return result.result ?? 0
        }, description: description)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let vc = segue.destination.contents as? GraphicViewController {
            let calculatorModelResult = calculatorModel.evaluate()
            if !calculatorModelResult.isPending {
                saveCalculatorModel()
                vc.navigationItem.title = calculatorModelResult.description
                vc.graphDataSource = getGraphDataSource()
            } else {
                vc.graphDataSource = nil
            }
            
        }
    }
}

extension UIViewController {
    var contents: UIViewController {
        get {
            if let navigation = self as? UINavigationController {
                return navigation.visibleViewController ?? self
            } else {
                return self
            }
        }
    }
}

