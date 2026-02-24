import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static SupabaseClient get client => Supabase.instance.client;
  static GoTrueClient get auth => client.auth;

  static String? get currentUserId => auth.currentUser?.id;
  static bool get isLoggedIn => auth.currentUser != null;

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

  static Future<void> verifyOtp({
    required String email,
    required String token,
  }) {
    return auth.verifyOTP(email: email, token: token, type: OtpType.email);
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
    // Increment view count via RPC
    await client.rpc('view_post', params: {'p_post_id': postId});
    final res = await client
        .from('posts')
        .select('*, municipalities(name)')
        .eq('id', postId)
        .maybeSingle();
    return res;
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

  // Likes
  static Future<void> toggleLike({
    required String targetType,
    required String targetId,
  }) async {
    final existing = await client
        .from('likes')
        .select('id')
        .eq('user_id', currentUserId!)
        .eq('target_type', targetType)
        .eq('target_id', targetId)
        .maybeSingle();
    if (existing != null) {
      await client.from('likes').delete().eq('id', existing['id']);
    } else {
      await client.from('likes').insert({
        'user_id': currentUserId,
        'target_type': targetType,
        'target_id': targetId,
      });
    }
  }

  // Bookmarks
  static Future<void> toggleBookmark(String postId) async {
    final existing = await client
        .from('bookmarks')
        .select('id')
        .eq('user_id', currentUserId!)
        .eq('post_id', postId)
        .maybeSingle();
    if (existing != null) {
      await client.from('bookmarks').delete().eq('id', existing['id']);
    } else {
      await client.from('bookmarks').insert({
        'user_id': currentUserId,
        'post_id': postId,
      });
    }
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
        .eq('blocker_id', currentUserId!)
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
        .eq('user_id', currentUserId!)
        .order('created_at', ascending: false)
        .range(offset, offset + limit - 1);
    return List<Map<String, dynamic>>.from(res);
  }

  static Future<void> markNotificationRead(String notificationId) async {
    await client
        .from('notifications')
        .update({'is_read': true}).eq('id', notificationId);
  }

  // Account deletion (anonymize)
  static Future<void> deleteAccount() async {
    await client.rpc('delete_my_account');
    await auth.signOut();
  }
}
