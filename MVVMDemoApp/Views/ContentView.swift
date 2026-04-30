import SwiftUI

struct ContentView: View {
    @StateObject private var userViewModel: UserViewModel
    @StateObject private var bannerViewModel: BannerViewModel

    init(environment: AppEnvironment) {
        _userViewModel = StateObject(wrappedValue: UserViewModel(repository: environment.userRepository))
        _bannerViewModel = StateObject(wrappedValue: BannerViewModel(repository: environment.bannerRepository))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    bannerSection
                    userSection
                }
                .padding(16)
            }
            .navigationTitle("首页示例")
            .toolbar {
                Button("刷新") {
                    userViewModel.load(forceRefresh: true)
                    bannerViewModel.load(forceRefresh: true)
                }
            }
        }
        .onAppear {
            if userViewModel.user == nil, !userViewModel.isLoading {
                userViewModel.load()
            }
            if bannerViewModel.banners.isEmpty, !bannerViewModel.isLoading {
                bannerViewModel.load()
            }
        }
    }

    @ViewBuilder
    private var bannerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Banner 区域")
                .font(.title3)
                .fontWeight(.semibold)

            if bannerViewModel.isLoading && bannerViewModel.banners.isEmpty {
                ProgressView("加载 Banner 中...")
                    .frame(maxWidth: .infinity, alignment: .center)
            } else if !bannerViewModel.banners.isEmpty {
                VStack(spacing: 12) {
                    ForEach(bannerViewModel.banners) { banner in
                        VStack(alignment: .leading, spacing: 8) {
                            Text(banner.title)
                                .font(.headline)
                            Text(banner.subtitle)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            Text(banner.imageURL)
                                .font(.footnote)
                                .foregroundStyle(.blue)
                            Text("跳转：\(banner.deeplink)")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
            } else if let errorMessage = bannerViewModel.errorMessage {
                ErrorStateView(message: errorMessage) {
                    bannerViewModel.load(forceRefresh: true)
                }
            } else if bannerViewModel.banners.isEmpty {
                EmptyStateView(title: "暂无 Banner 数据", buttonTitle: "重新加载") {
                    bannerViewModel.load(forceRefresh: true)
                }
            }
        }
    }

    @ViewBuilder
    private var userSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("User 区域")
                .font(.title3)
                .fontWeight(.semibold)

            if userViewModel.isLoading && userViewModel.user == nil {
                ProgressView("加载用户中...")
                    .frame(maxWidth: .infinity, alignment: .center)
            } else if let user = userViewModel.user {
                VStack(spacing: 12) {
                    infoRow(title: "姓名", value: user.name)
                    infoRow(title: "邮箱", value: user.email)
                    infoRow(title: "电话", value: user.phone)
                    infoRow(title: "地址", value: user.address)
                    infoRow(title: "头像", value: user.avatarURL)
                    infoRow(title: "更新时间", value: user.lastUpdated.formatted(date: .abbreviated, time: .shortened))
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            } else if let errorMessage = userViewModel.errorMessage {
                ErrorStateView(message: errorMessage) {
                    userViewModel.load(forceRefresh: true)
                }
            } else {
                EmptyStateView(title: "暂无用户数据", buttonTitle: "重新加载") {
                    userViewModel.load(forceRefresh: true)
                }
            }
        }
    }

    @ViewBuilder
    private func infoRow(title: String, value: String) -> some View {
        HStack(alignment: .top) {
            Text(title)
                .foregroundStyle(.secondary)
                .frame(width: 72, alignment: .leading)
            Text(value)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
