import SwiftUI

/// The Activity tab: an ocean where each friend is a fish. The deeper your fish, the more of your own
/// budget you've used. Shallowest is first. Only percentages are shown, never dollar amounts.
struct ActivityView: View {
    @State private var model = ReefViewModel()

    var body: some View {
        VStack(spacing: 0) {
            SkyHeader(model: model)
            OceanField(model: model)
        }
        .background(alignment: .top) {
            SkyGradient()
                .frame(height: 420)
                .ignoresSafeArea(edges: .top)
        }
    }
}

// MARK: - Sky

private struct SkyGradient: View {
    var body: some View {
        LinearGradient(
            colors: [
                Color(light: .white, dark: Color(hex: 0x10201F)),
                Color(light: Color(hex: 0xD9F3F0), dark: Color(hex: 0x0B3A3D)),
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }
}

private struct SkyHeader: View {
    @Bindable var model: ReefViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Activity")
                    .font(.largeTitle.bold())
                Text("Your reef · resets every Monday")
                    .font(.subheadline)
                    .foregroundStyle(Theme.textSecondary)
            }
            .padding(.horizontal, 20)

            CategoryChips(model: model)
            TopOfReefRow(model: model)
        }
        .foregroundStyle(Theme.text)
        .padding(.top, 8)
        .padding(.bottom, 22)
    }
}

private struct CategoryChips: View {
    @Bindable var model: ReefViewModel

    var body: some View {
        ScrollView(.horizontal) {
            GlassEffectContainer(spacing: 8) {
                HStack(spacing: 8) {
                    ForEach(ReefCategory.allCases) { category in
                        chip(category)
                    }
                }
                .padding(.horizontal, 20)
            }
        }
        .scrollIndicators(.hidden)
    }

    private func chip(_ category: ReefCategory) -> some View {
        let isSelected = model.category == category
        return Button {
            withAnimation(.spring(response: 0.9, dampingFraction: 0.78)) {
                model.category = category
            }
        } label: {
            Label(category.title, systemImage: category.systemImage)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(isSelected ? Color.white : Theme.text)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .glassEffect(isSelected ? .regular.tint(Theme.accent).interactive() : .regular.interactive(),
                             in: .capsule)
        }
        .buttonStyle(.plain)
        .sensoryFeedback(.selection, trigger: model.category)
    }
}

/// Podium of the ranking: shallowest first.
private struct TopOfReefRow: View {
    var model: ReefViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: "trophy.fill")
                    .foregroundStyle(Theme.coral)
                Text("Top of the reef")
                    .font(.headline)
            }
            .padding(.horizontal, 20)

            ScrollView(.horizontal) {
                HStack(alignment: .top, spacing: 14) {
                    ForEach(model.ranking) { ranked in
                        entry(ranked)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
            }
            .scrollIndicators(.hidden)
        }
    }

    private func entry(_ ranked: RankedFriend) -> some View {
        let isFirst = ranked.rank == 1
        return Button {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                model.selectedID = ranked.friend.id
            }
        } label: {
            VStack(spacing: 6) {
                Text(ranked.friend.initials)
                    .font(.system(size: isFirst ? 18 : 15, weight: .bold, design: .rounded))
                    .foregroundStyle(ranked.friend.isYou ? Color.white : Theme.text)
                    .frame(width: isFirst ? 62 : 52, height: isFirst ? 62 : 52)
                    .glassEffect(ranked.friend.isYou ? .regular.tint(Theme.coral) : .regular, in: .circle)
                    .overlay(alignment: .topTrailing) {
                        Text("\(ranked.rank)")
                            .font(.system(size: 11, weight: .heavy, design: .rounded))
                            .foregroundStyle(Color.white)
                            .frame(width: 20, height: 20)
                            .background(isFirst ? Theme.coral : Theme.charcoal, in: Circle())
                            .offset(x: 3, y: -3)
                            .zIndex(1)
                    }
                    .zIndex(1)
                Text(ranked.friend.isYou ? "You" : ranked.friend.name)
                    .font(.caption.weight(.semibold))
            }
            .foregroundStyle(Theme.text)
        }
        .buttonStyle(.plain)
        .transition(.scale.combined(with: .opacity))
    }
}

// MARK: - Ocean

private struct OceanField: View {
    var model: ReefViewModel

    private let swimPhases: [String: Double] = [
        "you": 0.0, "summer": 1.4, "raey": 2.6, "mario": 3.9, "alex": 5.1,
    ]

    /// Left and right swimming lanes; fish alternate between them from the surface down.
    private let laneX: [CGFloat] = [0.33, 0.72]
    /// Fish in the same lane never get closer than this vertically.
    private let minGap: CGFloat = 74
    private let youGap: CGFloat = 122

    private struct Placement {
        let x: CGFloat
        let y: CGFloat
        let facesRight: Bool
    }

    var body: some View {
        GeometryReader { geo in
            let topInset: CGFloat = 40
            let bottomReserve: CGFloat = 150
            let usableHeight = max(geo.size.height - topInset - bottomReserve, 1)
            let placements = layout(in: geo.size, top: topInset, usable: usableHeight)

            ZStack(alignment: .topLeading) {
                DepthGauge(top: topInset, height: usableHeight, width: geo.size.width)

                ForEach(model.friends) { friend in
                    if let place = placements[friend.id] {
                        fish(for: friend, place: place)
                    }
                }

                YourFishCard(model: model)
                    .padding(.horizontal, 16)
                    .frame(width: geo.size.width, height: geo.size.height, alignment: .bottom)
                    .padding(.bottom, 4)
            }
        }
        .background {
            OceanBackdrop()
                .ignoresSafeArea(edges: .bottom)
        }
    }

    /// Depth sets each fish's height. Lanes plus a minimum gap keep neighbours from overlapping.
    private func layout(in size: CGSize, top: CGFloat, usable: CGFloat) -> [String: Placement] {
        // Hidden fish hang at mid-depth so their real depth never leaks.
        let depths: [(friend: ReefFriend, depth: Double)] = model.friends
            .map { ($0, $0.depth(in: model.category) ?? 0.55) }
            .sorted { $0.depth < $1.depth }

        var lastY: [Int: (y: CGFloat, isYou: Bool)] = [:]
        var result: [String: Placement] = [:]
        let floorY = top + usable

        for (index, entry) in depths.enumerated() {
            let lane = index % 2
            var y = top + CGFloat(min(entry.depth, ReefViewModel.maxDepth) / ReefViewModel.maxDepth) * usable
            if let previous = lastY[lane] {
                // Your fish is bigger and carries a "you are here" tag, so it needs more room.
                let gap = (previous.isYou || entry.friend.isYou) ? youGap : minGap
                if y - previous.y < gap { y = previous.y + gap }
            }
            y = min(y, floorY + 20)
            lastY[lane] = (y, entry.friend.isYou)
            result[entry.friend.id] = Placement(x: size.width * laneX[lane], y: y, facesRight: lane == 0)
        }
        return result
    }

    @ViewBuilder
    private func fish(for friend: ReefFriend, place: Placement) -> some View {
        let depth = friend.depth(in: model.category)
        let isHidden = depth == nil
        let detail = isHidden ? "hidden" : "\(Int(((depth ?? 0) * 100).rounded()))%"
        let width: CGFloat = friend.isYou ? 150 : 100
        let isSelected = model.selectedID == friend.id

        Button {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                model.selectedID = friend.id
            }
        } label: {
            VStack(spacing: 8) {
                FishView(name: friend.name, detail: detail, width: width,
                         isYou: friend.isYou, isHidden: isHidden,
                         facesRight: place.facesRight, isSelected: isSelected,
                         phase: swimPhases[friend.id] ?? 0)
                if friend.isYou {
                    Text("YOU ARE HERE")
                        .font(.system(size: 10, weight: .heavy, design: .rounded))
                        .tracking(1)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .glassEffect(.regular, in: .capsule)
                }
            }
        }
        .buttonStyle(.plain)
        .position(x: place.x, y: place.y)
        .zIndex(friend.isYou ? 1 : 0)
        .animation(.spring(response: 1.0, dampingFraction: 0.75), value: model.category)
    }
}

/// Left-edge ruler: how much of the budget is used at each depth.
private struct DepthGauge: View {
    let top: CGFloat
    let height: CGFloat
    let width: CGFloat

    private let marks: [(label: String, value: Double)] = [
        ("0%", 0), ("25%", 0.25), ("50%", 0.5), ("75%", 0.75), ("100%", 1.0),
    ]

    var body: some View {
        ZStack(alignment: .topLeading) {
            ForEach(marks, id: \.label) { mark in
                let y = top + CGFloat(mark.value / ReefViewModel.maxDepth) * height
                HStack(spacing: 6) {
                    Text(mark.label)
                        .font(.system(size: 10, weight: .semibold, design: .rounded))
                    Capsule().frame(width: 10, height: 1.5)
                }
                .foregroundStyle(.white.opacity(0.6))
                .position(x: 34, y: y)
            }

            Text("THE TRENCH")
                .font(.system(size: 9, weight: .heavy, design: .rounded))
                .tracking(1.5)
                .foregroundStyle(.white.opacity(0.4))
                .position(x: width - 56, y: top + height + 4)
        }
        .accessibilityHidden(true)
    }
}

private struct YourFishCard: View {
    var model: ReefViewModel

    var body: some View {
        let friend = model.selected
        let ranked = model.rank(of: friend)
        let depth = friend.depth(in: model.category)

        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(friend.isYou ? "Your fish" : friend.name)
                        .font(.headline)
                    Text(subtitle(ranked: ranked, depth: depth))
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.75))
                }
                Spacer()
                if let ranked {
                    Text(ranked.rank.ordinal)
                        .font(.system(size: 28, weight: .heavy, design: .rounded))
                        .contentTransition(.numericText())
                }
            }

            DepthBar(value: depth)
        }
        .foregroundStyle(.white)
        .padding(18)
        .glassEffect(.regular.tint(Color.black.opacity(0.12)), in: .rect(cornerRadius: 26))
        .animation(.spring(response: 0.6, dampingFraction: 0.85), value: model.category)
        .animation(.spring(response: 0.6, dampingFraction: 0.85), value: model.selectedID)
    }

    private func subtitle(ranked: RankedFriend?, depth: Double?) -> String {
        guard let depth else { return "Hidden from friends in \(model.category.title.lowercased())" }
        let percent = Int((depth * 100).rounded())
        let line = ranked.map { model.friendlyLine(for: $0) } ?? ""
        let base = depth > 1 ? "Over budget · \(percent)%" : "\(percent)% of budget used"
        return line.isEmpty ? base : "\(base) · \(line)"
    }
}

private struct DepthBar: View {
    let value: Double?

    var body: some View {
        GeometryReader { geo in
            let fraction = min((value ?? 0) / ReefViewModel.maxDepth, 1)
            ZStack(alignment: .leading) {
                Capsule().fill(.white.opacity(0.18))
                Capsule()
                    .fill(LinearGradient(colors: [Color(hex: 0x4CC9BF), Theme.coral],
                                         startPoint: .leading, endPoint: .trailing))
                    .frame(width: max(geo.size.width * fraction, 10))
            }
        }
        .frame(height: 8)
        .animation(.spring(response: 0.8, dampingFraction: 0.8), value: value)
    }
}

#Preview {
    ActivityView()
}
