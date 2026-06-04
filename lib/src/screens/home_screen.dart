import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import '../providers.dart';
import '../models.dart';
import 'code_bucket_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _chatScrollController = ScrollController();
  
  bool _showEmojiPicker = false;
  bool _isCodeBucketActive = false;
  String? _selectedDmUser; 

  @override
  void dispose() {
    _messageController.dispose();
    _chatScrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_chatScrollController.hasClients) {
        _chatScrollController.animateTo(
          _chatScrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _sendMessage(String channelId) {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    ref.read(messagesProvider(channelId).notifier).sendMessage(text);
    _messageController.clear();
    setState(() {
      _showEmojiPicker = false;
    });
    _scrollToBottom();
  }

  void _showCreateChannelDialog() {
    final nameController = TextEditingController();
    final descController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Create a Channel', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Channel Name',
                hintText: 'e.g. marketing-updates',
                prefixText: '# ',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descController,
              decoration: const InputDecoration(
                labelText: 'Description (Optional)',
                hintText: 'What is this channel about?',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final name = nameController.text.trim();
              if (name.isNotEmpty) {
                ref.read(channelsProvider.notifier).createChannel(name, descController.text.trim());
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurpleAccent,
              foregroundColor: Colors.white,
            ),
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final authState = ref.watch(authProvider);
    final channels = ref.watch(channelsProvider);
    final users = ref.watch(usersProvider);
    final activeChannelId = ref.watch(activeChannelIdProvider);
    final activeThreadMsg = ref.watch(activeThreadMessageProvider);

    // Auto-select first channel when loaded
    if (activeChannelId == null && channels.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(activeChannelIdProvider.notifier).state = channels.first.id;
      });
    }

    if (activeChannelId != null) {
      ref.listen<List<Message>>(messagesProvider(activeChannelId), (prev, next) {
        if (prev == null || prev.length < next.length) {
          _scrollToBottom();
        }
      });
    }

    return Scaffold(
      body: Row(
        children: [
          // Sidebar Panel
          Container(
            width: 260,
            color: isDark ? const Color(0xFF161622) : const Color(0xFF3F0E40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Workspace Header
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: isDark ? Colors.grey[850]! : Colors.white.withOpacity(0.1),
                        width: 1,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.hub_rounded, color: Colors.white, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'NexHub Space',
                              style: GoogleFonts.outfit(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Row(
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    color: Colors.green,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  authState.user?.readableName ?? 'Online',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: Colors.white70,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Channels & DMs Navigation
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'CHANNELS',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.white60,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.add, color: Colors.white60, size: 18),
                              onPressed: _showCreateChannelDialog,
                              constraints: const BoxConstraints(),
                              padding: EdgeInsets.zero,
                            ),
                          ],
                        ),
                      ),

                      // List Channels
                      ...channels.map((chan) {
                        final isSelected = activeChannelId == chan.id && !_isCodeBucketActive && _selectedDmUser == null;
                        return _sidebarTile(
                          label: chan.name,
                          prefix: '# ',
                          isActive: isSelected,
                          onTap: () {
                            setState(() {
                              _isCodeBucketActive = false;
                              _selectedDmUser = null;
                              ref.read(activeChannelIdProvider.notifier).state = chan.id;
                            });
                          },
                          onDelete: chan.name == 'general' ? null : () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text('Delete Channel'),
                                content: Text('Are you sure you want to delete #${chan.name}?'),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx, false),
                                    child: const Text('Cancel'),
                                  ),
                                  ElevatedButton(
                                    onPressed: () => Navigator.pop(ctx, true),
                                    style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                                    child: const Text('Delete'),
                                  ),
                                ],
                              ),
                            );
                            if (confirm == true) {
                              if (activeChannelId == chan.id) {
                                ref.read(activeChannelIdProvider.notifier).state = channels.firstWhere((c) => c.id != chan.id, orElse: () => chan).id;
                              }
                              await ref.read(channelsProvider.notifier).deleteChannel(chan.id);
                            }
                          },
                        );
                      }),

                      const SizedBox(height: 16),

                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'DIRECT MESSAGES',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.white60,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.person_add_alt_1_rounded, color: Colors.white60, size: 18),
                              onPressed: () {
                                final codeCtrl = TextEditingController();
                                showDialog(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    title: const Text('Add User by Invite ID'),
                                    content: TextField(
                                      controller: codeCtrl,
                                      decoration: const InputDecoration(
                                        hintText: 'Enter 5-character ID (e.g. A1B2C)',
                                        labelText: 'Invite ID',
                                      ),
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(ctx),
                                        child: const Text('Cancel'),
                                      ),
                                      ElevatedButton(
                                        onPressed: () async {
                                          final code = codeCtrl.text.trim();
                                          if (code.isNotEmpty) {
                                            final invited = await ref.read(usersProvider.notifier).inviteUserByCode(code);
                                            if (ctx.mounted) {
                                              if (invited != null) {
                                                ScaffoldMessenger.of(ctx).showSnackBar(
                                                  SnackBar(content: Text('Added user: ${invited.readableName}')),
                                                );
                                                Navigator.pop(ctx);
                                              } else {
                                                ScaffoldMessenger.of(ctx).showSnackBar(
                                                  const SnackBar(content: Text('Invalid Invite Code!'), backgroundColor: Colors.redAccent),
                                                );
                                              }
                                            }
                                          }
                                        },
                                        child: const Text('Add User'),
                                      ),
                                    ],
                                  ),
                                );
                              },
                              constraints: const BoxConstraints(),
                              padding: EdgeInsets.zero,
                            ),
                          ],
                        ),
                      ),

                      // Render Dynamic users queried from DB (removing static demo users)
                      if (users.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                          child: Text(
                            'No other members yet',
                            style: GoogleFonts.inter(fontSize: 12, color: Colors.white38, fontStyle: FontStyle.italic),
                          ),
                        ),
                      ...users.map((user) {
                        return _dmSidebarTile(user.readableName, user.username, true);
                      }),

                      const Divider(color: Colors.white10, height: 32),

                      _sidebarTile(
                        label: 'Code Bucket',
                        prefix: '</> ',
                        isActive: _isCodeBucketActive,
                        onTap: () {
                          setState(() {
                            _isCodeBucketActive = true;
                            _selectedDmUser = null;
                          });
                        },
                      ),
                    ],
                  ),
                ),

                // User Info Footer
                Container(
                  padding: const EdgeInsets.all(16),
                  color: Colors.black.withOpacity(0.2),
                  child: Row(
                    children: [
                      InkWell(
                        onTap: () => context.push('/profile'),
                        borderRadius: BorderRadius.circular(20),
                        child: CircleAvatar(
                          radius: 18,
                          backgroundImage: NetworkImage(
                            authState.user?.avatarUrl ?? 'https://api.dicebear.com/7.x/bottts/svg?seed=user',
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: InkWell(
                          onTap: () => context.push('/profile'),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                authState.user?.readableName ?? 'Anonymous',
                                style: GoogleFonts.inter(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                'View Profile',
                                style: GoogleFonts.inter(
                                  color: Colors.white38,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.settings_rounded, color: Colors.white70, size: 20),
                        onPressed: () => context.push('/profile'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Active Screen
          Expanded(
            child: Container(
              color: isDark ? const Color(0xFF1E1E2A) : const Color(0xFFF5F7FA),
              child: _isCodeBucketActive
                  ? const CodeBucketScreen()
                  : activeChannelId != null
                      ? _buildChatInterface(activeChannelId, theme, isDark)
                      : Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.chat_bubble_outline_rounded, size: 48, color: Colors.grey[500]),
                              const SizedBox(height: 12),
                              Text(
                                'Select or create a channel to start',
                                style: GoogleFonts.inter(color: Colors.grey[500], fontSize: 15),
                              ),
                            ],
                          ),
                        ),
            ),
          ),

          // Thread replies Panel
          if (activeThreadMsg != null && activeChannelId != null)
            _buildThreadPanel(activeChannelId, activeThreadMsg, isDark),
        ],
      ),
    );
  }

  Widget _sidebarTile({
    required String label,
    required String prefix,
    required bool isActive,
    required VoidCallback onTap,
    VoidCallback? onDelete,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: isActive ? Colors.white.withOpacity(0.15) : Colors.transparent,
        borderRadius: BorderRadius.circular(6),
      ),
      child: ListTile(
        title: Text(
          '$prefix$label',
          style: GoogleFonts.inter(
            color: Colors.white,
            fontSize: 14,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        trailing: onDelete != null
            ? IconButton(
                icon: const Icon(Icons.delete_outline_rounded, color: Colors.white38, size: 16),
                onPressed: onDelete,
                hoverColor: Colors.redAccent.withOpacity(0.2),
                constraints: const BoxConstraints(),
                padding: EdgeInsets.zero,
              )
            : null,
        dense: true,
        onTap: onTap,
        visualDensity: const VisualDensity(vertical: -2),
      ),
    );
  }

  Widget _dmSidebarTile(String name, String seed, bool isOnline) {
    final isSelected = _selectedDmUser == name && !_isCodeBucketActive;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: isSelected ? Colors.white.withOpacity(0.15) : Colors.transparent,
        borderRadius: BorderRadius.circular(6),
      ),
      child: ListTile(
        leading: Stack(
          children: [
            CircleAvatar(
              radius: 12,
              backgroundImage: NetworkImage('https://api.dicebear.com/7.x/avataaars/svg?seed=$seed'),
            ),
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  color: isOnline ? Colors.green : Colors.grey,
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFF3F0E40), width: 1),
                ),
              ),
            ),
          ],
        ),
        title: Text(
          name,
          style: GoogleFonts.inter(
            color: Colors.white,
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        dense: true,
        onTap: () {
          setState(() {
            _isCodeBucketActive = false;
            _selectedDmUser = name;
          });
        },
        visualDensity: const VisualDensity(vertical: -2),
      ),
    );
  }

  Widget _buildChatInterface(String channelId, ThemeData theme, bool isDark) {
    final messages = ref.watch(messagesProvider(channelId));
    final channels = ref.watch(channelsProvider);
    final activeChan = channels.firstWhere(
      (c) => c.id == channelId, 
      orElse: () => Channel(id: channelId, name: 'general', ownerId: 'system'),
    );

    final chatTitle = _selectedDmUser ?? '# ${activeChan.name}';
    final chatDesc = _selectedDmUser != null ? 'Direct conversation' : (activeChan.description ?? 'Welcome to ${activeChan.name}');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          decoration: BoxDecoration(
            color: isDark ? Colors.grey[900]!.withOpacity(0.5) : Colors.white,
            border: Border(
              bottom: BorderSide(color: isDark ? Colors.grey[850]! : Colors.grey[200]!),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      chatTitle,
                      style: GoogleFonts.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      chatDesc,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Colors.grey[500],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.info_outline),
                onPressed: () {},
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            controller: _chatScrollController,
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 24),
            itemCount: messages.length,
            itemBuilder: (context, index) {
              final msg = messages[index];
              return _buildMessageItem(msg, isDark);
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 24, right: 24, bottom: 24),
          child: Column(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[900] : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark ? Colors.grey[800]! : Colors.grey[300]!,
                  ),
                ),
                child: Column(
                  children: [
                    TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: 'Message $chatTitle',
                        contentPadding: const EdgeInsets.all(16),
                        border: InputBorder.none,
                      ),
                      onSubmitted: (_) => _sendMessage(channelId),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.sentiment_satisfied_alt_rounded),
                            onPressed: () {
                              setState(() {
                                _showEmojiPicker = !_showEmojiPicker;
                              });
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.attach_file_rounded),
                            onPressed: () {
                              ref.read(messagesProvider(channelId).notifier).sendMessage(
                                    'Shared an attachment',
                                    attachmentUrls: ['https://images.unsplash.com/photo-1579202673506-ca3ce28943ef?w=400'],
                                  );
                            },
                          ),
                          const Spacer(),
                          IconButton(
                            icon: const Icon(Icons.send_rounded, color: Colors.deepPurpleAccent),
                            onPressed: () => _sendMessage(channelId),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              if (_showEmojiPicker)
                SizedBox(
                  height: 250,
                  child: EmojiPicker(
                    onEmojiSelected: (category, emoji) {
                      _messageController.text += emoji.emoji;
                    },
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMessageItem(Message msg, bool isDark) {
    final senderName = msg.sender?.readableName ?? 'anonymous';
    final senderAvatar = msg.sender?.avatarUrl ?? 'https://api.dicebear.com/7.x/bottts/svg?seed=$senderName';
    final timeStr = DateFormat('hh:mm a').format(msg.createdAt);

    return MouseRegion(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 20,
              backgroundImage: NetworkImage(senderAvatar),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        senderName,
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        timeStr,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    msg.content,
                    style: GoogleFonts.inter(
                      fontSize: 14.5,
                      height: 1.4,
                    ),
                  ),
                  if (msg.reactions.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Wrap(
                        spacing: 6,
                        children: msg.reactions
                            .map((r) => Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.deepPurpleAccent.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: Colors.deepPurpleAccent.withOpacity(0.3)),
                                  ),
                                  child: Text(
                                    '${r.type} 1',
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ))
                            .toList(),
                      ),
                    ),
                ],
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.add_reaction_outlined, size: 18),
                  tooltip: 'React thumbs up',
                  onPressed: () {
                    ref.read(messagesProvider(msg.channelId).notifier).toggleReaction(msg.id, '👍');
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.mode_comment_outlined, size: 18),
                  tooltip: 'Reply in thread',
                  onPressed: () {
                    ref.read(activeThreadMessageProvider.notifier).state = msg;
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThreadPanel(String channelId, Message parentMsg, bool isDark) {
    final replies = ref.watch(threadRepliesProvider({'channelId': channelId, 'parentId': parentMsg.id}));
    final replyController = TextEditingController();

    return Container(
      width: 320,
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(
            color: isDark ? Colors.grey[850]! : Colors.grey[300]!,
          ),
        ),
        color: isDark ? Colors.grey[900]!.withOpacity(0.7) : Colors.white,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: isDark ? Colors.grey[850]! : Colors.grey[200]!)),
            ),
            child: Row(
              children: [
                Text(
                  'Thread Discussion',
                  style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => ref.read(activeThreadMessageProvider.notifier).state = null,
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? Colors.black26 : Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    parentMsg.sender?.readableName ?? 'User',
                    style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  const SizedBox(height: 4),
                  Text(parentMsg.content, style: GoogleFonts.inter(fontSize: 13)),
                ],
              ),
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: replies.length,
              itemBuilder: (context, index) {
                final reply = replies[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        radius: 12,
                        backgroundImage: NetworkImage(
                          reply.sender?.avatarUrl ?? 'https://api.dicebear.com/7.x/bottts/svg?seed=${reply.sender?.username}',
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              reply.sender?.readableName ?? 'user',
                              style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                            const SizedBox(height: 2),
                            Text(reply.content, style: GoogleFonts.inter(fontSize: 12.5)),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: replyController,
              decoration: InputDecoration(
                hintText: 'Reply in thread...',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.send, color: Colors.deepPurpleAccent),
                  onPressed: () {
                    final text = replyController.text.trim();
                    if (text.isNotEmpty) {
                      ref.read(threadRepliesProvider({'channelId': channelId, 'parentId': parentMsg.id}).notifier).sendReply(text);
                      replyController.clear();
                    }
                  },
                ),
                border: const OutlineInputBorder(),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
