//
//  CalcModel.swift
//  Calc
//
//  Created by Bori Akinola on 23/09/2023.
//

import Foundation

struct CalcModel: Codable {
    private var stack = [Operation]()
    typealias PropertyList = Any
    
    var session: PropertyList {
        get {
            return stack.map{ $0.description } as CalcModel.PropertyList
        }
        set {
            if let operations = newValue as? [String] {
                var newStack = [Operation]()
                
                for operation in operations {
                    if let knownOperation = Operation.supportedOperators[operation] {
                        newStack.append(knownOperation)
                    } else if let operand = Double(operation) {
                        newStack.append(.operand(operand))
                    }
                }
                stack = newStack
            }
        }
    }
    
    init() {
        var operators = [String: Operation]()
        func newOperator(_ operation: Operation) {
            operators[operation.description] = operation
        }
    
        newOperator(.binaryOperator("+", +))
        newOperator(.binaryOperator("×", *))
        newOperator(.binaryOperator("÷", {$1 / $0}))
        newOperator(.binaryOperator("-", {$1 - $0}))
        newOperator(.unaryOperator("±", -))
        Operation.supportedOperators = operators
    }
    
    func json() throws -> Data {
        return try JSONEncoder().encode(self)
    }
    
    init(json data: Data) throws {
        self.init()
        self = try JSONDecoder().decode(CalcModel.self, from: data)
    }
    
    init(url: URL) throws {
        let data = try Data(contentsOf: url)
        self = try CalcModel(json: data)
    }
    
    mutating func pushOperand(_ operandValue: Double) -> Double? {
        stack.append(Operation.operand(operandValue))
        return evaluateStack()
    }
    
    mutating func evaluateStack() -> Double? {
        func evaluateStack(_ stack: [Operation]) -> (result: Double?, leftOverStack: [Operation]) {
            if !stack.isEmpty {
                var leftOverStack = stack
                let operation = leftOverStack.removeLast()
                switch operation {
                case .operand(let operand):
                    return (operand, leftOverStack)
                case .binaryOperator(_, let operation):
                    let firstEval = evaluateStack(leftOverStack)
                    if let firstEvalResult = firstEval.result {
                        let secondEval = evaluateStack(firstEval.leftOverStack)
                        if let secondEvalResult = secondEval.result {
                            return (operation(firstEvalResult, secondEvalResult), secondEval.leftOverStack)
                        }
                    }
                default:
                    break
                }
            }
            return (nil, stack)
        }
        
        let (result, leftOverStack) = evaluateStack(stack)
        if let evaluation = result {
            print("\(stack) = \(evaluation) with \(leftOverStack) left over")
        }
        
        return result
    }
    
    private func multiply(_ op1: Double,_ op2: Double) -> Double {
        return op1 * op2
    }
    
    mutating func performOperation(_ symbol: String) -> Double?{
        if let operation = Operation.supportedOperators[symbol] {
            stack.append(operation)
        }
        
        return evaluateStack()
    }
}

