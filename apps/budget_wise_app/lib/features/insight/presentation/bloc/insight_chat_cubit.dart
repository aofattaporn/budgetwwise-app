import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ─── Chat Message Model ─────────────────────────────────────────────────────

class ChatMessage extends Equatable {
  final String? id;
  final String text;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({
    this.id,
    required this.text,
    required this.isUser,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] as String?,
      text: json['content'] as String,
      isUser: json['role'] == 'user',
      timestamp: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toInsertJson() => {
        'role': isUser ? 'user' : 'assistant',
        'content': text,
      };

  @override
  List<Object?> get props => [id, text, isUser, timestamp];
}

// ─── Chat State ─────────────────────────────────────────────────────────────

enum ChatStatus { idle, loading, sending, error }

class InsightChatState extends Equatable {
  final List<ChatMessage> messages;
  final ChatStatus status;
  final String? errorMessage;

  const InsightChatState({
    this.messages = const [],
    this.status = ChatStatus.idle,
    this.errorMessage,
  });

  InsightChatState copyWith({
    List<ChatMessage>? messages,
    ChatStatus? status,
    String? errorMessage,
  }) {
    return InsightChatState(
      messages: messages ?? this.messages,
      status: status ?? this.status,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [messages, status, errorMessage];
}

// ─── Chat Cubit ─────────────────────────────────────────────────────────────

class InsightChatCubit extends Cubit<InsightChatState> {
  final SupabaseClient _supabaseClient;

  InsightChatCubit({required SupabaseClient supabaseClient})
      : _supabaseClient = supabaseClient,
        super(const InsightChatState());

  /// Load existing chat history from the database.
  Future<void> loadChatHistory() async {
    emit(state.copyWith(status: ChatStatus.loading));
    try {
      final rows = await _supabaseClient
          .from('chat_messages')
          .select()
          .order('created_at', ascending: true);

      final messages =
          (rows as List).map((r) => ChatMessage.fromJson(r)).toList();

      emit(state.copyWith(messages: messages, status: ChatStatus.idle));
    } catch (e) {
      emit(state.copyWith(status: ChatStatus.idle));
    }
  }

  // TODO : add planId to chat_messages table and filter by it in loadChatHistory
  Future<void> sendMessage(String query, String planId) async {
    if (query.trim().isEmpty) return;

    final userMessage = ChatMessage(text: query.trim(), isUser: true);
    emit(state.copyWith(
      messages: [...state.messages, userMessage],
      status: ChatStatus.sending,
      errorMessage: null,
    ));

    try {
      // Save user message to DB
      await _supabaseClient
          .from('chat_messages')
          .insert(userMessage.toInsertJson());

      final res = await _supabaseClient.functions.invoke(
        'budgetwise-gemini',
        body: {'query': query.trim(), "planId": planId},
      );

      final data = res.data as Map<String, dynamic>?;
      final statusCode = data?['statusCode'] as int?;

      // Handle rate limit (HTTP 429)
      if (statusCode == 429) {
        emit(state.copyWith(
          status: ChatStatus.error,
          errorMessage:
              'Rate limit reached. Please wait a moment before trying again.',
        ));
        return;
      }

      if (statusCode == 503) {
        emit(state.copyWith(
          status: ChatStatus.error,
          errorMessage:
              'The assistant is temporarily unavailable. Please try again in a moment.',
        ));
        return;
      }

      final responseText =
          data?['response'] as String? ?? 'No response received.';

      final botMessage = ChatMessage(text: responseText, isUser: false);

      // Save assistant message to DB
      await _supabaseClient
          .from('chat_messages')
          .insert(botMessage.toInsertJson());

      emit(state.copyWith(
        messages: [...state.messages, botMessage],
        status: ChatStatus.idle,
      ));
    } on FunctionException catch (e) {
      final code = e.status;
      if (code == 429) {
        emit(state.copyWith(
          status: ChatStatus.error,
          errorMessage:
              'Rate limit reached. Please wait a moment before trying again.',
        ));
      } else {
        emit(state.copyWith(
          status: ChatStatus.error,
          errorMessage: 'Failed to get response (status $code). Please try again.',
        ));
      }
    } catch (e) {
      final msg = e.toString().toLowerCase();
      if (msg.contains('429') || msg.contains('rate limit') || msg.contains('quota')) {
        emit(state.copyWith(
          status: ChatStatus.error,
          errorMessage:
              'Rate limit reached. Please wait a moment before trying again.',
        ));
      } else {
        emit(state.copyWith(
          status: ChatStatus.error,
          errorMessage: 'Failed to get response. Please try again.',
        ));
      }
    }
  }

  /// Delete all chat messages from DB and clear local state.
  Future<void> clearChat() async {
    try {
      await _supabaseClient.from('chat_messages').delete().neq('id', '');
    } catch (_) {
      // Ignore DB error — still clear locally
    }
    emit(const InsightChatState());
  }
}
