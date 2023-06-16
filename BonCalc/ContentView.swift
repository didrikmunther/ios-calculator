//
//  ContentView.swift
//  BonCalc
//
//  Created by Didrik Munther on 2023-06-12.
//

import SwiftUI

extension Double {
    func removeZerosFromEnd() -> String {
        let formatter = NumberFormatter()
        let number = NSNumber(value: self)
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 16
        
        return String(formatter.string(from: number) ?? "")
    }
}

struct CalcButtonStyle: ButtonStyle {
    typealias AspectRatio = (CGFloat?, ContentMode)
    typealias Frame = (CGFloat?, CGFloat?)
    
    let background: Color
    let foregroundColor: Color
    let clipShape: AnyShape
    let aspectRatio: Optional<AspectRatio>
    let frame: Frame
    
    init(background: Color = .black.opacity(0.5), foregroundColor: Color = .white, clipShape: AnyShape = AnyShape(Circle()), aspectRatio: Optional<AspectRatio> = .some((1, contentMode: .fit)), frame: Frame = (.infinity, .infinity)) {
        self.background = background
        self.foregroundColor = foregroundColor
        self.clipShape = clipShape
        self.aspectRatio = aspectRatio
        self.frame = frame
    }
    
    func makeBody(configuration: Configuration) -> some View {
        let view = configuration.label
            .frame(maxWidth: frame.0, maxHeight: frame.1)
            .padding()
            .background(background)
            .foregroundColor(foregroundColor)
            .clipShape(clipShape)
            .scaleEffect(configuration.isPressed ? 1.2 : 1)
            .animation(.easeOut(duration: 0.2), value: configuration.isPressed)
        
        if let (first, second) = aspectRatio {
            return AnyView(view.aspectRatio(first, contentMode: second))
        }
        
        return AnyView(view)
    }
}

extension ButtonStyle where Self == CalcButtonStyle {
    static var `operator`: Self { CalcButtonStyle(
        background: .orange,
        foregroundColor: .white)
    }
    
    static var topBar: Self { CalcButtonStyle(
        background: .black.opacity(0.3),
        foregroundColor: .white)
    }
    
    static var zeroButton: Self { CalcButtonStyle(
        background: .black.opacity(0.5),
        foregroundColor: .white,
        clipShape: AnyShape(RoundedRectangle(cornerRadius: 100.0)),
        aspectRatio: Optional.none,
        frame: (.infinity, nil))
    }
}

struct CalcButton<Content: View>: View {
    var buttonStyle: some ButtonStyle = CalcButtonStyle();
    var action: () -> Void
    @ViewBuilder var content: Content
    
    var body: some View {
        Button(action: action) {
            content
        }
        .buttonStyle(buttonStyle)
    }
}

extension CalcButton {
    public func withButtonStyle<S>(_ style: S) -> some View where S : ButtonStyle {
        Button(action: action) {
            content
        }
        .buttonStyle(style)
    }
}

struct CalcButtonText: View {
    var text: String
    
    init(_ text: String) {
        self.text = text
    }
    
    var body: some View {
        Text(text).font(.system(size: 36))
    }
}

struct ContentView: View {
    enum Operator {
        case Add
        case Subtract
        case Multiply
        case Divide
        case Equals
    }
    
    @State var input: Double = 0
    @State var buf: Double = 0
    @State var op: Optional<Operator> = Optional.none
    @State var isDecimal: Bool = false
    @State var decimalExp: Double = 1.0 / 10.0;
    
    func addNumber(number: Int) {
        if(isDecimal) {
            input += Double(number) * decimalExp
            decimalExp /= 10
        } else {
            input = input * 10 + Double(number);
        }
    }
    
    func reset() {
        input = 0
        buf = 0
        isDecimal = false
        decimalExp = 1.0 / 10.0
        op = Optional.none
    }
    
    func changeSign() {
        input *= -1
    }
    
    func setDecimal() {
        isDecimal = true
    }
    
    func percentage() {
        input /= 100.0
    }
    
    func doArithmetic() {
        if let op = op {
            switch op {
            case .Add:
                buf += input
            case .Subtract:
                buf -= input
            case .Multiply:
                buf *= input
            case .Divide:
                buf /= input
            case .Equals:
                buf = input
            }
        } else {
            buf = input
        }
        
        isDecimal = false
        decimalExp = 1.0 / 10.0
    }
    
    func binaryOperation(_ newOperator: Operator) {
        doArithmetic()
        op = Optional.some(newOperator)
        
        if(newOperator == Operator.Equals) {
            input = buf
            buf = 0
        } else {
            input = 0
        }
    }
    
    func getInputString() -> String {
        var res = input.removeZerosFromEnd()
        
        // We are in decimal mode but no decimal has been added,
        // display a decimal point to show that the next input is decimal.
        if(isDecimal && decimalExp > 1.0 / 100.0) {
            res += "."
        }
        
        return res
    }
    
    var body: some View {
        ZStack {
            Rectangle()
                .fill(Gradient(colors: [.indigo, .purple]))
                .ignoresSafeArea()
            VStack(alignment: .trailing) {
                ScrollView(.horizontal) {
                    VStack {
                        HStack{
                            Spacer()
                            Text(getInputString())
                                .font(.system(size: 96))
                                .foregroundColor(.white)
                                .padding()
                                .frame(alignment: .trailing)
                        }
                    }
                }
                HStack {
                    VStack {
                        HStack {
                            CalcButton(action: reset) {
                                CalcButtonText("AC")
                            }
                            .withButtonStyle(.topBar)
                            CalcButton {
                                changeSign()
                            } content: {
                                Image(systemName: "plus.forwardslash.minus").font(.system(size: 36))
                            }
                            .withButtonStyle(.topBar)
                            CalcButton {
                                percentage()
                            } content: {
                                Image(systemName: "percent").font(.system(size: 36))
                            }
                            .withButtonStyle(.topBar)
                            CalcButton {
                                binaryOperation(Operator.Divide)
                            } content: {
                                Image(systemName: "divide").font(.system(size: 36))
                            }
                            .withButtonStyle(.operator)
                        }
                        HStack {
                            ForEach([7, 8, 9], id: \.self) { num in
                                CalcButton {
                                    addNumber(number: num)
                                } content: {
                                    CalcButtonText("\(num)")
                                }
                            }
                            CalcButton {
                                binaryOperation(.Multiply)
                            } content: {
                                Image(systemName: "multiply").font(.system(size: 36))
                            }
                            .withButtonStyle(.operator)
                        }
                        HStack {
                            ForEach([4, 5, 6], id: \.self) { num in
                                CalcButton {
                                    addNumber(number: num)
                                } content: {
                                    CalcButtonText("\(num)")
                                }
                            }
                            CalcButton {
                                binaryOperation(.Subtract)
                            } content: {
                                Image(systemName: "minus").font(.system(size: 36))
                            }
                            .withButtonStyle(.operator)
                        }
                        HStack {
                            ForEach([1, 2, 3], id: \.self) { num in
                                CalcButton {
                                    addNumber(number: num)
                                } content: {
                                    CalcButtonText("\(num)")
                                }
                            }
                            CalcButton {
                                binaryOperation(Operator.Add)
                            } content: {
                                Image(systemName: "plus").font(.system(size: 36))
                            }
                            .withButtonStyle(.operator)
                        }
                        HStack {
                            CalcButton {
                                addNumber(number: 0)
                            } content: {
                                CalcButtonText("0")
                            }
                            .withButtonStyle(.zeroButton)
                            HStack {
                                CalcButton {
                                    setDecimal()
                                } content: {
                                    CalcButtonText(",")
                                }
                                CalcButton {
                                    binaryOperation(Operator.Equals)
                                } content: {
                                    Image(systemName: "equal").font(.system(size: 36))
                                }
                                .withButtonStyle(.operator)
                            }
                        }
                    }
                }
                .padding()
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
