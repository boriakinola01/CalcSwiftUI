//
//  ContentView.swift
//  CalcSwiftUI
//
//  Created by Bori Akinola on 17/10/2023.
//

import SwiftUI

struct CalcView: View {
    static let calcKeys: Set<CalcKey> = [
        CalcKey("1", (2, 0), (2, 1)),
        CalcKey("2", (2, 1), (2, 2)),
        CalcKey("3", (2, 2), (2, 3)),
        CalcKey("4", (1, 0), (1, 1)),
        CalcKey("5", (1, 1), (1, 2)),
        CalcKey("6", (1, 2), (1, 3)),
        CalcKey("7", (0, 0), (0, 1)),
        CalcKey("8", (0, 1), (0, 2)),
        CalcKey("9", (0, 2), (0, 3)),
        CalcKey(".", (3, 0), (3, 1)),
        CalcKey("0", (3, 1), (3, 2)),
        CalcKey("return.left", (3, 2), (3, 3), scale: 2, .gray, true),
        CalcKey("divide.square", (0, 3), (0, 4), scale: 3, .orange, true),
        CalcKey("multiply.square", (1, 3), (1, 4), scale: 3, .orange, true),
        CalcKey("minus.square", (2, 3), (2, 4), scale: 3, .orange, true),
        CalcKey("plus.square", (3, 3), (3, 4), scale: 3, .orange, true),
        CalcKey("plus.forwardslash.minus", (4, 0), (0, 0), scale: 3, .mint, true),
        CalcKey("x.squareroot", (4, 1), (1, 0), scale: 3, .mint, true),
        CalcKey("sqrt", (4, 1), (1, 0)),
        CalcKey("SIN", (4, 2), (2, 0)),
        CalcKey("COS", (4, 3), (3, 0))
    ]
    
    var keypadLayout: (portrait: [[CalcKey]], landscape: [[CalcKey]]) = (
        Self.calcKeys.keys(for: .portrait),
        Self.calcKeys.keys(for: .landscape)
    )
    
    var body: some View{
        GeometryReader {
            geom in
            let isLandscape = geom.size.width > geom.size.height
            VStack {
                DisplayView(text: "3.14159")
                    .frame(height: geom.size.height * (isLandscape ? 0.13 :0.15))
                    .padding([.top, .leading, .trailing])
                KeypadView(layout: keypadLayout)
                    .padding(.all)
            }
        }
    }
}

struct DisplayView: View {
    let text: String
    
    var body: some View {
        VStack(alignment: .trailing) {
            let shape = RoundedRectangle(cornerRadius: 8)
            shape.stroke(lineWidth: 2)
            shape.fill(.gray)
            Text(text)
                .multilineTextAlignment(.trailing)
                .font(.system(size: 48))
                .lineLimit(1)
        }
    }
}

struct KeypadView: View {
    let layout: (portrait:  [[CalcKey]], landscape: [[CalcKey]])
    
    var body: some View {
        GeometryReader {
            geom in
            let keypad = Orientation(geom.size) == .portrait ? layout.portrait : layout.landscape
            
            VStack {
                ForEach(0..<keypad.endIndex, id: \.self) { row in
                    let keypadRow = keypad[row]
                    
                    HStack {
                        ForEach(0..<keypad.endIndex, id: \.self) { column in
                            let item = keypadRow[column]
                            
                            KeyView(key: item)
                                .simultaneousGesture(
                                TapGesture()
                                    .onEnded({ print(item.symbolStyle.symbol) }))
                        }
                    }
                }
            }
        }
    }
}

struct KeyView: View {
    var key: CalcKey
    
    var body: some View {
        ZStack {
            let shape = RoundedRectangle(cornerRadius: 8)
            shape.fill(key.color.opacity(0.7))
            switch key.symbolStyle {
            case .text(let text, let scale):
                Text(text)
                    .font(.title)
                    .fontWeight(.semibold)
                    .multilineTextAlignment(.trailing)
                    .scaleEffect(scale)
            case .image(let image, let scale):
                Image(systemName: image)
                    .scaleEffect(scale)
            }
            
        }
    }
}

struct CalcKey {
    let symbolStyle: Style
    let color: Color
    let layouts: (portrait: Layout, landscape: Layout)
    
    init(_ symbol: String, _ portrait: (row: Int, column: Int), _ landscape: (row: Int, column: Int), scale: Double? = nil, _ color: Color? = nil, _ isImage: Bool = false) {
        self.symbolStyle = isImage ? Style.image(symbol, scale ?? 2.5) : Style.text(symbol, scale ?? 1.2)
        self.color = color ?? .cyan
        self.layouts = (
            Layout.portrait(row: portrait.row, column: portrait.column),
            Layout.landscape(row: landscape.row, column: landscape.column)
        )
    }
    
    enum Style {
        case text(String, Double = 1)
        case image(String, Double = 2.5)
        
        var symbol: String {
            switch self {
            case .image(let symbol, _): fallthrough
            case .text(let symbol, _): return symbol
            }
        }
        
        var scale: Double {
            switch self {
            case .image(_, let scale): fallthrough
            case .text(_, let scale): return scale
            }
        }
    }
    
    enum Layout {
        case portrait(row: Int, column: Int)
        case landscape(row: Int, column: Int)
        
        var row: Int {
            switch self {
            case .portrait(let row, _): fallthrough
            case .landscape(let row, _): return row
            }
        }
        
        var column: Int {
            switch self {
            case .portrait(let column, _): fallthrough
            case .landscape(let column, _): return column
            }
        }
    }
}

enum Orientation {
    case portrait
    case landscape
    
    init(_ size: CGSize) { self = (size.width > size.height) ? .landscape : .portrait }
    var isPortait: Bool { self == .portrait }
    var isLandscape: Bool { self == .landscape }
}

extension Set where Element == CalcKey {
    static let rowPredicate: (CalcKey, CalcKey, Orientation) -> Bool = {
        switch $2 {
        case .portrait:
            return $0.layouts.portrait.row < $1.layouts.portrait.row
        case .landscape:
            return $0.layouts.landscape.row < $1.layouts.landscape.row
        }
    }
    
    static let columnPredicate: (CalcKey, CalcKey, Orientation) -> Bool = {
        switch $2 {
        case .portrait:
            return $0.layouts.portrait.column < $1.layouts.portrait.column
        case .landscape:
            return $0.layouts.landscape.column < $1.layouts.landscape.column
        }
    }
    
    func columnRange(for orientation: Orientation) -> ClosedRange<Int> {
        let minKey = self.min(by: { Self.columnPredicate($0, $1, orientation) })!
        let maxKey = self.min(by: { Self.columnPredicate($0, $1, orientation) })!
        
        switch orientation {
        case .portrait:
            return minKey.layouts.portrait.column...maxKey.layouts.portrait.column
        case .landscape:
            return minKey.layouts.landscape.column...maxKey.layouts.landscape.column
        }
    }
    
    func rowRange(for orientation: Orientation) -> ClosedRange<Int> {
        let minKey = self.min(by: { Self.rowPredicate($0, $1, orientation) })!
        let maxKey = self.min(by: { Self.rowPredicate($0, $1, orientation) })!
        
        switch orientation {
        case .portrait:
            return minKey.layouts.portrait.row...maxKey.layouts.portrait.row
        case .landscape:
            return minKey.layouts.landscape.row...maxKey.layouts.landscape.row
        }
    }
    
    func keys(for orientation: Orientation) -> [[CalcKey]] {
        let keys = self.sorted { Self.rowPredicate($0, $1, orientation) }
        
        switch orientation {
        case .portrait:
            return rowRange(for: orientation)
                .map { row in keys.filter { key in
                    key.layouts.portrait.row == row }.sorted {
                        Self.columnPredicate($0, $1, orientation)
                    }
                }
        case .landscape:
            return rowRange(for: orientation)
                .map { row in keys.filter { key in
                    key.layouts.landscape.row == row }.sorted {
                        Self.columnPredicate($0, $1, orientation)
                    }
                }
        }
    }
}

extension CalcKey: Hashable, CustomStringConvertible {
    static func == (lhs: CalcKey, rhs: CalcKey) -> Bool {lhs.symbolStyle.symbol == rhs.symbolStyle.symbol }
    func hash(into hasher: inout Hasher) { hasher.combine(symbolStyle.symbol) }
    var description: String { symbolStyle.symbol }
}

#Preview {
    CalcView()
}
