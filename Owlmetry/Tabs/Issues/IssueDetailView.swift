import Owlmetry
import SwiftUI

struct IssueDetailView: View {
  let issue: Issue

  @EnvironmentObject private var appState: AppState
  @StateObject private var viewModel = IssueDetailViewModel()
  @State private var showResolveSheet = false
  @State private var resolveVersion: String = ""
  @State private var commentDraft: String = ""
  @FocusState private var commentFieldFocused: Bool

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 16) {
        header
        InfoGrid(items: infoItems)
          .padding(.horizontal, 16)
        if let errorMessage = viewModel.errorMessage {
          Text(errorMessage)
            .font(.caption)
            .foregroundStyle(.red)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(12)
            .background(
              RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color.red.opacity(0.1))
            )
            .padding(.horizontal, 16)
        }
        commentsSection
        if !viewModel.occurrences.isEmpty {
          occurrencesSection
        }
        if let attachments = viewModel.attachments, !attachments.isEmpty {
          attachmentsSection(attachments)
        }
        if let fingerprints = viewModel.fingerprints, !fingerprints.isEmpty {
          fingerprintsSection(fingerprints)
        }
      }
      .padding(.vertical, 16)
    }
    .navigationTitle("Issue")
    .navigationBarTitleDisplayMode(.inline)
    .toolbar {
      ToolbarItem(placement: .topBarTrailing) {
        statusMenu
      }
    }
    .task(id: issue.id) {
      await viewModel.load(projectId: issue.projectId, issueId: issue.id)
    }
    .sheet(isPresented: $showResolveSheet) {
      resolveSheet
    }
    .toolbar(.hidden, for: .tabBar)
    .owlScreen("IssueDetail")
  }

  private var currentIssue: Issue {
    viewModel.issue ?? issue
  }

  private var project: Project? { appState.projectsById[issue.projectId] }
  private var app: AppModel? { appState.apps.first(where: { $0.id == issue.appId }) }

  private var header: some View {
    VStack(alignment: .leading, spacing: 12) {
      HStack(spacing: 8) {
        ProjectDot(project: project, size: 10)
        Text(project?.name ?? "—")
          .font(.caption.weight(.medium))
          .foregroundStyle(.secondary)
        IssueStatusBadge(status: currentIssue.status, size: .sm)
        if currentIssue.isDev == true {
          DevModeBadge()
        }
        Spacer()
      }
      Text(currentIssue.title)
        .font(.title3.weight(.semibold))
        .foregroundStyle(.primary)
    }
    .padding(.horizontal, 16)
  }

  private var infoItems: [InfoGrid.Item] {
    [
      .init(label: "App", value: app?.name ?? "—"),
      .init(label: "Source", value: currentIssue.source ?? "—"),
      .init(label: "Occurrences", value: "\(currentIssue.occurrenceCount)"),
      .init(label: "Unique Users", value: "\(currentIssue.uniqueUserCount)"),
      .init(label: "First Seen", value: RelativeDate.string(from: currentIssue.firstSeenAt)),
      .init(label: "Last Seen", value: RelativeDate.string(from: currentIssue.lastSeenAt)),
      .init(label: "First Version", value: currentIssue.firstSeenAppVersion ?? "—", monospaced: true),
      .init(label: "Last Version", value: currentIssue.lastSeenAppVersion ?? "—", monospaced: true)
    ]
  }

  private var commentsSection: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text("Comments")
        .font(.caption.weight(.semibold))
        .foregroundStyle(.secondary)
        .padding(.horizontal, 16)
      VStack(alignment: .leading, spacing: 10) {
        if viewModel.comments.isEmpty {
          Text("No comments yet.")
            .font(.caption)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(12)
            .background(
              RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Theme.cardBackground)
            )
        }
        ForEach(viewModel.comments) { comment in
          VStack(alignment: .leading, spacing: 4) {
            HStack {
              Text(authorLabel(for: comment))
                .font(.caption.weight(.semibold))
              Spacer()
              Text(RelativeDate.shortString(from: comment.createdAt))
                .font(.caption2)
                .foregroundStyle(.secondary)
            }
            Text(comment.body)
              .font(.callout)
          }
          .padding(12)
          .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
              .fill(Theme.cardBackground)
          )
        }
        commentComposer
      }
      .padding(.horizontal, 16)
    }
  }

  private func authorLabel(for comment: IssueComment) -> String {
    let emoji = comment.authorType == "agent" ? "🕶️" : "👤"
    return "\(emoji) \(comment.authorName ?? "Unknown")"
  }

  private var commentComposer: some View {
    HStack(alignment: .bottom, spacing: 8) {
      TextField("Add a comment", text: $commentDraft, axis: .vertical)
        .lineLimit(1...4)
        .focused($commentFieldFocused)
        .textFieldStyle(.plain)
        .padding(10)
        .background(
          RoundedRectangle(cornerRadius: 10, style: .continuous)
            .fill(Theme.cardBackground)
        )
      Button {
        let body = commentDraft
        commentFieldFocused = false
        Task {
          await viewModel.submitComment(
            projectId: issue.projectId,
            issueId: issue.id,
            body: body
          )
          if viewModel.errorMessage == nil {
            commentDraft = ""
          }
        }
      } label: {
        if viewModel.isSubmittingComment {
          ProgressView()
            .frame(width: 22, height: 22)
        } else {
          Image(systemName: "paperplane.fill")
            .font(.body.weight(.semibold))
        }
      }
      .disabled(commentDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || viewModel.isSubmittingComment)
      .padding(.bottom, 4)
    }
  }

  private var occurrencesSection: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text("Occurrences (\(viewModel.occurrences.count))")
        .font(.caption.weight(.semibold))
        .foregroundStyle(.secondary)
        .padding(.horizontal, 16)
      VStack(spacing: 0) {
        ForEach(Array(viewModel.occurrences.enumerated()), id: \.element.id) { index, occurrence in
          occurrenceRow(occurrence)
          if index < viewModel.occurrences.count - 1 {
            Divider()
          }
        }
      }
      .background(
        RoundedRectangle(cornerRadius: 10, style: .continuous)
          .fill(Theme.cardBackground)
      )
      .padding(.horizontal, 16)
    }
  }

  private func occurrenceRow(_ occurrence: IssueOccurrence) -> some View {
    VStack(alignment: .leading, spacing: 4) {
      HStack(spacing: 8) {
        Text(occurrence.userId ?? "—")
          .font(.caption.monospaced())
          .lineLimit(1)
          .truncationMode(.middle)
        Spacer(minLength: 0)
        if let country = occurrence.countryCode {
          Text(CountryFlag.emoji(for: country))
        }
      }
      HStack(spacing: 8) {
        Text(RelativeDate.shortString(from: occurrence.timestamp))
          .font(.caption2)
          .foregroundStyle(.secondary)
        if let version = occurrence.appVersion {
          Text("·").font(.caption2).foregroundStyle(.secondary)
          Text(version)
            .font(.caption2.monospaced())
            .foregroundStyle(.secondary)
        }
        if let env = occurrence.environment {
          Text("·").font(.caption2).foregroundStyle(.secondary)
          Text(env)
            .font(.caption2)
            .foregroundStyle(.secondary)
        }
        Spacer(minLength: 0)
      }
    }
    .padding(.horizontal, 12)
    .padding(.vertical, 10)
  }

  private func attachmentsSection(_ attachments: [IssueAttachment]) -> some View {
    VStack(alignment: .leading, spacing: 8) {
      Text("Attachments")
        .font(.caption.weight(.semibold))
        .foregroundStyle(.secondary)
        .padding(.horizontal, 16)
      VStack(spacing: 8) {
        ForEach(attachments) { attachment in
          HStack {
            Image(systemName: "paperclip")
            VStack(alignment: .leading) {
              Text(attachment.filename).font(.footnote)
              Text(attachment.contentType ?? "—").font(.caption2).foregroundStyle(.secondary)
            }
            Spacer()
            if let size = attachment.sizeBytes {
              Text(byteFormatter.string(fromByteCount: Int64(size)))
                .font(.caption2)
                .foregroundStyle(.secondary)
            }
          }
          .padding(10)
          .background(RoundedRectangle(cornerRadius: 10, style: .continuous).fill(Theme.cardBackground))
        }
        Text("Open in dashboard to download attachments")
          .font(.caption2)
          .foregroundStyle(.secondary)
      }
      .padding(.horizontal, 16)
    }
  }

  private func fingerprintsSection(_ fingerprints: [String]) -> some View {
    VStack(alignment: .leading, spacing: 8) {
      Text("Fingerprints")
        .font(.caption.weight(.semibold))
        .foregroundStyle(.secondary)
        .padding(.horizontal, 16)
      VStack(alignment: .leading, spacing: 4) {
        ForEach(fingerprints, id: \.self) { fp in
          Text(fp)
            .font(.caption2.monospaced())
            .padding(8)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: 8).fill(Theme.cardBackground))
        }
      }
      .padding(.horizontal, 16)
    }
  }

  private var statusMenu: some View {
    Menu {
      if currentIssue.status != .resolved {
        Button {
          resolveVersion = currentIssue.lastSeenAppVersion ?? ""
          showResolveSheet = true
        } label: {
          Label("Resolve", systemImage: "checkmark.circle")
        }
      }
      if currentIssue.status != .silenced {
        Button {
          Task { await updateStatus(.silenced) }
        } label: {
          Label("Silence", systemImage: "speaker.slash")
        }
      }
      if currentIssue.status != .inProgress {
        Button {
          Task { await updateStatus(.inProgress) }
        } label: {
          Label("Mark in progress", systemImage: "wrench")
        }
      }
      if currentIssue.status != .new && currentIssue.status != .regressed {
        Button {
          Task { await updateStatus(.new) }
        } label: {
          Label("Reopen", systemImage: "arrow.counterclockwise")
        }
      }
    } label: {
      Image(systemName: "ellipsis.circle")
    }
  }

  private var resolveSheet: some View {
    NavigationStack {
      Form {
        Section {
          TextField("Version", text: $resolveVersion)
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
        } header: {
          Text("Resolved at version (optional)")
        } footer: {
          Text("If this is marked resolved and the same issue reappears in a later version, it will be marked regressed automatically.")
        }
      }
      .navigationTitle("Resolve issue")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .topBarLeading) {
          Button("Cancel") { showResolveSheet = false }
        }
        ToolbarItem(placement: .topBarTrailing) {
          Button("Resolve") {
            let version = resolveVersion.trimmingCharacters(in: .whitespacesAndNewlines)
            showResolveSheet = false
            Task {
              await viewModel.updateStatus(
                projectId: issue.projectId,
                issueId: issue.id,
                status: .resolved,
                resolvedAtVersion: version.isEmpty ? nil : version
              )
            }
          }
          .fontWeight(.semibold)
        }
      }
    }
    .presentationDetents([.medium])
  }

  private func updateStatus(_ status: IssueStatus) async {
    await viewModel.updateStatus(
      projectId: issue.projectId,
      issueId: issue.id,
      status: status,
      resolvedAtVersion: nil
    )
  }

  private let byteFormatter: ByteCountFormatter = {
    let f = ByteCountFormatter()
    f.allowedUnits = [.useKB, .useMB, .useGB]
    f.countStyle = .file
    return f
  }()
}
