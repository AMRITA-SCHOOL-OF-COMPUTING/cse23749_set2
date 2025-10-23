import 'package:flutter/material.dart';
import 'package:realm/realm.dart';


part 'main.realm.dart';

// i have implemented vackend with local storage mongodb realm

@RealmModel()
class _Task {
  @PrimaryKey()
  late ObjectId id;
  late String title;
  String? desc;
  String? priority;
  late DateTime date;
}

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const MyHomePage(title: 'Task Manager'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late final Realm realm;
  RealmResults<Task>? _tasks;

  @override
  void initState() {
    super.initState();
    final config = Configuration.local([Task.schema]);
    realm = Realm(config);
    _tasks = realm.all<Task>();
    _tasks!.changes.listen((changes) {
      setState(() {});
    });
  }

  @override
  void dispose() {
    realm.close();
    super.dispose();
  }

  void _openAdd() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AddTask(realm: realm)),
    );
  }

  void _openUpdate(Task t) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => UpdateTasks(realm: realm, task: t)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tasks = _tasks?.toList() ?? <Task>[];
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),

      // all tasks are visible on the home page
      body: ListView.builder(
        itemCount: tasks.length + 1,
        itemBuilder: (context, index) {
          if (index == tasks.length) {
            return ListTile(
              title: const Text("Task Editing Page"),
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => UpdateTasksList(realm: realm)));
              },
            );
          }
          final t = tasks[index];
          // each task is displayed as a tile with edit option
          // inkwell has been implemented as per question requirement
          return InkWell(
            splashColor: Colors.amber,
            highlightColor: Colors.blue,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => TaskPage(task: t))),
            child: ListTile(
              leading: const Icon(Icons.task),
              title: Text(t.title),
              subtitle: Text(t.desc ?? ''),
              trailing: IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () => _openUpdate(t),
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openAdd,
        child: const Icon(Icons.add),
      ),
    );
  }
}

// add task page for adding each task as per question

class AddTask extends StatefulWidget {
  final Realm realm;
  const AddTask({super.key, required this.realm});

  @override
  State<AddTask> createState() => _AddTaskState();
}

class _AddTaskState extends State<AddTask> {
  final TextEditingController _titlecontroller = TextEditingController();
  final TextEditingController _desccontroller = TextEditingController();
  String _priority = 'Low';
  DateTime selectedDate = DateTime.now();

  void addTask() {
    final t = _titlecontroller.text.trim();
    final d = _desccontroller.text.trim();
    widget.realm.write(() {
      widget.realm.add(Task(ObjectId(), t, selectedDate, desc: d, priority: _priority));
    });
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Task added!")));
    Navigator.pop(context);
  }

  // each task has title, description, dropdown priority and date picker for deadline
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Add Task"),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(controller: _titlecontroller, decoration: const InputDecoration(labelText: "Title")),
            const SizedBox(height: 12),
            TextField(controller: _desccontroller, decoration: const InputDecoration(labelText: "Description")),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _priority,
              items: const [
                DropdownMenuItem(value: 'Low', child: Text('Low')),
                DropdownMenuItem(value: 'Medium', child: Text('Medium')),
                DropdownMenuItem(value: 'High', child: Text('High')),
              ],
              onChanged: (v) => setState(() => _priority = v ?? 'Low'),
              decoration: const InputDecoration(labelText: "Priority"),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.calendar_month),
                  onPressed: () async {
                    final pickedDate = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime(2021),
                      lastDate: DateTime(2030),
                    );
                    if (pickedDate != null) setState(() => selectedDate = pickedDate);
                  },
                ),
                Text("${selectedDate.toLocal()}".split(' ')[0]),
              ],
            ),
            const SizedBox(height: 12),
            TextButton(onPressed: addTask, child: const Text("Add Task"))
          ],
        ),
      ),
    );
  }
}

// update task page for updating and deleting each task
class UpdateTasks extends StatefulWidget {
  final Realm realm;
  final Task task;
  const UpdateTasks({super.key, required this.realm, required this.task});

  @override
  State<UpdateTasks> createState() => _UpdateTasksState();
}

class _UpdateTasksState extends State<UpdateTasks> {
  late final TextEditingController _titlecontroller;
  late final TextEditingController _desccontroller;
  String _priority = 'Low';
  late DateTime selectedDate;

  @override
  void initState() {
    super.initState();
    _titlecontroller = TextEditingController(text: widget.task.title);
    _desccontroller = TextEditingController(text: widget.task.desc ?? '');
    _priority = widget.task.priority ?? 'Low';
    selectedDate = widget.task.date;
  }

  void uTask() {
    widget.realm.write(() {
      widget.task.title = _titlecontroller.text.trim();
      widget.task.desc = _desccontroller.text.trim();
      widget.task.priority = _priority;
      widget.task.date = selectedDate;
    });
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Task updated!")));
    Navigator.pop(context);
  }

  void deleteTask() {
    widget.realm.write(() {
      widget.realm.delete(widget.task);
    });
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Task deleted")));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Update Task"),
        actions: [
          IconButton(onPressed: deleteTask, icon: const Icon(Icons.delete)),
        ],
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(controller: _titlecontroller, decoration: const InputDecoration(labelText: "Title")),
            const SizedBox(height: 12),
            TextField(controller: _desccontroller, decoration: const InputDecoration(labelText: "Description")),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _priority,
              items: const [
                DropdownMenuItem(value: 'Low', child: Text('Low')),
                DropdownMenuItem(value: 'Medium', child: Text('Medium')),
                DropdownMenuItem(value: 'High', child: Text('High')),
              ],
              onChanged: (v) => setState(() => _priority = v ?? 'Low'),
              decoration: const InputDecoration(labelText: "Priority"),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.calendar_month),
                  onPressed: () async {
                    final pickedDate = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime(2021),
                      lastDate: DateTime(2030),
                    );
                    if (pickedDate != null) setState(() => selectedDate = pickedDate);
                  },
                ),
                Text("${selectedDate.toLocal()}".split(' ')[0]),
              ],
            ),
            const SizedBox(height: 12),
            TextButton(onPressed: uTask, child: const Text("Update Task")),
          ],
        ),
      ),
    );
  }
}

// update tasks list page to show all tasks for editing

class UpdateTasksList extends StatelessWidget {
  final Realm realm;
  const UpdateTasksList({super.key, required this.realm});

  @override
  Widget build(BuildContext context) {
    final all = realm.all<Task>();
    return Scaffold(
      appBar: AppBar(title: const Text('All Tasks'), backgroundColor: Theme.of(context).colorScheme.inversePrimary),
      body: ListView.builder(
        itemCount: all.length,
        itemBuilder: (context, idx) {
          final t = all[idx];
          return ListTile(
            leading: const Icon(Icons.task),
            title: Text(t.title),
            subtitle: Text(t.desc ?? ''),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (c) => UpdateTasks(realm: realm, task: t))),
          );
        },
      ),
    );
  }
}

// each task gets its own individual page showing details
class TaskPage extends StatelessWidget {
  final Task task;
  const TaskPage({super.key, required this.task});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(task.title), backgroundColor: Theme.of(context).colorScheme.inversePrimary),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Card(
          child: ListTile(
            title: Text(task.title),
            subtitle: Text('${task.desc ?? ''}\nPriority: ${task.priority ?? ''}\nDeadline: ${task.date.toLocal()}'.split(' ')[0]),
          ),
        ),
      ),
    );
  }
}
