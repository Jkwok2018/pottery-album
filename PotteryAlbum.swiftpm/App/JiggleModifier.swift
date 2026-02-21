import SwiftUI

struct JiggleModifier: ViewModifier {
    let isJiggling: Bool
    
    @State private var rotation: Double = 0.0
    
    func body(content: Content) -> some View {
        content
            .rotationEffect(.degrees(isJiggling ? rotation : 0))
            .animation(isJiggling ? 
                Animation.linear(duration: 0.15)
                    .repeatForever(autoreverses: true) : 
                .default, 
                value: rotation
            )
            .onAppear {
                if isJiggling {
                    rotation = -1.5
                    withAnimation {
                        rotation = 1.5
                    }
                }
            }
            .onChange(of: isJiggling) { oldValue, newValue in
                if newValue {
                    rotation = -1.5
                    withAnimation {
                        rotation = 1.5
                    }
                } else {
                    rotation = 0
                }
            }
    }
}

extension View {
    func jiggle(isActive: Bool) -> some View {
        self.modifier(JiggleModifier(isJiggling: isActive))
    }
}
