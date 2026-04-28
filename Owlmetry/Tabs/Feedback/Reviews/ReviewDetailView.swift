import Owlmetry
import SwiftUI

struct ReviewDetailView: View {
  let review: Review

  @EnvironmentObject private var appState: AppState

  @State private var current: Review
  @State private var showReplySheet = false
  @State private var replyDraft = ""
  @State private var isSubmitting = false
  @State private var errorMessage: String?
  @State private var showDeleteConfirm = false

  private static let maxReplyLength = 5970

  init(review: Review) {
    self.review = review
    self._current = State(initialValue: review)
  }

  private var project: Project? { appState.projectsById[current.projectId] }
  private var app: AppModel? { appState.apps.first(where: { $0.id == current.appId }) }
  private var canRespond: Bool { current.store == .appStore }

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 16) {
        header
        if let title = current.title, !title.isEmpty {
          Text(title)
            .font(.title3.weight(.semibold))
            .padding(.horizontal, 16)
        }
        bodyBox
        InfoGrid(items: infoItems).padding(.horizontal, 16)
        if let response = current.developerResponse, !response.isEmpty {
          developerResponseSection(response)
        } else if canRespond {
          replyButton
        }
      }
      .padding(.vertical, 16)
    }
    .navigationTitle("Review")
    .navigationBarTitleDisplayMode(.inline)
    .toolbar(.hidden, for: .tabBar)
    .sheet(isPresented: $showReplySheet) {
      ReplySheet(
        initialText: current.developerResponse ?? "",
        isSubmitting: $isSubmitting,
        maxLength: Self.maxReplyLength,
        onSubmit: { text in await submitReply(text) },
        onCancel: { showReplySheet = false }
      )
      .presentationDetents([.medium, .large])
    }
    .alert("Delete this reply?", isPresented: $showDeleteConfirm) {
      Button("Delete", role: .destructive) { Task { await deleteReply() } }
      Button("Cancel", role: .cancel) {}
    } message: {
      Text("This removes your reply from the public App Store listing. It cannot be undone.")
    }
    .alert(
      "Couldn't update reply",
      isPresented: Binding(
        get: { errorMessage != nil },
        set: { if !$0 { errorMessage = nil } }
      )
    ) {
      Button("OK", role: .cancel) {}
    } message: {
      Text(errorMessage ?? "")
    }
    .owlScreen("ReviewDetail")
  }

  private var header: some View {
    VStack(alignment: .leading, spacing: 12) {
      HStack(spacing: 8) {
        ProjectDot(project: project, size: 10)
        Text(project?.name ?? "—")
          .font(.caption.weight(.medium))
          .foregroundStyle(.secondary)
        Text(current.store.shortName)
          .badgeStyle(tone: .secondary, size: .sm)
        Spacer()
      }
      HStack(alignment: .firstTextBaseline, spacing: 12) {
        StarRow(rating: current.rating, size: .lg)
        Spacer()
        Text(RelativeDate.string(from: current.createdAtInStore))
          .font(.caption)
          .foregroundStyle(.secondary)
      }
    }
    .padding(.horizontal, 16)
  }

  private var bodyBox: some View {
    Text(current.body)
      .font(.body)
      .foregroundStyle(.primary)
      .frame(maxWidth: .infinity, alignment: .leading)
      .padding(14)
      .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Theme.cardBackground))
      .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(Theme.cardBorder, lineWidth: 1))
      .padding(.horizontal, 16)
      .textSelection(.enabled)
  }

  private var infoItems: [InfoGrid.Item] {
    var items: [InfoGrid.Item] = [
      .init(label: "App", value: app?.name ?? current.appName),
      .init(label: "Store", value: current.store.shortName)
    ]
    items.append(.init(
      label: "Country",
      value: current.countryCode.map { "\(CountryFlag.emoji(for: $0)) \($0)" } ?? "—"
    ))
    items.append(.init(label: "Version", value: current.appVersion ?? "—", monospaced: true))
    if let reviewer = current.reviewerName, !reviewer.isEmpty {
      items.append(.init(label: "Reviewer", value: reviewer))
    }
    if let language = current.languageCode, !language.isEmpty {
      items.append(.init(label: "Language", value: language))
    }
    items.append(.init(label: "Posted", value: RelativeDate.string(from: current.createdAtInStore)))
    items.append(.init(label: "Ingested", value: RelativeDate.string(from: current.ingestedAt)))
    return items
  }

  private func developerResponseSection(_ response: String) -> some View {
    VStack(alignment: .leading, spacing: 8) {
      HStack(spacing: 6) {
        Image(systemName: "bubble.left.fill")
        Text("Developer response")
        if let state = current.developerResponseState {
          Text(state.displayLabel)
            .font(.caption2.weight(.medium))
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(
              Capsule().fill(
                state == .pendingPublish
                  ? Color.orange.opacity(0.15)
                  : Color.green.opacity(0.15)
              )
            )
            .foregroundStyle(state == .pendingPublish ? Color.orange : Color.green)
        }
        Spacer()
        if let at = current.developerResponseAt {
          Text(RelativeDate.shortString(from: at))
            .font(.caption2)
            .foregroundStyle(.secondary)
        }
      }
      .font(.caption.weight(.semibold))
      .foregroundStyle(.green)
      Text(response)
        .font(.callout)
        .foregroundStyle(.primary)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 10, style: .continuous).fill(Color.green.opacity(0.08)))
        .overlay(RoundedRectangle(cornerRadius: 10, style: .continuous).stroke(Color.green.opacity(0.25), lineWidth: 1))
        .textSelection(.enabled)
      if canRespond {
        HStack(spacing: 12) {
          Button {
            replyDraft = current.developerResponse ?? ""
            showReplySheet = true
          } label: {
            Label("Edit reply", systemImage: "pencil")
              .font(.caption.weight(.medium))
          }
          .buttonStyle(.bordered)
          .disabled(isSubmitting)

          Button(role: .destructive) {
            showDeleteConfirm = true
          } label: {
            Label("Delete reply", systemImage: "trash")
              .font(.caption.weight(.medium))
          }
          .buttonStyle(.bordered)
          .tint(.red)
          .disabled(isSubmitting)
        }
      }
    }
    .padding(.horizontal, 16)
  }

  private var replyButton: some View {
    Button {
      replyDraft = ""
      showReplySheet = true
    } label: {
      Label("Reply on App Store", systemImage: "bubble.left.fill")
        .frame(maxWidth: .infinity)
    }
    .buttonStyle(.borderedProminent)
    .padding(.horizontal, 16)
    .disabled(isSubmitting)
  }

  private func submitReply(_ text: String) async {
    isSubmitting = true
    defer { isSubmitting = false }
    do {
      let updated = try await ReviewsService.respond(
        projectId: current.projectId,
        reviewId: current.id,
        body: text
      )
      current = updated
      showReplySheet = false
      Haptics.notify(.success)
    } catch let error as APIError {
      errorMessage = error.errorDescription
      Haptics.notify(.error)
      Owl.error("review.respond.failed", attributes: ["error": "\(error)"])
    } catch {
      if error.isCancellation { return }
      errorMessage = error.localizedDescription
      Haptics.notify(.error)
      Owl.error("review.respond.failed", attributes: ["error": "\(error)"])
    }
  }

  private func deleteReply() async {
    isSubmitting = true
    defer { isSubmitting = false }
    do {
      let updated = try await ReviewsService.deleteResponse(
        projectId: current.projectId,
        reviewId: current.id
      )
      current = updated
      Haptics.notify(.success)
    } catch let error as APIError {
      errorMessage = error.errorDescription
      Haptics.notify(.error)
      Owl.error("review.delete_response.failed", attributes: ["error": "\(error)"])
    } catch {
      if error.isCancellation { return }
      errorMessage = error.localizedDescription
      Haptics.notify(.error)
      Owl.error("review.delete_response.failed", attributes: ["error": "\(error)"])
    }
  }
}

private struct ReplySheet: View {
  let initialText: String
  @Binding var isSubmitting: Bool
  let maxLength: Int
  let onSubmit: (String) async -> Void
  let onCancel: () -> Void

  @State private var text: String = ""
  @FocusState private var focused: Bool

  private var trimmed: String { text.trimmingCharacters(in: .whitespacesAndNewlines) }
  private var canSend: Bool { !trimmed.isEmpty && trimmed.count <= maxLength && !isSubmitting }

  var body: some View {
    NavigationStack {
      VStack(alignment: .leading, spacing: 8) {
        TextEditor(text: $text)
          .focused($focused)
          .padding(8)
          .frame(minHeight: 160)
          .background(RoundedRectangle(cornerRadius: 10, style: .continuous).fill(Theme.cardBackground))
          .overlay(RoundedRectangle(cornerRadius: 10, style: .continuous).stroke(Theme.cardBorder, lineWidth: 1))
        HStack {
          Text("Visible publicly on the App Store listing.")
            .font(.caption2)
            .foregroundStyle(.secondary)
          Spacer()
          Text("\(trimmed.count) / \(maxLength)")
            .font(.caption2.monospacedDigit())
            .foregroundStyle(trimmed.count > maxLength ? .red : .secondary)
        }
      }
      .padding(16)
      .navigationTitle(initialText.isEmpty ? "Reply" : "Edit reply")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .topBarLeading) {
          Button("Cancel", role: .cancel, action: onCancel).disabled(isSubmitting)
        }
        ToolbarItem(placement: .topBarTrailing) {
          Button(initialText.isEmpty ? "Send" : "Save") {
            Task { await onSubmit(trimmed) }
          }
          .disabled(!canSend)
        }
      }
      .onAppear {
        text = initialText
        focused = true
      }
    }
  }
}
