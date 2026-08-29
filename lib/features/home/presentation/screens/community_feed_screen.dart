import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:playhub_playbooking/core/models/app_models.dart';
import 'package:playhub_playbooking/core/repositories/community_repository.dart';
import 'package:playhub_playbooking/shared/components/empty_view.dart';
import 'package:playhub_playbooking/shared/components/error_view.dart';
import 'package:playhub_playbooking/shared/components/loading_indicator.dart';

final communityFeedProvider = FutureProvider.autoDispose<List<CommunityPostItem>>((ref) async {
  final repo = ref.watch(communityRepositoryProvider);
  return repo.getFeedPosts();
});

final communitiesListProvider = FutureProvider.autoDispose<List<CommunityItem>>((ref) async {
  final repo = ref.watch(communityRepositoryProvider);
  return repo.getCommunities();
});

class CommunityFeedScreen extends ConsumerWidget {
  const CommunityFeedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final feedAsync = ref.watch(communityFeedProvider);
    final communitiesAsync = ref.watch(communitiesListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Community Feed', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.group_add_outlined),
            tooltip: 'Discover Communities',
            onPressed: () {
              _showCommunitiesModal(context, ref);
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(communityFeedProvider);
          ref.invalidate(communitiesListProvider);
        },
        child: CustomScrollView(
          slivers: [
            // Communities Horizontal Carousel
            SliverToBoxAdapter(
              child: communitiesAsync.when(
                data: (communities) {
                  return Container(
                    height: 100,
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: communities.length,
                      separatorBuilder: (c, i) => const SizedBox(width: 12),
                      itemBuilder: (context, index) {
                        final comm = communities[index];
                        return _CommunityPill(community: comm);
                      },
                    ),
                  );
                },
                loading: () => const SizedBox(height: 100, child: Center(child: CircularProgressIndicator.adaptive())),
                error: (err, stack) => const SizedBox.shrink(),
              ),
            ),

            // Feed Posts Header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: Text(
                  'Recent Posts & Activity',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
            ),

            // Posts List
            feedAsync.when(
              data: (posts) {
                if (posts.isEmpty) {
                  return SliverFillRemaining(
                    child: EmptyView(
                      icon: Icons.forum_outlined,
                      title: 'No posts yet',
                      message: 'Share your latest sports achievements and match experiences with the community!',
                      actionLabel: 'Create a Post',
                      onAction: () => _showCreatePostModal(context, ref),
                    ),
                  );
                }

                return SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final post = posts[index];
                      return _PostCard(post: post);
                    },
                    childCount: posts.length,
                  ),
                );
              },
              loading: () => SliverList(
                delegate: SliverChildBuilderDelegate(
                  (c, i) => const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.0),
                    child: SkeletonCard(height: 220),
                  ),
                  childCount: 3,
                ),
              ),
              error: (err, stack) => SliverFillRemaining(
                child: AppErrorView(
                  message: 'Failed to load community feed: $err',
                  onRetry: () => ref.invalidate(communityFeedProvider),
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreatePostModal(context, ref),
        tooltip: 'Create Post',
        child: const Icon(Icons.add_comment_outlined),
      ),
    );
  }

  void _showCommunitiesModal(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final communitiesAsync = ref.watch(communitiesListProvider);
        return Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Sports Communities', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              communitiesAsync.when(
                data: (list) => ListView.separated(
                  shrinkWrap: true,
                  itemCount: list.length,
                  separatorBuilder: (c, i) => const Divider(),
                  itemBuilder: (context, index) {
                    final comm = list[index];
                    return ListTile(
                      leading: CircleAvatar(child: Text(comm.sport[0])),
                      title: Text(comm.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text('${comm.memberCount} members • ${comm.description}', maxLines: 1, overflow: TextOverflow.ellipsis),
                      trailing: comm.isJoined
                          ? const Chip(label: Text('Joined', style: TextStyle(fontSize: 11)))
                          : ElevatedButton(
                              onPressed: () async {
                                await ref.read(communityRepositoryProvider).joinCommunity(comm.id);
                                ref.invalidate(communitiesListProvider);
                              },
                              style: ElevatedButton.styleFrom(visualDensity: VisualDensity.compact),
                              child: const Text('Join'),
                            ),
                    );
                  },
                ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Text('Error: $e'),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showCreatePostModal(BuildContext context, WidgetRef ref) {
    final textController = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            top: 20,
            left: 20,
            right: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Create Post', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: textController,
                maxLines: 4,
                decoration: const InputDecoration(
                  hintText: 'Share a game highlight, look for team players, or post an update...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () async {
                  final text = textController.text.trim();
                  if (text.isNotEmpty) {
                    await ref.read(communityRepositoryProvider).createPost(text);
                    ref.invalidate(communityFeedProvider);
                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Post published to community!')),
                      );
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Publish Post'),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _CommunityPill extends ConsumerWidget {
  final CommunityItem community;

  const _CommunityPill({required this.community});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: 170,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 12,
                backgroundColor: colorScheme.primaryContainer,
                child: Text(community.sport[0], style: TextStyle(fontSize: 10, color: colorScheme.onPrimaryContainer, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  community.sport,
                  style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          Text(
            community.name,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            '${community.memberCount} members',
            style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

class _PostCard extends ConsumerWidget {
  final CommunityPostItem post;

  const _PostCard({required this.post});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final timeFormat = DateFormat('MMM d • h:mm a');

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Author Header
          ListTile(
            leading: CircleAvatar(
              backgroundColor: colorScheme.primaryContainer,
              child: Text(
                post.authorName[0].toUpperCase(),
                style: TextStyle(color: colorScheme.onPrimaryContainer, fontWeight: FontWeight.bold),
              ),
            ),
            title: Text(post.authorName, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('${timeFormat.format(post.createdAt)} • ${post.communityName}', style: const TextStyle(fontSize: 12)),
            trailing: IconButton(
              icon: const Icon(Icons.more_vert),
              onPressed: () {},
            ),
          ),

          // Post Text Content
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Text(
              post.content,
              style: theme.textTheme.bodyMedium?.copyWith(height: 1.4),
            ),
          ),

          // Post Image if present
          if (post.imageUrl != null) ...[
            const SizedBox(height: 8),
            Image.network(
              post.imageUrl!,
              height: 200,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (c, e, s) => Container(
                height: 120,
                color: colorScheme.surfaceContainerHighest,
                child: const Center(child: Icon(Icons.broken_image, color: Colors.grey)),
              ),
            ),
          ],

          // Post Action Buttons
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(
                    post.isLiked ? Icons.favorite : Icons.favorite_border,
                    color: post.isLiked ? Colors.red : colorScheme.onSurfaceVariant,
                  ),
                  onPressed: () {
                    ref.read(communityRepositoryProvider).toggleLike(post.id);
                    ref.invalidate(communityFeedProvider);
                  },
                ),
                Text('${post.likes}', style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 13)),
                const SizedBox(width: 16),
                IconButton(
                  icon: Icon(Icons.chat_bubble_outline, color: colorScheme.onSurfaceVariant),
                  onPressed: () => _showCommentsModal(context, ref, post),
                ),
                Text('${post.comments}', style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 13)),
                const Spacer(),
                IconButton(
                  icon: Icon(Icons.share_outlined, color: colorScheme.onSurfaceVariant),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Post link copied to clipboard')),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showCommentsModal(BuildContext context, WidgetRef ref, CommunityPostItem post) {
    final commentController = TextEditingController();
    final repo = ref.read(communityRepositoryProvider);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => FutureBuilder<List<CommunityCommentItem>>(
          future: repo.getComments(post.id),
          builder: (context, snapshot) {
            final comments = snapshot.data ?? [];
            return Container(
              height: MediaQuery.of(context).size.height * 0.65,
              padding: EdgeInsets.only(
                top: 20,
                left: 16,
                right: 16,
                bottom: MediaQuery.of(context).viewInsets.bottom + 16,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Comments (${comments.length})',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: comments.isEmpty
                        ? const Center(
                            child: Text('No comments yet. Be the first to join the conversation!'),
                          )
                        : ListView.separated(
                            itemCount: comments.length,
                            separatorBuilder: (c, i) => const Divider(height: 16),
                            itemBuilder: (context, index) {
                              final c = comments[index];
                              return Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  CircleAvatar(
                                    radius: 16,
                                    backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                                    child: Text(
                                      c.authorName.isNotEmpty ? c.authorName[0].toUpperCase() : 'U',
                                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          c.authorName,
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(c.text, style: const TextStyle(fontSize: 13)),
                                      ],
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: commentController,
                          decoration: InputDecoration(
                            hintText: 'Add a comment...',
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(24)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton.filled(
                        icon: const Icon(Icons.send, size: 18),
                        onPressed: () async {
                          final text = commentController.text.trim();
                          if (text.isEmpty) return;
                          commentController.clear();
                          await repo.addComment(post.id, text);
                          ref.invalidate(communityFeedProvider);
                          setModalState(() {});
                        },
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

