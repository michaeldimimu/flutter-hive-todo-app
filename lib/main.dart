import 'package:flutter/material.dart';
import 'package:flutter_todo_app/models/task.dart';
import 'package:hive_flutter/hive_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter("hive_box");

  await Hive.openBox('tasks');

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(title: 'Flutter todo app', home: Home());
  }
}

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final Box taskBox = Hive.box('tasks');
  final TextEditingController _controller = TextEditingController();

  void _addTask() {
    if (_controller.text.isNotEmpty) {
      final newTask = Task(
        todo: _controller.text,
        timeStamp: DateTime.now(),
        isDone: false,
      );

      taskBox.add(newTask.toMap());

      _controller.clear();
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Title Section
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Text(
                'Todos',
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
              ),
            ),

            // The main body of your Scaffold
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: ValueListenableBuilder(
                  valueListenable: taskBox.listenable(),
                  builder: (context, Box box, _) {
                    // Convert the raw box data into usable lists
                    final List allTasks = box.values.toList();

                    // Inside your ValueListenableBuilder in main.dart
                    final activeTasks = allTasks
                        .where((t) => !t['isDone'])
                        .toList();
                    final completedTasks = allTasks
                        .where((t) => t['isDone'])
                        .toList();

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 1. ACTIVE TODOS SECTION
                        if (activeTasks.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          _buildTaskList(activeTasks, box),
                          const SizedBox(height: 32),
                        ] else ...[
                          // SHOW THIS WHEN ACTIVE TASKS ARE GONE
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.symmetric(vertical: 40),
                              child: Text(
                                "No tasks yet!",
                                style: TextStyle(color: Colors.grey, fontSize: 20),
                              ),
                            ),
                          ),
                        ],

                        // 2. COMPLETED SECTION
                        if (completedTasks.isNotEmpty) ...[
                          const Text(
                            "Completed",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 10),
                          _buildTaskList(
                            completedTasks,
                            box,
                            isCompletedSection: true,
                          ),
                        ],
                      ],
                    );
                  },
                ),
              ),
            ),

            // 3. Fixed Bottom Input Row
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  // The Text Input
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: InputDecoration(
                        hintText: "Type your task here",
                        hintStyle: const TextStyle(color: Colors.grey),
                        filled: true,
                        fillColor: const Color(0xFFEEEEEE),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 18,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: const BorderSide(
                            color: Colors.grey,
                            width: 1.5,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: const BorderSide(
                            color: Colors.black,
                            width: 2.0,
                          ),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // The Add Button
                  GestureDetector(
                    onTap: _addTask,
                    child: Container(
                      height: 60,
                      width: 60,
                      decoration: const BoxDecoration(
                        color: Colors.black,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.add,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskList(
    List tasks,
    Box box, {
    bool isCompletedSection = false,
  }) {
    return ListView.builder(
      shrinkWrap: true,
      padding: EdgeInsets.zero,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: tasks.length,
      itemBuilder: (context, index) {
        final taskMap = tasks[index];
        final task = Task.fromMap(Map<String, dynamic>.from(taskMap));
        final int originalIndex = box.values.toList().indexOf(taskMap);

        String formattedTime =
            "${task.timeStamp.hour.toString().padLeft(2, '0')}:${task.timeStamp.minute.toString().padLeft(2, '0')}";

        return ListTile(
          // Control the distance from the screen edges here
          contentPadding: const EdgeInsets.only(right: 0),
          horizontalTitleGap: 12,
          // Pulls the text closer to the leading icon
          onTap: () {
            task.isDone = !task.isDone;
            box.putAt(originalIndex, task.toMap());
          },
          leading: Icon(
            task.isDone ? Icons.check_circle : Icons.circle_outlined,
            color: task.isDone ? Colors.grey : Colors.black,
            size: 32,
          ),
          title: Text(
            task.todo,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: task.isDone ? Colors.grey.shade400 : Colors.black,
            ),
          ),
          subtitle: Text(
            formattedTime,
            style: TextStyle(
              fontSize: 14,
              color: task.isDone ? Colors.grey.shade400 : Colors.grey,
            ),
          ),
          trailing: IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            icon: const Icon(
              Icons.delete_outline,
              color: Colors.redAccent,
              size: 26,
            ),
            onPressed: () => box.deleteAt(originalIndex),
          ),
        );
      },
    );
  }
}
