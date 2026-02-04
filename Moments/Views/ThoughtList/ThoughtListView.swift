//
//  ThoughtListView.swift
//  Moments
//
//  主列表视图
//

import SwiftUI

struct ThoughtListView: View {
    @State private var viewModel = ThoughtListViewModel()
    @State private var showCompose = false
    @State private var selectedThought: Thought?

    var body: some View {
        NavigationStack {
            ZStack {
                if viewModel.isEmpty {
                    EmptyStateView(
                        icon: "text.bubble",
                        title: "还没有任何想法",
                        message: "点击右上角的按钮，记录你的第一个想法吧",
                        action: { showCompose = true },
                        actionTitle: "开始记录"
                    )
                } else {
                    thoughtList
                }
            }
            .navigationTitle("Moments")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    composeButton
                }
            }
            .sheet(isPresented: $showCompose) {
                ComposeView(onPublished: { thought in
                    viewModel.addThought(thought)
                })
            }
            .sheet(item: $selectedThought) { thought in
                ThoughtDetailView(thought: thought)
            }
        }
        .task {
            await viewModel.loadThoughts()
        }
    }

    // MARK: - Subviews

    private var thoughtList: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                // 标签筛选栏
                if !viewModel.allTags.isEmpty {
                    TagFilterBar(
                        tags: viewModel.allTags,
                        selectedTag: viewModel.selectedTag,
                        onSelect: { tag in
                            Task {
                                await viewModel.filterByTag(tag)
                            }
                        }
                    )
                    .padding(.bottom, 8)
                }

                // 想法列表
                if !viewModel.thoughts.isEmpty {
                    VStack(spacing: 0) {
                        ForEach(Array(viewModel.thoughts.enumerated()), id: \.element.id) { index, thought in
                            ThoughtCard(
                                thought: thought,
                                onTap: {
                                    selectedThought = thought
                                },
                                onDelete: {
                                    Task {
                                        await viewModel.deleteThought(thought)
                                    }
                                }
                            )
                        }
                    }
                    .transition(.asymmetric(
                        insertion: .offset(y: 10).combined(with: .opacity),
                        removal: .move(edge: viewModel.slideDirection == .right ? .leading : .trailing)
                            .combined(with: .opacity)
                    ))
                }

                // 底部加载触发器
                if viewModel.hasMore {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 20)
                        .onAppear {
                            Task {
                                await viewModel.loadMoreThoughts()
                            }
                        }
                }

                // 切换标签时的加载指示器
                if viewModel.thoughts.isEmpty && viewModel.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 60)
                        .transition(.opacity)
                }

                // 底部占位
                Color.clear.frame(height: 20)
            }
        }
        .refreshable {
            await viewModel.refresh()
        }
    }

    private var composeButton: some View {
        Button {
            HapticManager.lightImpact()
            showCompose = true
        } label: {
            Image(systemName: "square.and.pencil")
                .font(.system(size: 18, weight: .medium))
        }
    }
}

// MARK: - Preview

#Preview {
    ThoughtListView()
}
