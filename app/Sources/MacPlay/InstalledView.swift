import SwiftUI

struct InstalledDetail: View {
    let game: InstalledGame
    let known: GameEntry?
    let stats: ReportStats?
    let profile: HardwareProfile?
    let onSubmitted: (ReportStats?) -> Void

    @StateObject private var session = GameSession()
    @StateObject private var runner = ActionRunner()
    @State private var chosenBackend = Engine.activeBackend
    @State private var rating = 0
    @State private var comment = ""
    @State private var submitting = false
    @State private var feedback: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                ArtImage(appid: Int(game.appid), kind: .banner, title: "", key: PlayTime.steamKey(game.appid))
                    .frame(height: 220)
                    .frame(maxWidth: .infinity)
                    .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))

                // Title + play
                HStack(alignment: .firstTextBaseline) {
                    Text(game.name).font(Theme.title(28))
                    Spacer()
                    Button {
                        session.play(game)
                    } label: {
                        Label(L.t("Play", "Jouer", "Main"), systemImage: "play.fill")
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .disabled(session.phase == .launching || session.phase == .waitingForGame
                              || session.phase == .running || runner.running)
                }

                sessionStatus

                if let s = stats {
                    HStack(spacing: 4) {
                        Image(systemName: "star.fill").foregroundStyle(.yellow)
                        Text(String(format: "%.1f", s.avg_rating)).font(.headline)
                        Text(L.t("community average (\(s.report_count) reports)",
                                 "moyenne communauté (\(s.report_count) avis)",
                                 "rata-rata komunitas (\(s.report_count) laporan)"))
                            .foregroundStyle(.secondary)
                    }
                    .font(.callout)
                }

                // Model-specific expectation
                if let known, let est = Perf.estimate(profile: profile, game: known) {
                    Label {
                        Text(L.t("On your \(profile?.chip ?? "Mac") (\(profile?.gpuCores ?? 0) GPU cores): ~\(est.fpsRange) fps expected — \(est.hint). Estimate, not a promise.",
                                 "Sur ta \(profile?.chip ?? "machine") (\(profile?.gpuCores ?? 0) cœurs GPU) : ~\(est.fpsRange) fps attendus — \(est.hint). Estimation, pas une promesse.",
                                 "Di \(profile?.chip ?? "Mac") kamu (\(profile?.gpuCores ?? 0) core GPU): perkiraan ~\(est.fpsRange) fps — \(est.hint). Perkiraan, bukan janji."))
                    } icon: {
                        Image(systemName: "gauge.with.dots.needle.67percent")
                    }
                    .font(.callout)
                    .foregroundStyle(.secondary)
                }

                ArtworkBox(key: PlayTime.steamKey(game.appid), title: game.name, appid: Int(game.appid))

                // Engine choice — the escape hatch for unlisted games,
                // and the fix path after a crash
                GroupBox(L.t("Graphics engine", "Moteur graphique", "Engine grafis")) {
                    VStack(alignment: .leading, spacing: 10) {
                        if let known, !known.backend.isEmpty, known.backend != "none" {
                            Text(L.t("Recommended: \(known.backend.uppercased()). Change it only if you hit problems.",
                                     "Recommandé : \(known.backend.uppercased()). Change seulement en cas de problème.",
                                     "Disarankan: \(known.backend.uppercased()). Ganti hanya kalau ada masalah."))
                                .font(.callout)
                                .foregroundStyle(.secondary)
                        } else if known == nil {
                            Text(L.t("This game is not in our database yet. Pick an engine, test it, and if it works your rating will save it for everyone.",
                                     "Ce jeu n'est pas encore dans notre base. Choisis un moteur, teste, et si ça marche ta note l'enregistrera pour tout le monde.",
                                     "Game ini belum ada di database kami. Pilih engine, coba, dan kalau berhasil, rating-mu akan menyimpannya untuk semua orang."))
                                .font(.callout)
                                .foregroundStyle(.secondary)
                        } else {
                            Text(L.t("No engine recommendation for this game yet. Pick one, test it, and your rating will help others.",
                                     "Pas encore de moteur recommandé pour ce jeu. Choisis-en un, teste, et ta note aidera les autres.",
                                     "Belum ada rekomendasi engine untuk game ini. Pilih satu, coba, dan rating-mu akan membantu yang lain."))
                                .font(.callout)
                                .foregroundStyle(.secondary)
                        }
                        Picker("", selection: $chosenBackend) {
                            ForEach(Engine.backendChoices(for: Engine.wrapperPath), id: \.id) { c in
                                Text(c.label).tag(c.id)
                            }
                        }
                        .pickerStyle(.segmented)
                        .labelsHidden()

                        HStack {
                            Button(L.t("Apply and restart Steam", "Appliquer et relancer Steam", "Terapkan dan mulai ulang Steam")) {
                                let backend = chosenBackend
                                runner.start(L.t("Switching to \(backend.uppercased())",
                                                 "Passage sur \(backend.uppercased())",
                                                 "Beralih ke \(backend.uppercased())")) { emit, doneCb in
                                    do {
                                        let applied = try Engine.applyBackend(backend)
                                        emit(L.t("Backend set to \(applied).", "Backend réglé sur \(applied).", "Backend diatur ke \(applied)."))
                                        Engine.restart(emit: emit, done: doneCb)
                                    } catch {
                                        emit(error.localizedDescription)
                                        doneCb(1)
                                    }
                                }
                            }
                            .disabled(runner.running || chosenBackend == Engine.activeBackend)
                            Text(L.t("Currently active: \(Engine.activeBackend.uppercased())",
                                     "Actif actuellement : \(Engine.activeBackend.uppercased())",
                                     "Aktif sekarang: \(Engine.activeBackend.uppercased())"))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(4)
                }

                ratingBox

                if !runner.log.isEmpty {
                    LogPanel(runner: runner)
                }
            }
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: 720, alignment: .leading)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(20)
        }
    }

    @ViewBuilder
    private var sessionStatus: some View {
        switch session.phase {
        case .idle:
            if let line = session.statusLine {
                Label(line, systemImage: "info.circle").font(.callout).foregroundStyle(.secondary)
            }
        case .launching, .waitingForGame:
            HStack(spacing: 8) {
                ProgressView().controlSize(.small)
                Text(session.statusLine ?? L.t("Launching…", "Lancement…", "Menjalankan…"))
                    .font(.callout).foregroundStyle(.secondary)
            }
        case .running:
            Label(L.t("Game is running — have fun! I'm keeping an eye on it.",
                      "Le jeu tourne — amuse-toi ! Je garde un œil dessus.",
                      "Game sedang berjalan — selamat bermain! Aku pantau terus."),
                  systemImage: "checkmark.circle.fill")
                .font(.callout).foregroundStyle(.green)
        case .endedOK:
            VStack(alignment: .leading, spacing: 6) {
                Label(L.t("Session over (\(session.ranForSeconds / 60) min). Did it run well?",
                          "Session terminée (\(session.ranForSeconds / 60) min). Ça a bien tourné ?",
                          "Sesi selesai (\(session.ranForSeconds / 60) menit). Lancar jalannya?"),
                      systemImage: "flag.checkered")
                    .font(.callout)
                Text(L.t("Rate it below — your rating records the engine that worked for the community.",
                         "Note-le ci-dessous — ta note enregistre le moteur qui marche pour la communauté.",
                         "Beri rating di bawah — rating-mu mencatat engine yang berhasil untuk komunitas."))
                    .font(.callout).foregroundStyle(.secondary)
            }
            .padding(10)
            .background(.green.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
        case .crashed:
            VStack(alignment: .leading, spacing: 6) {
                Label(L.t("The game quit after only \(session.ranForSeconds)s — probably a crash.",
                          "Le jeu s'est fermé après seulement \(session.ranForSeconds)s — probablement un crash.",
                          "Game tertutup setelah cuma \(session.ranForSeconds) detik — mungkin crash."),
                      systemImage: "exclamationmark.triangle.fill")
                    .font(.callout).foregroundStyle(.orange)
                Text(crashSuggestion)
                    .font(.callout).foregroundStyle(.secondary)
            }
            .padding(10)
            .background(.orange.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
        case .failed:
            Label(session.statusLine ?? L.t("Launch failed.", "Le lancement a échoué.", "Gagal dijalankan."),
                  systemImage: "xmark.circle")
                .font(.callout).foregroundStyle(.red)
        }
    }

    private var crashSuggestion: String {
        let current = Engine.activeBackend
        let next = current == "d3dmetal" ? "DXVK" : current == "dxvk" ? "DXMT" : "D3DMetal"
        return L.t("Try another engine above (currently \(current.uppercased()) — try \(next)), apply, then hit Play again. If it keeps crashing, rate it 1 star so others know.",
                   "Essaie un autre moteur ci-dessus (actuellement \(current.uppercased()) — tente \(next)), applique, puis relance. Si ça continue de planter, mets 1 étoile pour prévenir les autres.",
                   "Coba engine lain di atas (sekarang \(current.uppercased()) — coba \(next)), terapkan, lalu tekan Main lagi. Kalau masih crash, beri 1 bintang supaya yang lain tahu.")
    }

    private var ratingBox: some View {
        GroupBox(L.t("How does it run on your Mac?", "Ça tourne comment sur ton Mac ?", "Bagaimana jalannya di Mac kamu?")) {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 6) {
                    ForEach(1...5, id: \.self) { star in
                        Button {
                            rating = star
                        } label: {
                            Image(systemName: star <= rating ? "star.fill" : "star")
                                .font(.title2)
                                .foregroundStyle(star <= rating ? .yellow : .secondary)
                        }
                        .buttonStyle(.plain)
                    }
                    if rating > 0 {
                        Text(ratingLabel(rating)).font(.callout).foregroundStyle(.secondary)
                    }
                }

                TextField(L.t("Optional comment (settings used, fps, issues…)",
                              "Commentaire optionnel (réglages, fps, soucis…)",
                              "Komentar opsional (pengaturan, fps, masalah…)"),
                          text: $comment, axis: .vertical)
                    .lineLimit(2...4)
                    .textFieldStyle(.roundedBorder)

                HStack {
                    Button(L.t("Send my rating", "Envoyer mon avis", "Kirim rating-ku")) { submit() }
                        .buttonStyle(.borderedProminent)
                        .disabled(rating == 0 || submitting)
                    if submitting { ProgressView().controlSize(.small) }
                    if let feedback {
                        Text(feedback).font(.callout).foregroundStyle(.secondary)
                    }
                }

                Text(L.t("Sent anonymously with your hardware profile and the engine used (\(Engine.activeBackend.uppercased())), so ratings are comparable.",
                         "Envoyé anonymement avec ton profil matériel et le moteur utilisé (\(Engine.activeBackend.uppercased())), pour que les notes soient comparables.",
                         "Dikirim secara anonim bersama profil hardware-mu dan engine yang dipakai (\(Engine.activeBackend.uppercased())), supaya rating bisa dibandingkan."))
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(4)
        }
    }

    private func ratingLabel(_ r: Int) -> String {
        switch r {
        case 1: return L.t("Unplayable", "Injouable", "Tidak bisa dimainkan")
        case 2: return L.t("Rough", "Pénible", "Kurang mulus")
        case 3: return L.t("Playable", "Jouable", "Bisa dimainkan")
        case 4: return L.t("Runs well", "Tourne bien", "Jalan dengan baik")
        default: return L.t("Flawless", "Impeccable", "Mulus tanpa cela")
        }
    }

    private func submit() {
        submitting = true
        feedback = nil
        let backend = Engine.activeBackend
        Task {
            do {
                let newStats = try await Hub.submitReport(game: game, rating: rating, comment: comment,
                                                          profile: profile, backend: backend)
                feedback = L.t("Thanks! Your rating is recorded.", "Merci ! Ton avis est enregistré.", "Terima kasih! Rating-mu sudah tercatat.")
                onSubmitted(newStats)
            } catch {
                feedback = error.localizedDescription
            }
            submitting = false
        }
    }
}
