import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:playhub_playbooking/app/bootstrap/bootstrap.dart';
import 'package:playhub_playbooking/core/networking/api_client_interface.dart';
import '../models/app_models.dart';

abstract class CommunityRepository {
  Future<List<CommunityItem>> getCommunities();
  Future<List<CommunityPostItem>> getFeedPosts();
  Future<bool> createPost(String content, {String? imageUrl, String communityName = 'Hyderabad Sports Club'});
  Future<bool> toggleLike(String postId);
  Future<bool> joinCommunity(String communityId);
  Future<List<CommunityCommentItem>> getComments(String postId);
  Future<bool> addComment(String postId, String text, {String authorName = 'You'});
}

class CommunityRepositoryImpl implements CommunityRepository {
  final IApiClient apiClient;

  CommunityRepositoryImpl({required this.apiClient});

  final List<CommunityItem> _communities = [
    CommunityItem(
      id: 'comm_001',
      name: 'Hyderabad Strikers Club',
      description: 'The premier community for amateur and semi-pro football players in Hyderabad.',
      sport: 'Football',
      memberCount: 342,
      isJoined: true,
    ),
    CommunityItem(
      id: 'comm_002',
      name: 'Cyberabad Cricket League',
      description: 'Weekend tournaments, practice nets, and friendly matches across Hitech City & Gachibowli.',
      sport: 'Cricket',
      memberCount: 520,
      isJoined: false,
    ),
    CommunityItem(
      id: 'comm_003',
      name: 'Smashers Badminton Group',
      description: 'Daily early morning and evening indoor badminton doubles and singles enthusiasts.',
      sport: 'Badminton',
      memberCount: 189,
      isJoined: false,
    ),
  ];

  final List<CommunityPostItem> _posts = [
    CommunityPostItem(
      id: 'post_001',
      authorName: 'Rahul Sharma',
      communityName: 'Hyderabad Strikers Club',
      content: 'Just finished an intense 5-a-side match at Test Venue! The turf quality is fantastic. Looking for 3 players for our Saturday evening match at 6 PM. Drop a comment if you are interested!',
      imageUrl: 'https://images.unsplash.com/photo-1574629810360-7efbbe195018?w=800',
      likes: 28,
      comments: 7,
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
      isLiked: true,
    ),
    CommunityPostItem(
      id: 'post_002',
      authorName: 'Anil Kumar',
      communityName: 'Cyberabad Cricket League',
      content: 'Tournament announcement: The Monsoon Cup 2026 registration is now open! 8 teams, knockout format, red leather ball. Ping the organizers to register your team before Friday.',
      imageUrl: 'https://images.unsplash.com/photo-1531415074968-036ba1b575da?w=800',
      likes: 45,
      comments: 19,
      createdAt: DateTime.now().subtract(const Duration(hours: 5)),
      isLiked: false,
    ),
    CommunityPostItem(
      id: 'post_003',
      authorName: 'Sneha Patel',
      communityName: 'Smashers Badminton Group',
      content: 'Any intermediate badminton players up for regular 7 AM practice sessions at Gachibowli Arena on weekdays?',
      likes: 14,
      comments: 4,
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
      isLiked: false,
    ),
  ];

  @override
  Future<List<CommunityItem>> getCommunities() async {
    try {
      final response = await apiClient.get('/communities');
      if (response.isSuccess && response.data != null) {
        final list = (response.data as List).map((e) => CommunityItem(
          id: e['id'],
          name: e['name'],
          description: e['description'] ?? '',
          sport: e['sport'] ?? 'Sports',
          memberCount: e['memberCount'] ?? 1,
        )).toList();
        if (list.isNotEmpty) return list;
      }
    } catch (_) {}
    return _communities;
  }

  @override
  Future<List<CommunityPostItem>> getFeedPosts() async {
    try {
      final response = await apiClient.get('/community-posts');
      if (response.isSuccess && response.data != null) {
        final list = (response.data as List).map((e) => CommunityPostItem(
          id: e['id'],
          authorName: e['authorName'] ?? 'Member',
          communityName: e['communityName'] ?? 'Community',
          content: e['content'] ?? '',
          imageUrl: e['imageUrl'],
          likes: e['likes'] ?? 0,
          comments: e['comments'] ?? 0,
          createdAt: DateTime.parse(e['createdAt']),
        )).toList();
        if (list.isNotEmpty) return list;
      }
    } catch (_) {}
    return _posts;
  }

  @override
  Future<bool> createPost(String content, {String? imageUrl, String communityName = 'Hyderabad Sports Club'}) async {
    final newPost = CommunityPostItem(
      id: 'post_${DateTime.now().millisecondsSinceEpoch}',
      authorName: 'You',
      communityName: communityName,
      content: content,
      imageUrl: imageUrl,
      likes: 0,
      comments: 0,
      createdAt: DateTime.now(),
      isLiked: false,
    );

    try {
      await apiClient.post('/community-posts', data: {
        'content': content,
        'imageUrl': imageUrl,
        'communityName': communityName,
      });
    } catch (_) {}

    _posts.insert(0, newPost);
    return true;
  }

  @override
  Future<bool> toggleLike(String postId) async {
    final index = _posts.indexWhere((p) => p.id == postId);
    if (index != -1) {
      final p = _posts[index];
      final newLiked = !p.isLiked;
      _posts[index] = CommunityPostItem(
        id: p.id,
        authorName: p.authorName,
        authorAvatar: p.authorAvatar,
        communityName: p.communityName,
        content: p.content,
        imageUrl: p.imageUrl,
        likes: newLiked ? p.likes + 1 : (p.likes > 0 ? p.likes - 1 : 0),
        comments: p.comments,
        createdAt: p.createdAt,
        isLiked: newLiked,
      );
      return true;
    }
    return false;
  }

  final Map<String, List<CommunityCommentItem>> _commentsMap = {
    'post_001': [
      CommunityCommentItem(
        id: 'comm_c1',
        postId: 'post_001',
        authorName: 'Suresh Raina',
        text: 'Count me in for Saturday! What time do we assemble?',
        createdAt: DateTime.now().subtract(const Duration(minutes: 45)),
      ),
      CommunityCommentItem(
        id: 'comm_c2',
        postId: 'post_001',
        authorName: 'Karthik V',
        text: 'I can join as goalkeeper or defender. Let me know!',
        createdAt: DateTime.now().subtract(const Duration(minutes: 20)),
      ),
    ],
    'post_002': [
      CommunityCommentItem(
        id: 'comm_c3',
        postId: 'post_002',
        authorName: 'Manish Pandey',
        text: 'Registered our team "Hitech Strikers" yesterday. Looking forward to the tournament!',
        createdAt: DateTime.now().subtract(const Duration(hours: 3)),
      ),
    ],
  };

  @override
  Future<List<CommunityCommentItem>> getComments(String postId) async {
    return _commentsMap[postId] ?? [];
  }

  @override
  Future<bool> addComment(String postId, String text, {String authorName = 'You'}) async {
    final comment = CommunityCommentItem(
      id: 'comm_c_${DateTime.now().millisecondsSinceEpoch}',
      postId: postId,
      authorName: authorName,
      text: text,
      createdAt: DateTime.now(),
    );
    _commentsMap.putIfAbsent(postId, () => []).add(comment);

    final pIndex = _posts.indexWhere((p) => p.id == postId);
    if (pIndex != -1) {
      final p = _posts[pIndex];
      _posts[pIndex] = CommunityPostItem(
        id: p.id,
        authorName: p.authorName,
        authorAvatar: p.authorAvatar,
        communityName: p.communityName,
        content: p.content,
        imageUrl: p.imageUrl,
        likes: p.likes,
        comments: p.comments + 1,
        createdAt: p.createdAt,
        isLiked: p.isLiked,
      );
    }
    return true;
  }

  @override
  Future<bool> joinCommunity(String communityId) async {
    final index = _communities.indexWhere((c) => c.id == communityId);
    if (index != -1) {
      final c = _communities[index];
      _communities[index] = CommunityItem(
        id: c.id,
        name: c.name,
        description: c.description,
        avatarUrl: c.avatarUrl,
        sport: c.sport,
        memberCount: c.memberCount + 1,
        isJoined: true,
      );
      return true;
    }
    return false;
  }
}

final communityRepositoryProvider = Provider<CommunityRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return CommunityRepositoryImpl(apiClient: apiClient);
});
