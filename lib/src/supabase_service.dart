import 'dart:async';
import 'dart:math';
import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'models.dart';

class SupabaseService {
  static final SupabaseService instance = SupabaseService._internal();
  SupabaseService._internal();

  static const _supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://ztjwuvitissdvgmjbsqk.supabase.co',
  );

  bool get isSupabaseConfigured {
    return _supabaseUrl.isNotEmpty &&
        !_supabaseUrl.contains('your-project-ref');
  }

  SupabaseClient get _client => Supabase.instance.client;

  // --- Auth API ---

  UserProfile? get mockCurrentUser => _mockCurrentUser;

  Future<UserProfile?> getCurrentUserProfile() async {
    if (!isSupabaseConfigured) {
      return _mockCurrentUser;
    }

    final user = _client.auth.currentUser;
    if (user == null) return null;

    try {
      final data = await _client
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();
      if (data != null) {
        return UserProfile.fromJson(data);
      }
      // Create profile if not exists
      final invite = _generate5CharId();
      final newProfile = {
        'id': user.id,
        'username': user.email?.split('@').first ?? 'user',
        'display_name': user.userMetadata?['display_name'] as String?,
        'avatar_url': user.userMetadata?['avatar_url'] as String?,
        'invite_code': invite,
      };
      await _client.from('profiles').insert(newProfile);
      return UserProfile.fromJson(newProfile);
    } catch (e) {
      print('Error getting profile: $e');
      return UserProfile(
        id: user.id,
        username: user.email?.split('@').first ?? 'user',
      );
    }
  }

  String _generate5CharId() {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final rand = Random();
    return List.generate(5, (index) => chars[rand.nextInt(chars.length)])
        .join()
        .toUpperCase();
  }

  Future<UserProfile> signIn(
      {required String email, required String password}) async {
    if (!isSupabaseConfigured) {
      await Future.delayed(const Duration(milliseconds: 600));
      if (email == 'admin@nexhub.com' && password == 'admin') {
        _mockCurrentUser = UserProfile(
          id: 'mock-admin-id',
          username: 'admin',
          displayName: 'Admin User',
          avatarUrl: 'https://api.dicebear.com/7.x/bottts/svg?seed=admin',
        );
        return _mockCurrentUser!;
      } else {
        // Create dynamic user
        final username = email.split('@').first;
        _mockCurrentUser = UserProfile(
          id: 'mock-user-${DateTime.now().millisecondsSinceEpoch}',
          username: username,
          displayName: username[0].toUpperCase() + username.substring(1),
          avatarUrl:
              'https://api.dicebear.com/7.x/adventurer/svg?seed=$username',
        );
        return _mockCurrentUser!;
      }
    }

    final response = await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
    if (response.user == null) {
      throw Exception('Login failed: User is null');
    }
    final profile = await getCurrentUserProfile();
    return profile ?? UserProfile(id: response.user!.id, username: 'anonymous');
  }

  Future<UserProfile> signUp(
      {required String email,
      required String password,
      required String username}) async {
    if (!isSupabaseConfigured) {
      await Future.delayed(const Duration(milliseconds: 600));
      _mockCurrentUser = UserProfile(
        id: 'mock-user-${DateTime.now().millisecondsSinceEpoch}',
        username: username,
        displayName: username,
        avatarUrl: 'https://api.dicebear.com/7.x/adventurer/svg?seed=$username',
      );
      return _mockCurrentUser!;
    }

    final response = await _client.auth.signUp(
      email: email,
      password: password,
      data: {'display_name': username},
    );

    if (response.user == null) {
      throw Exception('Signup failed');
    }

    final invite = _generate5CharId();
    final newProfile = UserProfile(
      id: response.user!.id,
      username: username,
      displayName: username,
      avatarUrl: 'https://api.dicebear.com/7.x/adventurer/svg?seed=$username',
      inviteCode: invite,
    );

    await _client.from('profiles').insert(newProfile.toJson());
    return newProfile;
  }

  Future<void> signOut() async {
    if (isSupabaseConfigured) {
      await _client.auth.signOut();
    }
    _mockCurrentUser = null;
  }

  Future<UserProfile> updateProfile({
    required String username,
    String? displayName,
    String? avatarUrl,
  }) async {
    final current = await getCurrentUserProfile();
    if (current == null) throw Exception('No user logged in');

    final updated = UserProfile(
      id: current.id,
      username: username,
      displayName: displayName,
      avatarUrl: avatarUrl,
      inviteCode: current.inviteCode,
    );

    if (!isSupabaseConfigured) {
      _mockCurrentUser = updated;
      return updated;
    }

    await _client.from('profiles').update({
      'username': username,
      'display_name': displayName,
      'avatar_url': avatarUrl,
    }).eq('id', current.id);

    return updated;
  }

  // --- Users API (For Dynamic DM list) ---

  Future<List<UserProfile>> fetchUsers() async {
    if (!isSupabaseConfigured) {
      return [];
    }

    try {
      final List<dynamic> data =
          await _client.from('profiles').select().order('username');
      return data.map((json) => UserProfile.fromJson(json)).toList();
    } catch (e) {
      print('Error fetching users: $e');
      return [];
    }
  }

  Future<UserProfile?> inviteUser(String inviteCode) async {
    if (!isSupabaseConfigured) {
      // In local mode, return a dummy user matching the invite code prefix
      await Future.delayed(const Duration(milliseconds: 300));
      return UserProfile(
        id: 'mock-user-$inviteCode',
        username: 'invited_$inviteCode'.toLowerCase(),
        displayName: 'Invited User $inviteCode',
        avatarUrl:
            'https://api.dicebear.com/7.x/adventurer/svg?seed=$inviteCode',
        inviteCode: inviteCode.toUpperCase(),
      );
    }

    try {
      final data = await _client
          .from('profiles')
          .select()
          .eq('invite_code', inviteCode.toUpperCase())
          .maybeSingle();
      if (data == null) return null;
      return UserProfile.fromJson(data);
    } catch (e) {
      print('Error inviting user: $e');
      return null;
    }
  }

  // --- Channels API ---

  Future<List<Channel>> fetchChannels() async {
    if (!isSupabaseConfigured) {
      await Future.delayed(const Duration(milliseconds: 300));
      return _mockChannels;
    }

    final List<dynamic> data =
        await _client.from('channels').select().order('name', ascending: true);
    return data.map((json) => Channel.fromJson(json)).toList();
  }

  Future<Channel> createChannel(String name, String? description) async {
    final cleanName = name.trim().toLowerCase().replaceAll(' ', '-');
    final currentUser = await getCurrentUserProfile();
    final ownerId = currentUser?.id ?? 'system';

    if (!isSupabaseConfigured) {
      final newChan = Channel(
        id: 'chan-${DateTime.now().millisecondsSinceEpoch}',
        name: cleanName,
        description: description,
        ownerId: ownerId,
        createdAt: DateTime.now(),
      );
      _mockChannels.add(newChan);
      return newChan;
    }

    final data = await _client
        .from('channels')
        .insert({
          'name': cleanName,
          'description': description,
          'owner_id': ownerId,
        })
        .select()
        .single();

    return Channel.fromJson(data);
  }

  Future<void> deleteChannel(String id) async {
    if (!isSupabaseConfigured) {
      _mockChannels.removeWhere((c) => c.id == id);
      return;
    }
    await _client.from('channels').delete().eq('id', id);
  }

  // --- Messages & Chat API ---

  Future<List<Message>> fetchMessages(String channelId, {int? parentId}) async {
    if (!isSupabaseConfigured) {
      await Future.delayed(const Duration(milliseconds: 200));
      var msgs = _mockMessages.where((m) => m.channelId == channelId).toList();
      if (parentId != null) {
        msgs = msgs.where((m) => m.parentId == parentId).toList();
      } else {
        msgs = msgs.where((m) => m.parentId == null).toList();
      }
      msgs.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      return msgs;
    }

    var query = _client.from('messages').select('*, profiles(*)');
    query = query.eq('channel_id', channelId);

    if (parentId != null) {
      query = query.eq('parent_id', parentId);
    } else {
      query = query.isFilter('parent_id', null);
    }

    final List<dynamic> data = await query.order('created_at', ascending: true);
    return data.map((json) => Message.fromJson(json)).toList();
  }

  Future<Message> sendMessage(String channelId, String content,
      {int? parentId, List<String> attachmentUrls = const []}) async {
    final profile = await getCurrentUserProfile();
    final userId = profile?.id ?? 'system';

    if (!isSupabaseConfigured) {
      final newMsg = Message(
        id: _mockMessages.length + 1,
        channelId: channelId,
        userId: userId,
        content: content,
        createdAt: DateTime.now(),
        sender: profile,
        parentId: parentId,
      );
      _mockMessages.add(newMsg);

      if (parentId == null &&
          (content.toLowerCase().contains('hello') ||
              content.toLowerCase().contains('help'))) {
        _triggerMockReply(channelId, content);
      }

      return newMsg;
    }

    final msgData = await _client
        .from('messages')
        .insert({
          'channel_id': channelId,
          'user_id': userId,
          'content': content,
          'parent_id': parentId,
        })
        .select('*, profiles(*)')
        .single();

    final message = Message.fromJson(msgData);

    for (final url in attachmentUrls) {
      await _client.from('attachments').insert({
        'message_id': message.id,
        'url': url,
        'mime_type': _getMimeType(url),
      });
    }

    return message;
  }

  // --- Realtime Streams ---

  StreamSubscription subscribeToMessages(
      String channelId, Function(Message) onNewMessage) {
    if (!isSupabaseConfigured) {
      return _mockMessageStreamController.stream.listen((msg) {
        if (msg.channelId == channelId) {
          onNewMessage(msg);
        }
      });
    }

    final channel = _client.channel('public:messages:chan-$channelId');

    channel
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'messages',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'channel_id',
            value: channelId,
          ),
          callback: (payload) async {
            if (payload.eventType == PostgresChangeEvent.insert) {
              final record = payload.newRecord;
              final senderData = await _client
                  .from('profiles')
                  .select()
                  .eq('id', record['user_id'])
                  .maybeSingle();
              final sender =
                  senderData != null ? UserProfile.fromJson(senderData) : null;
              final msg = Message.fromJson(record, sender: sender);
              onNewMessage(msg);
            }
          },
        )
        .subscribe();

    return StreamSubscriptionWrapper(channel);
  }

  // --- Reactions API ---

  Future<void> toggleReaction(int messageId, String type) async {
    final profile = await getCurrentUserProfile();
    final userId = profile?.id ?? 'system';

    if (!isSupabaseConfigured) {
      final idx = _mockMessages.indexWhere((m) => m.id == messageId);
      if (idx != -1) {
        final msg = _mockMessages[idx];
        final existingIdx = msg.reactions
            .indexWhere((r) => r.userId == userId && r.type == type);
        final newReactions = List<Reaction>.from(msg.reactions);
        if (existingIdx != -1) {
          newReactions.removeAt(existingIdx);
        } else {
          newReactions.add(Reaction(
            id: 'react-${DateTime.now().millisecondsSinceEpoch}',
            messageId: messageId,
            userId: userId,
            type: type,
          ));
        }
        _mockMessages[idx] = msg.copyWith(reactions: newReactions);
      }
      return;
    }

    final existing = await _client
        .from('reactions')
        .select()
        .eq('message_id', messageId)
        .eq('user_id', userId)
        .eq('type', type)
        .maybeSingle();

    if (existing != null) {
      await _client.from('reactions').delete().eq('id', existing['id']);
    } else {
      await _client.from('reactions').insert({
        'message_id': messageId,
        'user_id': userId,
        'type': type,
      });
    }
  }

  // --- SQL Executor RPC API ---

  Future<Map<String, dynamic>> executeSql(String sql) async {
    if (!isSupabaseConfigured) {
      await Future.delayed(const Duration(milliseconds: 400));
      return _runMockSql(sql);
    }

    try {
      final response = await _client.rpc('run_sql', params: {'p_sql': sql});
      if (response is Map) {
        return Map<String, dynamic>.from(response);
      }
      return {'status': 'ok', 'data': response};
    } catch (e) {
      return {'status': 'error', 'message': e.toString()};
    }
  }

  // --- Code Snippets API (Code Bucket) ---

  Future<List<CodeSnippet>> fetchSnippets() async {
    if (!isSupabaseConfigured) {
      await Future.delayed(const Duration(milliseconds: 300));
      return List<CodeSnippet>.from(_mockSnippets);
    }

    final List<dynamic> data = await _client
        .from('code_snippets')
        .select()
        .order('created_at', ascending: false);
    return data.map((json) => CodeSnippet.fromJson(json)).toList();
  }

  Future<CodeSnippet> createSnippet({
    required String title,
    required String code,
    required String language,
  }) async {
    final profile = await getCurrentUserProfile();
    final userId = profile?.id ?? 'system';

    if (!isSupabaseConfigured) {
      final snippet = CodeSnippet(
        id: 'snip-${DateTime.now().millisecondsSinceEpoch}',
        title: title,
        code: code,
        language: language,
        userId: userId,
        createdAt: DateTime.now(),
      );
      _mockSnippets.insert(0, snippet);
      return snippet;
    }

    final data = await _client
        .from('code_snippets')
        .insert({
          'title': title,
          'code': code,
          'language': language,
          'user_id': userId,
        })
        .select()
        .single();

    return CodeSnippet.fromJson(data);
  }

  Future<void> deleteSnippet(String id) async {
    if (!isSupabaseConfigured) {
      _mockSnippets.removeWhere((s) => s.id == id);
      return;
    }

    await _client.from('code_snippets').delete().eq('id', id);
  }

  // --- Storage Helper ---

  Future<String> uploadFile(
      String path, List<int> bytes, String fileName) async {
    if (!isSupabaseConfigured) {
      await Future.delayed(const Duration(milliseconds: 800));
      return 'https://images.unsplash.com/photo-1579202673506-ca3ce28943ef?w=400';
    }

    final fileExtension = fileName.split('.').last;
    final uniqueName =
        '${DateTime.now().millisecondsSinceEpoch}.$fileExtension';

    await _client.storage
        .from('attachments')
        .uploadBinary(uniqueName, Uint8List.fromList(bytes));

    return _client.storage.from('attachments').getPublicUrl(uniqueName);
  }

  String? _getMimeType(String url) {
    if (url.contains('.png')) return 'image/png';
    if (url.contains('.jpg') || url.contains('.jpeg')) return 'image/jpeg';
    if (url.contains('.pdf')) return 'application/pdf';
    return null;
  }

  // --- Mock Database / Demo Data ---

  UserProfile? _mockCurrentUser;
  final StreamController<Message> _mockMessageStreamController =
      StreamController<Message>.broadcast();

  final List<CodeSnippet> _mockSnippets = [
    CodeSnippet(
      id: 'snip-1',
      title: 'Flutter Hero Animation',
      code: '''class HeroPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Hero(
          tag: 'hero-avatar',
          child: CircleAvatar(radius: 60),
        ),
      ),
    );
  }
}''',
      language: 'Dart',
      userId: 'user-alice',
      createdAt: DateTime.now().subtract(const Duration(hours: 6)),
    ),
    CodeSnippet(
      id: 'snip-2',
      title: 'Python FastAPI endpoint',
      code: '''from fastapi import FastAPI

app = FastAPI()

@app.get("/items/{item_id}")
async def read_item(item_id: int, q: str | None = None):
    return {"item_id": item_id, "q": q}''',
      language: 'Python',
      userId: 'user-bob',
      createdAt: DateTime.now().subtract(const Duration(hours: 3)),
    ),
    CodeSnippet(
      id: 'snip-3',
      title: 'React useEffect cleanup',
      code: '''useEffect(() => {
  const controller = new AbortController();
  fetch("/api/data", { signal: controller.signal })
    .then(res => res.json())
    .then(setData);

  return () => controller.abort();
}, []);''',
      language: 'JavaScript',
      userId: 'user-alice',
      createdAt: DateTime.now().subtract(const Duration(hours: 1)),
    ),
    CodeSnippet(
      id: 'snip-4',
      title: 'Supabase RLS Policy',
      code: '''CREATE POLICY "Users can view own data"
  ON public.profiles
  FOR SELECT
  USING (auth.uid() = id);''',
      language: 'SQL',
      userId: 'bot-1',
      createdAt: DateTime.now().subtract(const Duration(minutes: 30)),
    ),
  ];

  final List<Channel> _mockChannels = [
    Channel(
        id: 'c1',
        name: 'general',
        description: 'General announcements and gossip',
        ownerId: 'system'),
    Channel(
        id: 'c2',
        name: 'random',
        description: 'Random posts, memes, and fun stuff',
        ownerId: 'system'),
    Channel(
        id: 'c3',
        name: 'announcements',
        description: 'Important company bulletins',
        ownerId: 'system'),
    Channel(
        id: 'c4',
        name: 'tech-talk',
        description: 'Coding discussions, git issues, technology releases',
        ownerId: 'system'),
  ];

  late final List<Message> _mockMessages = [
    Message(
      id: 1,
      channelId: 'c1',
      userId: 'bot-1',
      content:
          'Welcome to **NexHub**! 🚀 This is a Slack-level workspace app designed in Flutter.',
      createdAt: DateTime.now().subtract(const Duration(hours: 4)),
      sender: UserProfile(
          id: 'bot-1',
          username: 'nexbot',
          displayName: 'NexHub Bot',
          avatarUrl: 'https://api.dicebear.com/7.x/bottts/svg?seed=nexbot'),
    ),
    Message(
      id: 2,
      channelId: 'c1',
      userId: 'user-alice',
      content:
          'Wow, the styling is so beautiful! The glassmorphism card effect feels so premium.',
      createdAt: DateTime.now().subtract(const Duration(hours: 3)),
      sender: UserProfile(
          id: 'user-alice',
          username: 'alice',
          displayName: 'Alice Johnson',
          avatarUrl: 'https://api.dicebear.com/7.x/avataaars/svg?seed=alice'),
      reactions: [
        Reaction(id: 'r1', messageId: 2, userId: 'user-bob', type: '👍'),
        Reaction(id: 'r2', messageId: 2, userId: 'bot-1', type: '🔥'),
      ],
    ),
    Message(
      id: 3,
      channelId: 'c1',
      userId: 'user-bob',
      content: 'Does it support database queries from the integrated editor?',
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
      sender: UserProfile(
          id: 'user-bob',
          username: 'bob',
          displayName: 'Bob Smith',
          avatarUrl: 'https://api.dicebear.com/7.x/avataaars/svg?seed=bob'),
    ),
    Message(
      id: 4,
      channelId: 'c1',
      userId: 'bot-1',
      content:
          'Yes! Click the SQL Editor in the sidebar to execute PostgreSQL commands directly into your Supabase database.',
      createdAt: DateTime.now().subtract(const Duration(hours: 1)),
      sender: UserProfile(
          id: 'bot-1',
          username: 'nexbot',
          displayName: 'NexHub Bot',
          avatarUrl: 'https://api.dicebear.com/7.x/bottts/svg?seed=nexbot'),
    ),
  ];

  void _triggerMockReply(String channelId, String userMessage) {
    Timer(const Duration(seconds: 1), () {
      final reply = Message(
        id: _mockMessages.length + 1,
        channelId: channelId,
        userId: 'bot-1',
        content:
            'Thanks for sending: "$userMessage"! I am here to help you build the best web experience.',
        createdAt: DateTime.now(),
        sender: UserProfile(
            id: 'bot-1',
            username: 'nexbot',
            displayName: 'NexHub Bot',
            avatarUrl: 'https://api.dicebear.com/7.x/bottts/svg?seed=nexbot'),
      );
      _mockMessages.add(reply);
      _mockMessageStreamController.add(reply);
    });
  }

  Map<String, dynamic> _runMockSql(String sql) {
    final cleanSql = sql.trim().toUpperCase();
    if (cleanSql.startsWith('SELECT')) {
      if (cleanSql.contains('PROFILES')) {
        return {
          'status': 'ok',
          'data': [
            {
              'id': 'mock-admin-id',
              'username': 'admin',
              'display_name': 'Admin User',
              'avatar_url': 'https://api.dicebear.com/7.x/bottts/svg?seed=admin'
            },
            {
              'id': 'user-alice',
              'username': 'alice',
              'display_name': 'Alice Johnson',
              'avatar_url':
                  'https://api.dicebear.com/7.x/avataaars/svg?seed=alice'
            },
            {
              'id': 'user-bob',
              'username': 'bob',
              'display_name': 'Bob Smith',
              'avatar_url':
                  'https://api.dicebear.com/7.x/avataaars/svg?seed=bob'
            }
          ]
        };
      }
      if (cleanSql.contains('CHANNELS')) {
        return {
          'status': 'ok',
          'data': _mockChannels.map((c) => c.toJson()).toList()
        };
      }
      return {
        'status': 'ok',
        'data': [
          {
            'result': 'Postgres Mock Engine Running',
            'timestamp': DateTime.now().toIso8601String()
          }
        ]
      };
    }
    if (cleanSql.startsWith('CREATE TABLE')) {
      return {
        'status': 'ok',
        'message': 'Table created successfully (Mock Engine)'
      };
    }
    if (cleanSql.startsWith('INSERT')) {
      return {
        'status': 'ok',
        'message': '1 row inserted successfully (Mock Engine)'
      };
    }
    return {
      'status': 'ok',
      'message': 'Command executed successfully (Mock Engine)'
    };
  }
}

class StreamSubscriptionWrapper implements StreamSubscription<Message> {
  final RealtimeChannel channel;

  StreamSubscriptionWrapper(this.channel);

  @override
  Future<void> cancel() async {
    await Supabase.instance.client.removeChannel(channel);
  }

  @override
  void onData(void Function(Message data)? handleData) {}

  @override
  void onError(Function? handleError) {}

  @override
  void onDone(void Function()? handleDone) {}

  @override
  bool get isPaused => false;

  @override
  void pause([Future<void>? resumeSignal]) {}

  @override
  void resume() {}

  @override
  Future<E> asFuture<E>([E? futureValue]) => Future.value(futureValue);
}
