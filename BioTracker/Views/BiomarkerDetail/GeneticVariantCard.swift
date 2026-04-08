import SwiftUI

struct GeneticVariantCard: View {
    let variant: GeneticVariant

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(variant.gene)
                        .font(.headline)
                    Text(variant.rsid)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Text(variant.genotype)
                    .font(.title3.bold().monospaced())
                magnitudeBadge
            }

            if !variant.status.isEmpty {
                Text(variant.status)
                    .font(.subheadline.bold())
                    .foregroundStyle(variant.isProtective ? .green : statusColor)
            }

            if !variant.statusDescription.isEmpty {
                Text(variant.statusDescription)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if let note = variant.clinicalNote, !note.isEmpty {
                Text(note)
                    .font(.caption)
                    .foregroundStyle(.orange)
                    .padding(8)
                    .background(Color.orange.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
            }
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }

    private var magnitudeBadge: some View {
        Text(variant.magnitudeLabel)
            .font(.caption2.bold())
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(magnitudeColor.opacity(0.15))
            .foregroundStyle(magnitudeColor)
            .clipShape(Capsule())
    }

    private var statusColor: Color {
        switch variant.magnitude {
        case 4...6: .red
        case 3: .orange
        case 2: .yellow
        default: .secondary
        }
    }

    private var magnitudeColor: Color {
        switch variant.magnitude {
        case 4...6: .red
        case 3: .orange
        case 2: .yellow
        case 1: .blue
        default: .secondary
        }
    }
}
