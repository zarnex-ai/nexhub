class UserProfile {
  final String id;
  final String username;
  final String? displayName;
  final String? avatarUrl;
  final String? inviteCode;

  UserProfile({
    required this.id,
    required this.username,
    this.displayName,
    this.avatarUrl,
    this.inviteCode,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      username: json['username'] as String? ?? 'anonymous',
      displayName: json['display_name'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      inviteCode: json['invite_code'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'display_name': displayName,
      'avatar_url': avatarUrl,
      'invite_code': inviteCode,
    };
  }

  String get readableName => displayName ?? username;
}

class Channel {
  final String id;
  final String name;
  final String? description;
  final String ownerId;
  final DateTime? createdAt;

  Channel({
    required this.id,
    required this.name,
    this.description,
    required this.ownerId,
    this.createdAt,
  });

  factory Channel.fromJson(Map<String, dynamic> json) {
    return Channel(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      ownerId: json['owner_id'] as String,
      createdAt: json['created_at'] != null 
          ? DateTime.tryParse(json['created_at'] as String) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'owner_id': ownerId,
    };
  }
}

class Attachment {
  final String id;
  final int messageId;
  final String url;
  final String? mimeType;

  Attachment({
    required this.id,
    required this.messageId,
    required this.url,
    this.mimeType,
  });

  factory Attachment.fromJson(Map<String, dynamic> json) {
    return Attachment(
      id: json['id'] as String,
      messageId: json['message_id'] is String
          ? int.parse(json['message_id'] as String)
          : json['message_id'] as int,
      url: json['url'] as String,
      mimeType: json['mime_type'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'message_id': messageId,
      'url': url,
      'mime_type': mimeType,
    };
  }
}

class Reaction {
  final String id;
  final int messageId;
  final String userId;
  final String type; // Emoji string like '👍', '❤️', etc.

  Reaction({
    required this.id,
    required this.messageId,
    required this.userId,
    required this.type,
  });

  factory Reaction.fromJson(Map<String, dynamic> json) {
    return Reaction(
      id: json['id'] as String,
      messageId: json['message_id'] is String
          ? int.parse(json['message_id'] as String)
          : json['message_id'] as int,
      userId: json['user_id'] as String,
      type: json['type'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'message_id': messageId,
      'user_id': userId,
      'type': type,
    };
  }
}

class Message {
  final int id;
  final String channelId;
  final String userId;
  final String content;
  final DateTime createdAt;
  final UserProfile? sender;
  final List<Attachment> attachments;
  final List<Reaction> reactions;
  final int? parentId; // For thread replies support

  Message({
    required this.id,
    required this.channelId,
    required this.userId,
    required this.content,
    required this.createdAt,
    this.sender,
    this.attachments = const [],
    this.reactions = const [],
    this.parentId,
  });

  factory Message.fromJson(Map<String, dynamic> json, {UserProfile? sender, List<Attachment> attachments = const [], List<Reaction> reactions = const []}) {
    return Message(
      id: json['id'] is String ? int.parse(json['id'] as String) : json['id'] as int,
      channelId: json['channel_id'] as String,
      userId: json['user_id'] as String,
      content: json['content'] as String? ?? '',
      createdAt: json['created_at'] != null 
          ? DateTime.tryParse(json['created_at'] as String) ?? DateTime.now()
          : DateTime.now(),
      sender: sender ?? (json['profiles'] != null ? UserProfile.fromJson(json['profiles'] as Map<String, dynamic>) : null),
      attachments: attachments,
      reactions: reactions,
      parentId: json['parent_id'] != null
          ? (json['parent_id'] is String ? int.parse(json['parent_id'] as String) : json['parent_id'] as int)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'channel_id': channelId,
      'user_id': userId,
      'content': content,
      'created_at': createdAt.toIso8601String(),
      'parent_id': parentId,
    };
  }

  Message copyWith({
    int? id,
    String? channelId,
    String? userId,
    String? content,
    DateTime? createdAt,
    UserProfile? sender,
    List<Attachment>? attachments,
    List<Reaction>? reactions,
    int? parentId,
  }) {
    return Message(
      id: id ?? this.id,
      channelId: channelId ?? this.channelId,
      userId: userId ?? this.userId,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      sender: sender ?? this.sender,
      attachments: attachments ?? this.attachments,
      reactions: reactions ?? this.reactions,
      parentId: parentId ?? this.parentId,
    );
  }
}

class CodeSnippet {
  final String id;
  final String title;
  final String code;
  final String language;
  final String userId;
  final DateTime createdAt;

  CodeSnippet({
    required this.id,
    required this.title,
    required this.code,
    required this.language,
    required this.userId,
    required this.createdAt,
  });

  factory CodeSnippet.fromJson(Map<String, dynamic> json) {
    return CodeSnippet(
      id: json['id'] as String,
      title: json['title'] as String? ?? 'Untitled',
      code: json['code'] as String? ?? '',
      language: json['language'] as String? ?? 'text',
      userId: json['user_id'] as String? ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'code': code,
      'language': language,
      'user_id': userId,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
