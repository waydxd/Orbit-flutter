import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../auth/view_model/auth_view_model.dart';
import '../../chat/view/chat_page.dart';
import '../../calendar/view/calendar_page.dart';
import '../../calendar/view_model/calendar_view_model.dart';
import '../../calendar/widgets/floating_nav_bar.dart';
import '../../dashboard/view/dashboard_page.dart';
import '../../home/view/home_page.dart';
import '../../tasks/view/create_item_page.dart';
import '../../tasks/view/task_list_page.dart';
import '../../nlp_input/view/nlp_input_page.dart';

class MainNavigationShell extends StatefulWidget {
  const MainNavigationShell({super.key});

  @override
  State<MainNavigationShell> createState() => _MainNavigationShellState();
}

class _MainNavigationShellState extends State<MainNavigationShell> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    HomePage(),
    CalendarPage(),
    TaskListPage(),
    DashboardPage(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final userId = context.read<AuthViewModel>().currentUser?.id;
      if (userId != null) {
        context.read<CalendarViewModel>().fetchAll(
              userId: userId,
              eventRangeAnchor: DateTime.now(),
            );
      }
    });
  }

  void _selectTab(int index) {
    if (_currentIndex == index) return;
    setState(() {
      _currentIndex = index;
    });
  }

  Future<void> _openCreateItem() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const CreateItemPage()),
    );
  }

  Future<void> _openAiChat() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const AiChatPage()),
    );
  }

  Future<void> _openNlpInput() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const NlpInputPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          IndexedStack(index: _currentIndex, children: _pages),
          FloatingNavBar(
            currentIndex: _currentIndex,
            onHomeTap: () => _selectTab(0),
            onCalendarTap: () => _selectTab(1),
            onCreateTaskTap: _openCreateItem,
            onCreateTaskLongPress: _openAiChat,
            onNlpInputTap: _openNlpInput,
            onTodoListTap: () => _selectTab(2),
            onDashboardTap: () => _selectTab(3),
          ),
        ],
      ),
    );
  }
}
