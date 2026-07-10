import SwiftUI

struct DiaryLogEntryRowView: View {
    let entry: DiaryLogEntry
    let onEditRequested: () -> Void
    let onDeleteRequested: () -> Void

    @State private var dragOffset: CGFloat = 0
    private let deleteButtonWidth: CGFloat = 76

    var body: some View {
        ZStack(alignment: .trailing) {
            Button(action: onDeleteRequested) {
                VStack(spacing: 4) {
                    Image(systemName: "trash")
                        .font(.system(size: 16))
                    Text("Delete")
                        .font(.system(size: 11, weight: .semibold))
                }
                .foregroundStyle(.white)
                .frame(width: deleteButtonWidth, height: 44)
            }
            .background(DesignTokens.dangerBackground)
            .clipShape(RoundedRectangle(cornerRadius: 10))

            rowContent
                .offset(x: dragOffset)
                .gesture(
                    DragGesture(minimumDistance: 10)
                        .onChanged { value in
                            guard value.translation.width < 0 else { dragOffset = 0; return }
                            dragOffset = max(value.translation.width, -deleteButtonWidth)
                        }
                        .onEnded { value in
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                dragOffset = value.translation.width < -deleteButtonWidth / 2
                                    ? -deleteButtonWidth : 0
                            }
                        }
                )
                .onTapGesture {
                    if dragOffset != 0 {
                        withAnimation { dragOffset = 0 }
                    } else {
                        onEditRequested()
                    }
                }
        }
    }

    private var rowContent: some View {
        HStack(alignment: .center, spacing: 8) {
            Text(entry.timeString)
                .font(.custom("Geist Mono", size: 11))
                .foregroundStyle(DesignTokens.textTertiary)
                .frame(width: 40, alignment: .leading)

            HStack(spacing: 7) {
                Circle()
                    .fill(entry.isEstimated ? DesignTokens.confidenceEstimatedDot : DesignTokens.confidenceMeasuredDot)
                    .frame(width: 7, height: 7)
                Text(entry.foodName)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(DesignTokens.textPrimary)
                    .lineLimit(1)
                    .truncationMode(.tail)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            HStack(alignment: .lastTextBaseline, spacing: 7) {
                if let weightG = entry.weightG {
                    HStack(alignment: .lastTextBaseline, spacing: 1) {
                        Text("\(Int(weightG))")
                            .font(.custom("Geist Mono", size: 12))
                            .foregroundStyle(DesignTokens.textPrimary)
                        Text("g")
                            .font(.system(size: 10))
                            .foregroundStyle(DesignTokens.textTertiary)
                    }
                }
                HStack(alignment: .lastTextBaseline, spacing: 1) {
                    Text("\(Int(entry.calories))")
                        .font(.custom("Geist Mono", size: 12))
                        .foregroundStyle(DesignTokens.textPrimary)
                    Text("kcal")
                        .font(.system(size: 10))
                        .foregroundStyle(DesignTokens.textTertiary)
                }
            }
        }
        .padding(.vertical, 9)
        .padding(.horizontal, 12)
        .background(DesignTokens.backgroundElevated)
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(DesignTokens.border, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .applyShadow1()
    }
}
