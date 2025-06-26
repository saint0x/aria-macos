import SwiftUI

struct TestGlassmorphicView: View {
    var body: some View {
        VStack {
            Text("Glassmorphic Test")
                .font(.largeTitle)
                .padding()
            
            VStack {
                Text("This is a glassmorphic container")
                    .padding()
            }
            .frame(width: 300, height: 100)
            .background(
                RoundedRectangle(cornerRadius: 22)
                    .fill(Color.white.opacity(0.3))
                    .background(
                        VisualEffectBlur(
                            material: .hudWindow,
                            blendingMode: .behindWindow,
                            state: .active
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 22))
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 22)
                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.05), radius: 25, x: 0, y: 20)
            .shadow(color: Color.black.opacity(0.04), radius: 10, x: 0, y: 8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.gray.opacity(0.1))
    }
}