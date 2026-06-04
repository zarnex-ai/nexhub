import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'models.dart';
import 'supabase_service.dart';

// --- Auth Provider ---

class AuthState {
  final UserProfile? user;
  final bool isLoading;
  final String? errorMessage;
  final bool isSupabaseConfigured;

  AuthState({
    this.user,
    this.isLoading = false,
    this.errorMessage,
    required this.isSupabaseConfigured,
  });

  AuthState copyWith({
    UserProfile? user,
    bool? isLoading,
    String? errorMessage,
    bool? isSupabaseConfigured,
  }) {
    return AuthState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
      isSupabaseConfigured: isSupabaseConfigured ?? this.isSupabaseConfigured,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final SupabaseService _service = SupabaseService.instance;

  AuthNotifier() : super(AuthState(isSupabaseConfigured: SupabaseService.instance.isSupabaseConfigured)) {
    _init();
  }

  Future<void> _init() async {
    state = state.copyWith(isLoading: true);
    try {
      final user = await _service.getCurrentUserProfile();
      state = state.copyWith(user: user, isLoading: false);
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString(), isLoading: false);
    }
  }

  Future<bool> signIn(String email, String password) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final user = await _service.signIn(email: email, password: password);
      state = state.copyWith(user: user, isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString().replaceAll('Exception: ', ''), isLoading: false);
      return false;
    }
  }

  Future<bool> signUp(String email, String password, String username) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final user = await _service.signUp(email: email, password: password, username: username);
      state = state.copyWith(user: user, isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString().replaceAll('Exception: ', ''), isLoading: false);
      return false;
    }
  }

  Future<void> signOut() async {
    state = state.copyWith(isLoading: true);
    await _service.signOut();
    state = AuthState(user: null, isLoading: false, isSupabaseConfigured: _service.isSupabaseConfigured);
  }

  Future<bool> updateProfile({
    required String username,
    String? displayName,
    String? avatarUrl,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final user = await _service.updateProfile(
        username: username,
        displayName: displayName,
        avatarUrl: avatarUrl,
      );
      state = state.copyWith(user: user, isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString().replaceAll('Exception: ', ''), isLoading: false);
      return false;
    }
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});

// --- Channels Provider ---

class ChannelsNotifier extends StateNotifier<List<Channel>> {
  final SupabaseService _service = SupabaseService.instance;

  ChannelsNotifier() : super([]) {
    loadChannels();
  }

  Future<void> loadChannels() async {
    try {
      final list = await _service.fetchChannels();
      state = list;
    } catch (e) {
      print('Error loading channels: $e');
    }
  }

  Future<Channel?> createChannel(String name, String? description) async {
    try {
      final newChan = await _service.createChannel(name, description);
      await loadChannels();
      return newChan;
    } catch (e) {
      print('Error creating channel: $e');
      return null;
    }
  }

  Future<void> deleteChannel(String id) async {
    try {
      await _service.deleteChannel(id);
      await loadChannels();
    } catch (e) {
      print('Error deleting channel: $e');
    }
  }
}

final channelsProvider = StateNotifierProvider<ChannelsNotifier, List<Channel>>((ref) {
  return ChannelsNotifier();
});

// --- Users Provider (DM Sidebar list) ---

class UsersNotifier extends StateNotifier<List<UserProfile>> {
  final SupabaseService _service = SupabaseService.instance;

  UsersNotifier() : super([]) {
    loadUsers();
  }

  Future<void> loadUsers() async {
    try {
      final list = await _service.fetchUsers();
      state = list;
    } catch (e) {
      print('Error loading users: $e');
    }
  }
  Future<UserProfile?> inviteUserByCode(String inviteCode) async {
    try {
      final user = await _service.inviteUser(inviteCode);
      if (user != null) {
        // Only append to active list if not already present
        if (!state.any((u) => u.id == user.id)) {
          state = [...state, user];
        }
      }
      return user;
    } catch (e) {
      print('Error inviting user by code: $e');
      return null;
    }
  }
}

final usersProvider = StateNotifierProvider<UsersNotifier, List<UserProfile>>((ref) {
  return UsersNotifier();
});

// --- Active Channel Provider ---

final activeChannelIdProvider = StateProvider<String?>((ref) => 'c1'); 

// --- Messages State Management ---

class MessagesNotifier extends StateNotifier<List<Message>> {
  final SupabaseService _service = SupabaseService.instance;
  final String channelId;
  StreamSubscription? _subscription;

  MessagesNotifier(this.channelId) : super([]) {
    _loadMessages();
    _subscribe();
  }

  Future<void> _loadMessages() async {
    try {
      final msgs = await _service.fetchMessages(channelId);
      state = msgs;
    } catch (e) {
      print('Error fetching messages: $e');
    }
  }

  void _subscribe() {
    _subscription?.cancel();
    _subscription = _service.subscribeToMessages(channelId, (newMsg) {
      if (!state.any((m) => m.id == newMsg.id)) {
        state = [...state, newMsg];
      }
    });
  }

  Future<void> sendMessage(String content, {List<String> attachmentUrls = const []}) async {
    try {
      final currentUser = _service.mockCurrentUser ?? await _service.getCurrentUserProfile();
      final tempId = DateTime.now().millisecondsSinceEpoch;
      final tempMsg = Message(
        id: tempId,
        channelId: channelId,
        userId: currentUser?.id ?? 'system',
        content: content,
        createdAt: DateTime.now(),
        sender: currentUser,
      );
      state = [...state, tempMsg];

      final sentMsg = await _service.sendMessage(channelId, content, attachmentUrls: attachmentUrls);
      
      state = state.map((m) => m.id == tempId ? sentMsg : m).toList();
    } catch (e) {
      print('Error sending message: $e');
      _loadMessages(); 
    }
  }

  Future<void> toggleReaction(int messageId, String type) async {
    try {
      await _service.toggleReaction(messageId, type);
      _loadMessages();
    } catch (e) {
      print('Error toggling reaction: $e');
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}

final messagesProvider = StateNotifierProvider.family<MessagesNotifier, List<Message>, String>((ref, channelId) {
  return MessagesNotifier(channelId);
});

// --- Active Thread Message Provider ---

final activeThreadMessageProvider = StateProvider<Message?>((ref) => null);

// --- Thread Replies Provider ---

class ThreadRepliesNotifier extends StateNotifier<List<Message>> {
  final SupabaseService _service = SupabaseService.instance;
  final String channelId;
  final int parentId;

  ThreadRepliesNotifier({required this.channelId, required this.parentId}) : super([]) {
    _loadReplies();
  }

  Future<void> _loadReplies() async {
    try {
      final replies = await _service.fetchMessages(channelId, parentId: parentId);
      state = replies;
    } catch (e) {
      print('Error loading thread replies: $e');
    }
  }

  Future<void> sendReply(String content) async {
    try {
      final sentReply = await _service.sendMessage(channelId, content, parentId: parentId);
      state = [...state, sentReply];
    } catch (e) {
      print('Error sending thread reply: $e');
    }
  }
}

final threadRepliesProvider = StateNotifierProvider.family<ThreadRepliesNotifier, List<Message>, Map<String, dynamic>>((ref, params) {
  final channelId = params['channelId'] as String;
  final parentId = params['parentId'] as int;
  return ThreadRepliesNotifier(channelId: channelId, parentId: parentId);
});

// --- Code Bucket Provider ---

class CodeBucketNotifier extends StateNotifier<List<CodeSnippet>> {
  final SupabaseService _service = SupabaseService.instance;

  CodeBucketNotifier() : super([]) {
    loadSnippets();
  }

  Future<void> loadSnippets() async {
    try {
      final list = await _service.fetchSnippets();
      state = list;
    } catch (e) {
      print('Error loading snippets: $e');
    }
  }

  Future<CodeSnippet?> addSnippet({
    required String title,
    required String code,
    required String language,
  }) async {
    try {
      final snippet = await _service.createSnippet(
        title: title,
        code: code,
        language: language,
      );
      state = [snippet, ...state];
      return snippet;
    } catch (e) {
      print('Error creating snippet: $e');
      return null;
    }
  }

  Future<void> removeSnippet(String id) async {
    try {
      await _service.deleteSnippet(id);
      state = state.where((s) => s.id != id).toList();
    } catch (e) {
      print('Error deleting snippet: $e');
    }
  }
}

final codeBucketProvider = StateNotifierProvider<CodeBucketNotifier, List<CodeSnippet>>((ref) {
  return CodeBucketNotifier();
});
