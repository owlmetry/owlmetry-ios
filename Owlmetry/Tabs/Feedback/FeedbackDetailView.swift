import Owlmetry
import SwiftUI

struct FeedbackDetailView: View {
  let feedback: Feedback
  var onDeleted: ((String) -> Void)? = nil
  var onUpdated: ((Feedback) -> Void)? = nil

  @EnvironmentObject private var appState: AppState
  @StateObject private var viewModel = FeedbackDetailViewModel()
  @Environment(\.dismiss) private var dismiss
  @State private var showDeleteConfirm = false

  private var current: Feedback { viewModel.feedback ?? feedback }
  private var project: Project? { appState.projectsById[feedback.projectId] }
  private var app: AppModel? { appState.apps.first(where: { $0.id == feedback.appId }) }

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 16) {
        header
        messageBox
        InfoGrid(items: infoItems).padding(.horizontal, 16)
        if !viewModel.comments.isEmpty { commentsSection }
      }
      .padding(.vertical, 16)
    }
    .navigationTitle("Feedback")
    .navigationBarTitleDisplayMode(.inline)
    .toolbar {
      ToolbarItem(placement: .topBarTrailing) { statusMenu }
    }
    .task(id: feedback.id) {
      await viewModel.load(projectId: feedback.projectId, feedbackId: feedback.id)
    }
    .alert("Delete this feedback?", isPresented: $showDeleteConfirm) {
      Button("Delete", role: .destructive) {
        Task {
          let ok = await viewModel.deleteFeedback(projectId: feedback.projectId, feedbackId: feedback.id)
          if ok {
            Haptics.notify(.success)
            onDeleted?(feedback.id)
            dismiss()
          } else {
            Haptics.notify(.error)
          }
        }
      }
      Button("Cancel", role: .cancel) {}
    } message: {
      Text("This cannot be undone.")
    }
    .alert(
      "Couldn't delete feedback",
      isPresented: Binding(
        get: { viewModel.errorMessage != nil },
        set: { if !$0 { viewModel.errorMessage = nil } }
      )
    ) {
      Button("OK", role: .cancel) {}
    } message: {
      Text(viewModel.errorMessage ?? "")
    }
    .toolbar(.hidden, for: .tabBar)
    .owlScreen("FeedbackDetail")
  }

  private var header: some View {
    VStack(alignment: .leading, spacing: 12) {
      HStack(spacing: 8) {
        ProjectDot(project: project, size: 10)
        Text(project?.name ?? "—")
          .font(.caption.weight(.medium))
          .foregroundStyle(.secondary)
        FeedbackStatusBadge(status: current.status, size: .sm)
        if current.isDev == true {
          DevModeBadge()
        }
        BillingBadge(properties: current.userProperties, size: .sm)
        Spacer()
      }
      Text(submitterTitle)
        .font(.title3.weight(.semibold))
    }
    .padding(.horizontal, 16)
  }

  private var messageBox: some View {
    Text(current.message)
      .font(.body)
      .foregroundStyle(.primary)
      .frame(maxWidth: .infinity, alignment: .leading)
      .padding(14)
      .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Theme.cardBackground))
      .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(Theme.cardBorder, lineWidth: 1))
      .padding(.horizontal, 16)
  }

  private var submitterTitle: String {
    if let name = current.submitterName { return name }
    if let email = current.submitterEmail { return email }
    return "Anonymous user"
  }

  private var infoItems: [InfoGrid.Item] {
    var items: [InfoGrid.Item] = [
      .init(label: "App", value: app?.name ?? "—"),
      .init(label: "Country", value: current.countryCode.map { "\(CountryFlag.emoji(for: $0)) \($0)" } ?? "—")
    ]
    if let email = current.submitterEmail {
      items.append(.init(label: "Email", value: email))
    }
    items.append(.init(label: "Version", value: current.appVersion ?? "—", monospaced: true))
    if let env = current.environment {
      items.append(.init(label: "Environment", value: env))
    }
    if current.deviceModel != nil || current.osVersion != nil {
      items.append(.init(label: "Device", value: [current.deviceModel, current.osVersion].compactMap { $0 }.joined(separator: " · ")))
    }
    if let userId = current.userId {
      items.append(.init(label: "User ID", value: userId, monospaced: true))
    }
    if let sessionId = current.sessionId {
      items.append(.init(label: "Session", value: sessionId, monospaced: true))
    }
    items.append(.init(label: "Created", value: RelativeDate.string(from: current.createdAt)))
    items.append(.init(label: "Updated", value: RelativeDate.string(from: current.updatedAt)))
    return items
  }

  private var commentsSection: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text("Comments")
        .font(.caption.weight(.semibold))
        .foregroundStyle(.secondary)
        .padding(.horizontal, 16)
      VStack(alignment: .leading, spacing: 10) {
        ForEach(viewModel.comments) { comment in
          VStack(alignment: .leading, spacing: 4) {
            HStack {
              Text(comment.authorName ?? "Unknown").font(.caption.weight(.semibold))
              Spacer()
              Text(RelativeDate.shortString(from: comment.createdAt))
                .font(.caption2)
                .foregroundStyle(.secondary)
            }
            Text(comment.body).font(.callout)
          }
          .padding(12)
          .background(RoundedRectangle(cornerRadius: 10, style: .continuous).fill(Theme.cardBackground))
        }
      }
      .padding(.horizontal, 16)
    }
  }

  private var statusMenu: some View {
    Menu {
      ForEach(FeedbackStatus.allCases.filter { $0 != current.status }) { status in
        Button {
          Task {
            await viewModel.updateStatus(projectId: feedback.projectId, feedbackId: feedback.id, status: status)
            if let updated = viewModel.feedback {
              onUpdated?(updated)
            }
          }
        } label: {
          Label("Move to \(status.displayName)", systemImage: "arrow.right")
        }
      }
      Divider()
      Button(role: .destructive) {
        DispatchQueue.main.async { showDeleteConfirm = true }
      } label: {
        Label("Delete", systemImage: "trash")
      }
    } label: {
      Image(systemName: "ellipsis.circle")
    }
  }
}
