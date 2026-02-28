import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../view_model/chat_view_model.dart';
import '../../../data/models/chat_message_model.dart';
import '../../../data/repositories/chat_repository.dart';
import '../../../data/services/api_client.dart';

class AiChatPage extends StatelessWidget {
  const AiChatPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Note: ChatViewModel is created here and will be disposed when the user
    // navigates away from this page. This means chat history is intentionally
    // cleared on page exit. If chat persistence is needed in the future,
    // move ChatViewModel to the app-level MultiProvider.
    return ChangeNotifierProvider(
      create: (_) => ChatViewModel(
        chatRepository: ChatRepository(ApiClient()),
      ),
      child: const _AiChatView(),
    );
  }
}

class _AiChatView extends StatefulWidget {
  const _AiChatView();

  @override
  State<_AiChatView> createState() => _AiChatViewState();
}

class _AiChatViewState extends State<_AiChatView> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _shouldScrollToBottom = false;

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients && _shouldScrollToBottom) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
        _shouldScrollToBottom = false;
      }
    });
  }

  void _handleSend(ChatViewModel viewModel, String text) {
    if (text.trim().isEmpty) return;
    viewModel.sendMessage(text);
    _textController.clear();
    // Mark that we should scroll to bottom after the next rebuild
    _shouldScrollToBottom = true;
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<ChatViewModel>();

    // Scroll to bottom when needed
    if (_shouldScrollToBottom) {
      _scrollToBottom();
    }

    final hasInteracted = viewModel.messages.length > 1;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            // Display error message if present
            if (viewModel.error != null)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 30, vertical: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline,
                        color: Colors.red.shade700, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        viewModel.error!,
                        style: TextStyle(
                          color: Colors.red.shade700,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 30),
                itemCount: viewModel.messages.isEmpty
                    ? 1
                    : viewModel.messages.length + 1, // +1 for header items
                itemBuilder: (context, index) {
                  if (index == 0) {
                    // Header items (Avatar + Suggestions)
                    if (hasInteracted) {
                      return const SizedBox(height: 20);
                    }
                    return Column(
                      children: [
                        const SizedBox(height: 10),
                        _buildAvatar(),
                        const SizedBox(height: 30),
                        _buildSuggestionsCard(viewModel),
                        const SizedBox(height: 40),
                      ],
                    );
                  }

                  final message = viewModel.messages[index - 1];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: _buildChatBubble(message),
                  );
                },
              ),
            ),
            if (viewModel.isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0),
                child: LinearProgressIndicator(
                  backgroundColor: Colors.transparent,
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6366F1)),
                  minHeight: 2,
                ),
              ),
            _buildInputSection(viewModel),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          IconButton(
            icon: const Icon(Icons.close, color: Color(0xFF6366F1), size: 28),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer glow layers
          for (int i = 1; i <= 3; i++)
            Container(
              width: 100.0 + (i * 20),
              height: 100.0 + (i * 20),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF6366F1).withValues(alpha: 0.15 / i),
                    const Color(0xFF6366F1).withValues(alpha: 0),
                  ],
                ),
              ),
            ),
          // Inner Orb
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFE0E7FF),
                  Color(0xFFC7D2FE),
                  Color(0xFF818CF8),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF6366F1).withValues(alpha: 0.4),
                  blurRadius: 25,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: const Center(
              child: Icon(Icons.auto_awesome, color: Colors.white, size: 36),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionsCard(ChatViewModel viewModel) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FE),
        borderRadius: BorderRadius.circular(32),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.auto_awesome_outlined,
                color: Color(0xFF6366F1),
                size: 20,
              ),
              SizedBox(width: 8),
              Text(
                'You can ask me about...',
                style: TextStyle(
                  color: Color(0xFF5E6272),
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _buildSuggestionChip('Task creation', viewModel),
              _buildSuggestionChip('Available time', viewModel),
              _buildSuggestionChip('Rearrange schedules', viewModel),
              _buildSuggestionChip('Next event', viewModel),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionChip(String label, ChatViewModel viewModel) {
    return InkWell(
      onTap: () => _handleSend(viewModel, label),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color(0xFF6366F1).withValues(alpha: 0.4),
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: Color(0xFF5E6272),
            fontSize: 14,
            fontWeight: FontWeight.w400,
          ),
        ),
      ),
    );
  }

  Widget _buildChatBubble(ChatMessage message) {
    final isUser = message.isUser;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        margin: EdgeInsets.only(left: isUser ? 50 : 0, right: isUser ? 0 : 50),
        decoration: BoxDecoration(
          color: isUser ? const Color(0xFF6366F1) : const Color(0xFF5E6272),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: Radius.circular(isUser ? 20 : 5),
            bottomRight: Radius.circular(isUser ? 5 : 20),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          message.content,
          textAlign: TextAlign.left,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w500,
            height: 1.4,
          ),
        ),
      ),
    );
  }

  Widget _buildInputSection(ChatViewModel viewModel) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(25, 0, 25, 25),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 54,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE0E7FF), width: 1.5),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: TextField(
                        controller: _textController,
                        onSubmitted: (value) => _handleSend(viewModel, value),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          hintText: 'Type a message...',
                        ),
                      ),
                    ),
                  ),
                  const Tooltip(
                    message: 'Voice input coming soon',
                    child: Icon(
                      Icons.mic,
                      color: Color(0xFFB0B3C0),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                ],
              ),
            ),
          ),
          const SizedBox(width: 15),
          InkWell(
            onTap: () => _handleSend(viewModel, _textController.text),
            borderRadius: BorderRadius.circular(50),
            child: Container(
              width: 54,
              height: 54,
              decoration: const BoxDecoration(
                color: Color(0xFFDDE1FF),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.send_rounded,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
