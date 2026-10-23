import SwiftUI
import CoreImage.CIFilterBuiltins

struct QRCodeView: View {
    @Environment(\.dismiss) private var dismiss

    // Placeholder until real accounts exist.
    private let name = PlaceholderProfile.name
    private let handle = PlaceholderProfile.handle

    private var payload: String { "pacifica://pay/\(handle.dropFirst())" }

    var body: some View {
        ZStack {
            AppBackground()

            VStack(spacing: 28) {
                header

                VStack(spacing: 24) {
                    QRImage(text: payload)
                        .frame(maxWidth: .infinity)
                        .aspectRatio(1, contentMode: .fit)
                        .padding(16)
                        .background(RoundedRectangle(cornerRadius: 20).fill(Color.white))

                    VStack(spacing: 4) {
                        Text(name)
                            .font(.title2.weight(.bold))
                        Text(handle)
                            .font(.title3)
                            .foregroundStyle(Theme.textSecondary)
                    }
                }
                .padding(28)
                .glassEffect(.regular, in: .rect(cornerRadius: Theme.cardRadius))

                Text("Scan to pay me")
                    .font(.headline)
                    .foregroundStyle(Theme.textSecondary)

                Spacer()

                ShareLink(item: payload) {
                    Label("Share my code", systemImage: "square.and.arrow.up")
                        .font(.title3.weight(.semibold))
                        .frame(maxWidth: .infinity, minHeight: 44)
                }
                .buttonStyle(.glass)
                .buttonBorderShape(.capsule)
                .controlSize(.extraLarge)
                .foregroundStyle(Theme.text)
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 16)
        }
    }

    private var header: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.title3.weight(.semibold))
                    .frame(width: 52, height: 52)
                    .glassEffect(.regular.interactive(), in: .circle)
            }
            .foregroundStyle(Theme.text)
            Spacer()
            Text("Pay with QR")
                .font(.headline)
            Spacer()
            Color.clear.frame(width: 52, height: 52)
        }
    }
}

private struct QRImage: View {
    let text: String

    var body: some View {
        if let image = makeImage() {
            Image(uiImage: image)
                .interpolation(.none)
                .resizable()
                .scaledToFit()
        }
    }

    private func makeImage() -> UIImage? {
        let filter = CIFilter.qrCodeGenerator()
        filter.message = Data(text.utf8)
        filter.correctionLevel = "M"
        guard let output = filter.outputImage else { return nil }
        let scaled = output.transformed(by: CGAffineTransform(scaleX: 12, y: 12))
        guard let cg = CIContext().createCGImage(scaled, from: scaled.extent) else { return nil }
        return UIImage(cgImage: cg)
    }
}

#Preview {
    QRCodeView()
}
