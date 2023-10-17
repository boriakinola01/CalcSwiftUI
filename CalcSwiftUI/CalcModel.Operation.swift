//
//  CalcModel.Operation.swift
//  Calc
//
//  Created by Bori Akinola on 05/10/2023.
//

import Foundation

extension CalcModel {
    enum CalcError: Error {
        case decodingError(String)
    }
    
    enum Operation: CustomStringConvertible, Codable {
        
        static var supportedOperators = [String: Operation]()
        
        enum CodingKeys: String, CodingKey {
            case operand = "operand"
            case unaryOperator = "unary.operator"
            case binaryOperator = "binary.operator"
        }
        
        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            switch self {
            case .operand(let value): try container.encode(value, forKey: .operand)
            case .unaryOperator(let symbol, _): try container.encode(symbol, forKey: .unaryOperator)
            case .binaryOperator(let symbol, _): try container.encode(symbol, forKey: .binaryOperator)
            }
        }
        
        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            if let operand = try? container.decode(Double.self, forKey: .operand) {
                self = .operand(operand)
            } else if let symbol = try? container.decode(String.self, forKey: .unaryOperator) {
                guard let operation = Operation.supportedOperators[symbol], case .unaryOperator(_, _) = operation
                else {
                    throw CalcError.decodingError("Unsupported Unary Operator: \(symbol)")
                }
                self = operation
            } else if let symbol = try? container.decode(String.self, forKey: .binaryOperator) {
                guard let operation = Operation.supportedOperators[symbol], case .binaryOperator(_, _) = operation
                else {
                    throw CalcError.decodingError("Unsupported Binary Operator: \(symbol)")
                }
                self = operation
            } else {
                throw CalcError.decodingError("Unsupported Operation/Operand")
            }
        }
        
        case operand(Double)
        case unaryOperator(String, (Double) -> Double)
        case binaryOperator(String, (Double, Double) -> Double)
        
        var description: String {
            get {
                switch self {
                case .operand(let value):
                    return "\(value)"
                case .binaryOperator(let symbol, _):
                    fallthrough
                case .unaryOperator(let symbol, _):
                    return symbol
                }
            }
        }
    }
}
