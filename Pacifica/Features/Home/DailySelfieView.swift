import PhotosUI
import SwiftUI
import UIKit

struct DailySelfieView: View {
    @ObservedObject var viewModel: DailySelfieViewModel

    @State private var selectedPhoto: PhotosPickerItem?
    @State private var showsCamera = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Selfie check-in")
                .font(.title3.weight(.semibold))

            if let image = viewModel.image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(height: 180)
                    .frame(maxWidth: .infinity)
                    .clipShape(RoundedRectangle(cornerRadius: 18))
            } else {
                Text(viewModel.statusText)
                    .foregroundStyle(Theme.textSecondary)
            }

            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .font(.footnote)
                    .foregroundStyle(.red)
            }

            if viewModel.isLoading {
                ProgressView()
            } else if viewModel.isEligible {
                HStack(spacing: 12) {
                    PhotosPicker(selection: $selectedPhoto, matching: .images) {
                        Label("Choose photo", systemImage: "photo")
                    }
                    .buttonStyle(.bordered)

                    Button {
                        showsCamera = true
                    } label: {
                        Label("Take selfie", systemImage: "camera")
                    }
                    .buttonStyle(.borderedProminent)
                }
                .disabled(viewModel.isSaving)
            }

            if viewModel.selfie != nil {
                Button("Remove selfie") {
                    Task { await viewModel.remove() }
                }
                .buttonStyle(.bordered)
                .disabled(viewModel.isSaving)
            }
        }
        .padding(20)
        .glassEffect(.regular, in: .rect(cornerRadius: Theme.cardRadius))
        .task {
            await viewModel.load()
        }
        .onChange(of: selectedPhoto) { _, item in
            guard let item else { return }
            Task {
                await importPhoto(item)
                selectedPhoto = nil
            }
        }
        .sheet(isPresented: $showsCamera) {
            CameraPicker { image in
                Task { await viewModel.save(image: image) }
            }
            .ignoresSafeArea()
        }
    }

    private func importPhoto(_ item: PhotosPickerItem) async {
        do {
            guard let data = try await item.loadTransferable(type: Data.self),
                  let image = UIImage(data: data)
            else {
                return
            }

            _ = await viewModel.save(image: image)
        } catch {
            viewModel.errorMessage = error.localizedDescription
        }
    }
}

private struct CameraPicker: UIViewControllerRepresentable {
    let onImage: (UIImage) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onImage: onImage)
    }

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = UIImagePickerController.isSourceTypeAvailable(.camera) ? .camera : .photoLibrary
        picker.allowsEditing = false
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    final class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let onImage: (UIImage) -> Void

        init(onImage: @escaping (UIImage) -> Void) {
            self.onImage = onImage
        }

        func imagePickerController(
            _ picker: UIImagePickerController,
            didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
        ) {
            if let image = info[.originalImage] as? UIImage {
                onImage(image)
            }
            picker.dismiss(animated: true)
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true)
        }
    }
}

#Preview {
    DailySelfieView(viewModel: DailySelfieViewModel(userID: UUID()))
        .padding()
}
