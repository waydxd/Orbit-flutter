import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../nlp_input_provider.dart';
import '../../tasks/view/create_item_page.dart';

/// Page for natural language input to create tasks/events
class NlpInputPage extends StatefulWidget {
  final String? apiKey;
  
  const NlpInputPage({super.key, this.apiKey});

  @override
  State<NlpInputPage> createState() => _NlpInputPageState();
}

class _NlpInputPageState extends State<NlpInputPage> {
  final _textController = TextEditingController();
  late final NlpInputProvider _provider;

  @override
  void initState() {
    super.initState();
    _provider = NlpInputProvider(apiKey: widget.apiKey);
  }

  @override
  void dispose() {
    _textController.dispose();
    _provider.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _provider,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFFEAFFFE),
                Color(0xFFCDC9F1),
              ],
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Freely write down your future plan.',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1F2937),
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 24),
                        _buildInputField(),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
                  child: _buildCreateButton(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(
              Icons.chevron_left,
              color: Color(0xFF6366F1),
              size: 32,
            ),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _buildInputField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(60),
      ),
      child: Stack(
        children: [
          TextField(
            controller: _textController,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: 'eg, "Meeting with John tomorrow at 3pm" or "Buy groceries by Friday"',
              hintStyle: TextStyle(color: Colors.grey.shade400),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(20),
            ),
            style: const TextStyle(
              fontSize: 16,
              color: Color(0xFF1F2937),
            ),
          ),
          Positioned(
            bottom: 12,
            right: 12,
            child: Icon(
              Icons.drag_handle_rounded,
              color: Colors.grey.shade300,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleCreate() async {
    final text = _textController.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter some text')),
      );
      return;
    }

    await _provider.parseInput(text);

    if (!mounted) return;

    if (_provider.hasResult) {
      final result = _provider.result!;
      final isEvent = result.type == 'event';

      // Navigate to create item page with classification result
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => CreateItemPage(
            initialIsEvent: isEvent,
          ),
        ),
      );
    } else if (_provider.hasError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_provider.error!)),
      );
    }
  }

  Widget _buildCreateButton() {
    return Consumer<NlpInputProvider>(
      builder: (context, provider, _) {
        return GestureDetector(
          onTap: provider.isLoading ? null : _handleCreate,
          child: Container(
            width: double.infinity,
            height: 60,
            decoration: BoxDecoration(
              color: provider.isLoading ? Colors.grey : Colors.black,
              borderRadius: BorderRadius.circular(30),
            ),
            child: Center(
              child: provider.isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text(
                      'Create',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        );
      },
    );
  }

}
