import SwiftUI

/// The Activity tab: a tall ocean you scroll down. Each friend swims in their own lane, and the deeper their
/// fish, the more of their own budget they've used. Shallowest is first. Only percentages are shown.
struct ActivityView: View {
    @State private var model = ReefViewModel()

    var body: some View {
        ScrollViewReader { proxy in
            // Header, scroll area and card are stacked (not overlaid), so the scroll area is exactly the visible
            // space between them and "centered" really means the middle of what you can see.
            VStack(spacing: 0) {
                PinnedHeader(model: model) { id in focus(on: id, using: proxy) }
                    .background { OceanPalette.skyTop.ignoresSafeArea(edges: .top) }

                ScrollView {
                    VStack(spacing: 0) {
                        TopOfReefRow(model: model) { id in focus(on: id, using: proxy) }
                            .padding(.top, 6)
                            .padding(.bottom, 26)
                            .frame(maxWidth: .infinity)
                            .background { SkyGradient() }

                        OceanTrack(model: model) { id in focus(on: id, using: proxy) }
                    }
                }
                .scrollIndicators(.hidden)
                .scrollEdgeEffectStyle(.soft, for: .top)

                YourFishCard(model: model)
                    .padding(.horizontal, 16)
                    .padding(.top, 10)
                    .padding(.bottom, 18)
            }
            .background { OceanPalette.deep.ignoresSafeArea() }
            .task {
                // Dive in: after the sky and podium show, swim down to your fish.
                try? await Task.sleep(for: .seconds(1.2))
                focus(on: "you", using: proxy)
            }
        }
    }

    private func focus(on id: String, using proxy: ScrollViewProxy) {
        withAnimation(.spring(response: 0.6, dampingFraction: 0.85)) {
            model.selectedID = id
        }
        withAnimation(.easeInOut(duration: 0.9)) {
            proxy.scrollTo("fish-\(id)", anchor: .center)
        }
    }
}

// MARK: - Sky and pinned header

/// Sky behind the podium. It fades from the page's sky color into the exact blue of the water's surface.
private struct SkyGradient: View {
    var body: some View {
        LinearGradient(
            colors: [OceanPalette.skyTop, Color(light: Color(hex: 0xBFE8FB), dark: Color(hex: 0x0A2A4A)), OceanPalette.surface],
            startPoint: .top,
            endPoint: .bottom
        )
    }
}

/// Title and category chips stay on screen while you dive, so you can switch category from anywhere in the ocean.
private struct PinnedHeader: View {
    @Bindable var model: ReefViewModel
    let onFocusYou: (String) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                Text("Activity")
                    .font(.title.bold())
                Text("resets Monday")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Spacer()
                Button {
                    onFocusYou("you")
                } label: {
                    Label("Find me", systemImage: "scope")
                        .font(.subheadline.weight(.semibold))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .glassEffect(.regular.interactive(), in: .capsule)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 16)

            CategoryChips(model: model, onChange: { onFocusYou(model.selectedID) })
        }
        .padding(.top, 6)
        .padding(.bottom, 10)
    }
}

private struct CategoryChips: View {
    @Bindable var model: ReefViewModel
    let onChange: () -> Void

    var body: some View {
        ScrollView(.horizontal) {
            GlassEffectContainer(spacing: 8) {
                HStack(spacing: 8) {
                    ForEach(ReefCategory.allCases) { category in
                        chip(category)
                    }
                }
                .padding(.horizontal, 16)
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
            onChange()
        } label: {
            Label(category.title, systemImage: category.systemImage)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(isSelected ? Color.white : Theme.text)
                .padding(.horizontal, 14)
                .padding(.vertical, 9)
                .glassEffect(isSelected ? .regular.tint(Theme.accent).interactive() : .regular.interactive(),
                             in: .capsule)
        }
        .buttonStyle(.plain)
        .sensoryFeedback(.selection, trigger: model.category)
    }
}

// MARK: - Podium

/// Ranking, shallowest first. Tap someone to swim down to their fish.
private struct TopOfReefRow: View {
    var model: ReefViewModel
    let onSelect: (String) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: "trophy.fill")
                    .foregroundStyle(Theme.yellow)
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
        .foregroundStyle(Theme.text)
    }

    private func entry(_ ranked: RankedFriend) -> some View {
        let isFirst = ranked.rank == 1
        return Button {
            onSelect(ranked.friend.id)
        } label: {
            VStack(spacing: 6) {
                Text(ranked.friend.initials)
                    .font(.system(size: isFirst ? 18 : 15, weight: .bold, design: .rounded))
                    .foregroundStyle(ranked.friend.isYou ? Theme.charcoal : Theme.text)
                    .frame(width: isFirst ? 62 : 52, height: isFirst ? 62 : 52)
                    .glassEffect(ranked.friend.isYou ? .regular.tint(Theme.yellow) : .regular, in: .circle)
                    .overlay(alignment: .topTrailing) {
                        Text("\(ranked.rank)")
                            .font(.system(size: 11, weight: .heavy, design: .rounded))
                            .foregroundStyle(isFirst ? Theme.charcoal : Color.white)
                            .frame(width: 20, height: 20)
                            .background(isFirst ? Theme.yellow : Theme.charcoal, in: Circle())
                            .offset(x: 3, y: -3)
                            .zIndex(1)
                    }
                    .zIndex(1)
                Text(ranked.friend.isYou ? "You" : ranked.friend.name)
                    .font(.caption.weight(.semibold))
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Ocean track

/// The tall ocean. Depth sets how far down a fish is; sideways it takes a spot that changes with the ranking,
/// so fish aren't tied to one lane.
private struct OceanTrack: View {
    var model: ReefViewModel
    let onSelect: (String) -> Void

    private let oceanHeight: CGFloat = 1300
    private let surfaceMargin: CGFloat = 54
    private let rulerWidth: CGFloat = 50
    private let trenchHeight: CGFloat = 260
    /// Fish in the same spot never get closer than this vertically.
    private let minGap: CGFloat = 96
    /// Horizontal spots across the swimming area, used in turn from the surface down.
    private let spots: [CGFloat] = [0.17, 0.50, 0.83]

    private var trackHeight: CGFloat { oceanHeight - surfaceMargin - trenchHeight }

    private func yTop(for depth: Double) -> CGFloat {
        surfaceMargin + CGFloat(min(max(depth, 0), ReefViewModel.maxDepth) / ReefViewModel.maxDepth) * trackHeight
    }

    private struct Placement {
        let centerX: CGFloat
        let top: CGFloat
        let depth: Double
        let facesRight: Bool
    }

    private let phases: [String: Double] = ["you": 0.0, "summer": 1.4, "raey": 2.6, "mario": 3.9, "alex": 5.1]

    var body: some View {
        GeometryReader { geo in
            let placements = layout(width: geo.size.width)

            ZStack(alignment: .topLeading) {
                DepthRuler(top: surfaceMargin, trackHeight: trackHeight, totalHeight: oceanHeight)

                ForEach(model.friends) { friend in
                    if let place = placements[friend.id] {
                        fish(for: friend, place: place)
                    }
                }
            }
        }
        .frame(height: oceanHeight)
        .background { OceanBackdrop() }
        .animation(.spring(response: 1.0, dampingFraction: 0.78), value: model.category)
    }

    /// Hidden fish hang at mid-depth so their real depth never leaks.
    private func layout(width: CGFloat) -> [String: Placement] {
        let swimWidth = width - rulerWidth
        let ordered: [(friend: ReefFriend, depth: Double)] = model.friends
            .map { ($0, $0.depth(in: model.category) ?? 0.55) }
            .sorted { $0.depth < $1.depth }

        var lastTop: [Int: CGFloat] = [:]
        var result: [String: Placement] = [:]

        for (index, entry) in ordered.enumerated() {
            let spot = index % spots.count
            var top = yTop(for: entry.depth)
            if let previous = lastTop[spot], top - previous < minGap {
                top = previous + minGap
            }
            lastTop[spot] = top
            result[entry.friend.id] = Placement(
                centerX: rulerWidth + swimWidth * spots[spot],
                top: top,
                depth: entry.depth,
                facesRight: spot != 2
            )
        }
        return result
    }

    private func fish(for friend: ReefFriend, place: Placement) -> some View {
        let isHidden = friend.depth(in: model.category) == nil
        let detail = isHidden ? "hidden" : "\(Int((place.depth * 100).rounded()))%"
        let nodeWidth: CGFloat = friend.isYou ? 110 : 92

        return Button {
            onSelect(friend.id)
        } label: {
            FishView(name: friend.name, detail: detail,
                     isYou: friend.isYou, isHidden: isHidden,
                     facesRight: place.facesRight,
                     isSelected: model.selectedID == friend.id,
                     depth: place.depth, phase: phases[friend.id] ?? 0)
                .frame(width: nodeWidth)
        }
        .buttonStyle(.plain)
        .id("fish-\(friend.id)")
        .padding(.leading, place.centerX - nodeWidth / 2)
        .padding(.top, place.top)
        .zIndex(friend.isYou ? 1 : 0)
    }
}

/// Left-edge ruler with a tick every 10% and the sea floor / trench below 100%.
private struct DepthRuler: View {
    let top: CGFloat
    let trackHeight: CGFloat
    let totalHeight: CGFloat

    var body: some View {
        ZStack(alignment: .topLeading) {
            let floorY = top + CGFloat(1.0 / ReefViewModel.maxDepth) * trackHeight

            ForEach(0...10, id: \.self) { step in
                let value = Double(step) / 10
                let y = top + CGFloat(value / ReefViewModel.maxDepth) * trackHeight
                HStack(spacing: 5) {
                    if step % 2 == 0 {
                        Text("\(step * 10)%")
                            .font(.system(size: 10, weight: .semibold, design: .rounded))
                    }
                    Capsule().frame(width: step % 2 == 0 ? 10 : 6, height: 1.5)
                }
                .foregroundStyle(.white.opacity(step % 2 == 0 ? 0.65 : 0.35))
                .frame(width: 50, alignment: .trailing)
                .position(x: 25, y: y)
            }

            Text("SEA FLOOR")
                .font(.system(size: 12, weight: .heavy, design: .rounded))
                .tracking(3)
                .foregroundStyle(.white.opacity(0.85))
                .frame(maxWidth: .infinity)
                .offset(y: floorY + 24)

            Text("THE TRENCH")
                .font(.system(size: 12, weight: .heavy, design: .rounded))
                .tracking(3)
                .foregroundStyle(.white.opacity(0.55))
                .frame(maxWidth: .infinity)
                .offset(y: floorY + 110)
        }
        .accessibilityHidden(true)
    }
}

// MARK: - Bottom card

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
        .glassEffect(.regular.tint(Color.black.opacity(0.25)), in: .rect(cornerRadius: 26))
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
                    .fill(Theme.yellow)
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
