import SwiftUI
import UniformTypeIdentifiers

/// What the picker is choosing artwork for.
struct CoverTarget: Identifiable {
    let key: String
    let title: String
    let kind: GameArt.Kind
    var id: String { key + "-\(kind)" }
}

/// Google Images opens in the browser; the image comes back by drag, paste or file.
struct CoverPicker: View {
    let target: CoverTarget

    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var chosen = ChosenArt.shared
    @State private var preview: CGImage?
    @State private var problem: String?
    @State private var loading = false
    @State private var dropTargeted = false
    @State private var choosingFile = false

    private var isCover: Bool { target.kind == .cover }
    private var previewSize: CGSize { isCover ? CGSize(width: 200, height: 300) : CGSize(width: 480, height: 165) }
    private var shape: RoundedRectangle { RoundedRectangle(cornerRadius: isCover ? 16 : 22, style: .continuous) }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(isCover ? L.t("Cover for \(target.title)", "Jaquette de \(target.title)", "Sampul untuk \(target.title)")
                         : L.t("Banner for \(target.title)", "Bannière de \(target.title)", "Banner untuk \(target.title)"))
                .font(Theme.title(22))
                .foregroundStyle(Theme.text)

            Button {
                if let url = ArtIntake.googleImagesURL(title: target.title, kind: target.kind) {
                    NSWorkspace.shared.open(url)
                }
            } label: {
                Label(L.t("Search Google Images", "Chercher sur Google Images", "Cari di Google Images"),
                      systemImage: "magnifyingglass")
            }
            .buttonStyle(.borderedProminent)

            Text(L.t("Open the image you like in full size, then drag it here, or copy it and paste.",
                     "Ouvre l'image choisie en grand, puis glisse-la ici, ou copie-la et colle-la.",
                     "Buka gambar yang kamu suka dalam ukuran penuh, lalu tarik ke sini, atau salin dan tempel."))
                .font(.callout)
                .foregroundStyle(Theme.muted)

            dropArea
                .frame(maxWidth: .infinity)

            if let problem {
                Text(problem).font(.callout).foregroundStyle(.red)
            }

            HStack {
                Button {
                    take { ArtIntake.candidatesFromPasteboard() }
                } label: {
                    Label(L.t("Paste", "Coller", "Tempel"), systemImage: "doc.on.clipboard")
                }
                .keyboardShortcut("v", modifiers: .command)
                Button {
                    choosingFile = true
                } label: {
                    Label(L.t("Choose file…", "Choisir un fichier…", "Pilih file…"), systemImage: "folder")
                }
            }

            Divider()

            HStack {
                if chosen.has(target.key, target.kind) {
                    Button(L.t("Use default artwork", "Illustration par défaut", "Pakai gambar bawaan"), role: .destructive) {
                        chosen.remove(target.key, target.kind)
                        dismiss()
                    }
                }
                Spacer()
                Button(L.t("Cancel", "Annuler", "Batal")) { dismiss() }
                    .keyboardShortcut(.cancelAction)
                Button(L.t("Apply", "Appliquer", "Terapkan")) { apply() }
                    .keyboardShortcut(.defaultAction)
                    .disabled(preview == nil || loading)
            }
        }
        .padding(24)
        .frame(width: 560)
        .background(Theme.background)
        .tint(Theme.accent)
        .fileImporter(isPresented: $choosingFile, allowedContentTypes: [.image]) { result in
            if case .success(let url) = result {
                take { [.file(url)] }
            }
        }
    }

    private var dropArea: some View {
        ZStack {
            shape.fill(Theme.card)
            if let preview {
                Image(decorative: preview, scale: 1)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: previewSize.width, height: previewSize.height)
            } else {
                VStack(spacing: 8) {
                    Image(systemName: "photo.on.rectangle.angled").font(.system(size: 28))
                    Text(L.t("Drop an image here", "Dépose une image ici", "Tarik gambar ke sini"))
                        .font(.callout)
                }
                .foregroundStyle(Theme.muted)
            }
            if loading {
                ProgressView()
            }
        }
        .frame(width: previewSize.width, height: previewSize.height)
        .clipShape(shape)
        .overlay {
            shape.strokeBorder(dropTargeted ? Theme.accent : Theme.muted.opacity(0.4),
                               style: StrokeStyle(lineWidth: 2, dash: preview == nil ? [6, 4] : []))
        }
        .onDrop(of: ArtIntake.dropTypes, isTargeted: $dropTargeted) { providers in
            take { await ArtIntake.candidates(from: providers) }
            return true
        }
    }

    private func take(_ gather: @escaping () async -> [ArtIntake.Candidate]) {
        loading = true
        problem = nil
        Task {
            let result = await ArtIntake.image(from: await gather())
            loading = false
            switch result {
            case .success(let image): preview = image
            case .failure(let failure): problem = failure.message
            }
        }
    }

    private func apply() {
        guard let preview else { return }
        do {
            try chosen.save(preview, key: target.key, kind: target.kind)
            dismiss()
        } catch {
            problem = error.localizedDescription
        }
    }
}
