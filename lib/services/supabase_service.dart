import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static SupabaseClient get client => Supabase.instance.client;
  static GoTrueClient get auth => client.auth;

  static String? get currentUserId => auth.currentUser?.id;
  static bool get isLoggedIn => auth.currentUser != null;

  /// Cached profile completion status (synced at startup & after profile setup)
  static bool _profileComplete = false;
  static bool get profileComplete => _profileComplete;

  /// Check and cache profile completion. Call at startup.
  static Future<void> checkProfileComplete() async {
    if (!isLoggedIn) {
      _profileComplete = false;
      return;
    }
    final profile = await getProfile();
    _profileComplete = profile != null && profile['municipality_id'] != null;
  }

  // Auth
  static Future<AuthResponse> signUp({
    required String email,
    required String password,
  }) {
    return auth.signUp(email: email, password: password);
  }

  static Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) {
    return auth.signInWithPassword(email: email, password: password);
  }

  static Future<void> signOut() => auth.signOut();

  static Future<AuthResponse> verifyOtp({
    required String email,
    required String token,
  }) {
    return auth.verifyOTP(email: email, token: token, type: OtpType.signup);
  }

  static Future<void> resendOtp({required String email}) {
    return auth.resend(type: OtpType.signup, email: email);
  }

  static Future<void> resetPassword({required String email}) {
    return auth.resetPasswordForEmail(email);
  }

  /// Get blocked users with profiles
  static Future<List<Map<String, dynamic>>> getBlockedUsers() async {
    final uid = currentUserId;
    if (uid == null) return [];
    final res = await client
        .from('blocks')
        .select('blocked_id, created_at, profiles!blocks_blocked_id_fkey(nickname)')
        .eq('blocker_id', uid)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(res);
  }

  // Profile
  static Future<Map<String, dynamic>?> getProfile() async {
    final uid = currentUserId;
    if (uid == null) return null;
    final res = await client
        .from('profiles')
        .select('*, municipalities(name, full_name)')
        .eq('id', uid)
        .maybeSingle();
    return res;
  }

  static Future<void> updateProfile({String? nickname}) async {
    final uid = currentUserId;
    if (uid == null) return;
    final updates = <String, dynamic>{};
    if (nickname != null) updates['nickname'] = nickname;
    await client.from('profiles').update(updates).eq('id', uid);
  }

  /// Complete profile setup after signup
  static Future<void> completeProfileSetup({
    required String municipalityId,
    required String nickname,
    required String verificationMethod,
    String? verifiedEmail,
  }) async {
    final uid = currentUserId;
    if (uid == null) return;
    final updates = <String, dynamic>{
      'municipality_id': municipalityId,
      'nickname': nickname,
      'verification_method': verificationMethod,
    };
    if (verificationMethod == 'email') {
      updates['is_verified'] = true;
      if (verifiedEmail != null) updates['verified_email'] = verifiedEmail;
    }
    await client.from('profiles').update(updates).eq('id', uid);
    _profileComplete = true;
  }

  /// Find municipality by email domain (for auto-detection)
  static Future<Map<String, dynamic>?> getMunicipalityByDomain(
      String domain) async {
    final res = await client
        .from('municipalities')
        .select()
        .eq('email_domain', domain)
        .maybeSingle();
    return res;
  }

  /// Get list of blocked user IDs
  static Future<List<String>> getBlockedUserIds() async {
    final uid = currentUserId;
    if (uid == null) return [];
    final res = await client
        .from('blocks')
        .select('blocked_id')
        .eq('blocker_id', uid);
    return List<Map<String, dynamic>>.from(res)
        .map((e) => e['blocked_id'] as String)
        .toList();
  }

  /// Upload image to post-images bucket
  static Future<String> uploadPostImage(File file) async {
    final uid = currentUserId;
    if (uid == null) throw Exception('Not logged in');
    final ext = file.path.split('.').last;
    final path = '$uid/${DateTime.now().millisecondsSinceEpoch}.$ext';
    await client.storage.from('post-images').upload(path, file);
    return client.storage.from('post-images').getPublicUrl(path);
  }

  // My posts / comments / bookmarks
  static Future<List<Map<String, dynamic>>> getMyPosts({
    int limit = 20,
    int offset = 0,
  }) async {
    final res = await client
        .from('posts')
        .select('*, municipalities(name)')
        .eq('author_id', currentUserId ?? '')
        .order('created_at', ascending: false)
        .range(offset, offset + limit - 1);
    return List<Map<String, dynamic>>.from(res);
  }

  static Future<List<Map<String, dynamic>>> getMyComments({
    int limit = 20,
    int offset = 0,
  }) async {
    final res = await client
        .from('comments')
        .select('*, posts(id, title)')
        .eq('author_id', currentUserId ?? '')
        .order('created_at', ascending: false)
        .range(offset, offset + limit - 1);
    return List<Map<String, dynamic>>.from(res);
  }

  static Future<List<Map<String, dynamic>>> getMyBookmarks({
    int limit = 20,
    int offset = 0,
  }) async {
    final res = await client
        .from('bookmarks')
        .select('*, posts(*, municipalities(name))')
        .eq('user_id', currentUserId ?? '')
        .order('created_at', ascending: false)
        .range(offset, offset + limit - 1);
    return List<Map<String, dynamic>>.from(res);
  }

  // Posts
  static Future<List<Map<String, dynamic>>> getFeed({
    required String municipalityId,
    String? tag,
    int limit = 20,
    int offset = 0,
  }) async {
    var query = client
        .from('posts')
        .select('*, municipalities(name)')
        .eq('municipality_id', municipalityId)
        .eq('is_blinded', false);
    if (tag != null) {
      query = query.eq('tag', tag);
    }
    final res = await query
        .order('created_at', ascending: false)
        .range(offset, offset + limit - 1);
    return List<Map<String, dynamic>>.from(res);
  }

  static Future<List<Map<String, dynamic>>> getHotPosts({
    int limit = 20,
    int offset = 0,
  }) async {
    final res = await client
        .from('posts')
        .select('*, municipalities(name)')
        .eq('is_blinded', false)
        .order('hot_score', ascending: false)
        .range(offset, offset + limit - 1);
    return List<Map<String, dynamic>>.from(res);
  }

  static Future<List<Map<String, dynamic>>> getLatestPosts({
    int limit = 20,
    int offset = 0,
  }) async {
    final res = await client
        .from('posts')
        .select('*, municipalities(name)')
        .eq('is_blinded', false)
        .order('created_at', ascending: false)
        .range(offset, offset + limit - 1);
    return List<Map<String, dynamic>>.from(res);
  }

  static Future<Map<String, dynamic>?> getPost(String postId) async {
    final res = await client.rpc('get_post_detail', params: {
      'p_post_id': postId,
    });
    if (res == null) return null;
    return Map<String, dynamic>.from(res as Map);
  }

  /// Increment view count. Call once on initial page load only.
  static Future<void> incrementViewCount(String postId) async {
    await client.rpc('view_post', params: {'p_post_id': postId});
  }

  static Future<Map<String, dynamic>> createPost({
    required String municipalityId,
    required String tag,
    required String title,
    required String content,
    List<String>? imageUrls,
  }) async {
    final res = await client.from('posts').insert({
      'author_id': currentUserId,
      'municipality_id': municipalityId,
      'tag': tag,
      'title': title,
      'content': content,
      'image_urls': imageUrls ?? [],
    }).select().single();
    return res;
  }

  static Future<void> updatePost({
    required String postId,
    String? title,
    String? content,
    String? tag,
  }) async {
    final updates = <String, dynamic>{};
    if (title != null) updates['title'] = title;
    if (content != null) updates['content'] = content;
    if (tag != null) updates['tag'] = tag;
    await client.from('posts').update(updates).eq('id', postId);
  }

  static Future<void> deletePost(String postId) async {
    await client.from('posts').delete().eq('id', postId);
  }

  // Comments
  static Future<List<Map<String, dynamic>>> getComments(String postId) async {
    final res = await client
        .from('comments')
        .select()
        .eq('post_id', postId)
        .eq('is_blinded', false)
        .order('created_at');
    return List<Map<String, dynamic>>.from(res);
  }

  static Future<Map<String, dynamic>> createComment({
    required String postId,
    required String content,
    String? parentId,
  }) async {
    final data = <String, dynamic>{
      'post_id': postId,
      'author_id': currentUserId,
      'content': content,
    };
    if (parentId != null) data['parent_id'] = parentId;
    final res = await client.from('comments').insert(data).select().single();
    return res;
  }

  static Future<void> deleteComment(String commentId) async {
    await client.from('comments').delete().eq('id', commentId);
  }

  // Likes (RPC: atomic toggle, 1 round-trip)
  static Future<bool> toggleLike({
    required String targetType,
    required String targetId,
  }) async {
    final res = await client.rpc('toggle_like', params: {
      'p_target_type': targetType,
      'p_target_id': targetId,
    });
    return (res as Map)['liked'] as bool;
  }

  // Bookmarks (RPC: atomic toggle, 1 round-trip)
  static Future<bool> toggleBookmark(String postId) async {
    final res = await client.rpc('toggle_bookmark', params: {
      'p_post_id': postId,
    });
    return (res as Map)['bookmarked'] as bool;
  }

  // Reports
  static Future<void> report({
    required String targetType,
    required String targetId,
    required String reason,
    String? detail,
  }) async {
    await client.from('reports').insert({
      'reporter_id': currentUserId,
      'target_type': targetType,
      'target_id': targetId,
      'reason': reason,
      'detail': detail,
    });
  }

  // Blocks
  static Future<void> blockUser(String blockedId) async {
    await client.from('blocks').insert({
      'blocker_id': currentUserId,
      'blocked_id': blockedId,
    });
  }

  static Future<void> unblockUser(String blockedId) async {
    await client
        .from('blocks')
        .delete()
        .eq('blocker_id', currentUserId ?? '')
        .eq('blocked_id', blockedId);
  }

  // Municipalities
  static Future<List<Map<String, dynamic>>> getMunicipalities({
    int? level,
    String? parentId,
  }) async {
    var query = client.from('municipalities').select();
    if (level != null) query = query.eq('level', level);
    if (parentId != null) query = query.eq('parent_id', parentId);
    final res = await query.order('full_name');
    return List<Map<String, dynamic>>.from(res);
  }

  // Search
  static Future<List<Map<String, dynamic>>> searchPosts({
    required String query,
    String? municipalityId,
    int limit = 20,
    int offset = 0,
  }) async {
    final res = await client.rpc('search_posts', params: {
      'p_query': query,
      'p_municipality_id': municipalityId,
      'p_limit': limit,
      'p_offset': offset,
    });
    return List<Map<String, dynamic>>.from(res);
  }

  // Notifications
  static Future<List<Map<String, dynamic>>> getNotifications({
    int limit = 20,
    int offset = 0,
  }) async {
    final res = await client
        .from('notifications')
        .select()
        .eq('user_id', currentUserId ?? '')
        .order('created_at', ascending: false)
        .range(offset, offset + limit - 1);
    return List<Map<String, dynamic>>.from(res);
  }

  static Future<void> markNotificationRead(String notificationId) async {
    await client
        .from('notifications')
        .update({'is_read': true}).eq('id', notificationId);
  }

  // Nickname validation (banned words + duplicate check)
  static Future<String?> validateNickname(String nickname) async {
    final lower = nickname.toLowerCase();
    final banned = await client
        .from('banned_words')
        .select('word')
        .eq('category', 'other');
    final words = List<Map<String, dynamic>>.from(banned);
    if (words.any((w) => lower.contains((w['word'] as String).toLowerCase()))) {
      return '사용할 수 없는 닉네임입니다';
    }
    final existing = await client
        .from('profiles')
        .select('id')
        .eq('nickname', nickname)
        .neq('id', currentUserId ?? '')
        .maybeSingle();
    if (existing != null) {
      return '이미 사용 중인 닉네임입니다';
    }
    return null;
  }

  // FCM token
  static Future<void> saveFcmToken(String token) async {
    final uid = currentUserId;
    if (uid == null) return;
    await client.from('profiles').update({'fcm_token': token}).eq('id', uid);
  }

  // Account deletion (anonymize)
  static Future<void> deleteAccount() async {
    await client.rpc('delete_my_account');
    await auth.signOut();
  }
}
