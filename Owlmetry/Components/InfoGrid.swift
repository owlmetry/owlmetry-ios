import SwiftUI

struct InfoGrid: View {
  struct Item: Identifiable {
    let id = UUID()
    let label: String
    let value: String
    var monospaced: Bool = false
  }

  let items: [Item]

  var body: some View {
    LazyVGrid(columns: [GridItem(.flexible(), alignment: .topLeading), GridItem(.flexible(), alignment: .topLeading)], spacing: 14) {
      ForEach(items, id: \.id) { (item: Item) in
        VStack(alignment: .leading, spacing: 2) {
          Text(item.label.uppercased())
            .font(.system(size: 9, weight: .semibold))
            .tracking(0.6)
            .foregroundStyle(.secondary)
          if item.monospaced {
            Text(item.value)
              .font(.callout.monospaced())
              .foregroundStyle(.primary)
              .textSelection(.enabled)
          } else {
            Text(item.value)
              .font(.callout)
              .foregroundStyle(.primary)
              .textSelection(.enabled)
          }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
      }
    }
  }
}
