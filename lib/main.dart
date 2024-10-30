import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // TRY THIS: Try running your application with "flutter run". You'll see
        // the application has a purple toolbar. Then, without quitting the app,
        // try changing the seedColor in the colorScheme below to Colors.green
        // and then invoke "hot reload" (save your changes or press the "hot
        // reload" button in a Flutter-supported IDE, or press "r" if you used
        // the command line to start the app).
        //
        // Notice that the counter didn't reset back to zero; the application
        // state is not lost during the reload. To reset the state, use hot
        // restart instead.
        //
        // This works for code too, not just values: Most code changes can be
        // tested with just a hot reload.
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String folderPath = '';
  bool onFolderize = false;

  Future<void> _saveFolder(String folderPath) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('selectedFolder', folderPath);
  }

  Future<String> _getSavedFolder() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('selectedFolder') ?? '';
  }

  Future<void> _pickFolder() async {
    debugPrint("Before Pick");
    final result = await getDirectoryPath();
    debugPrint("After Pick");
    if (result != null) {
      setState(() {
        folderPath = result;
      });
    }
  }

  Future<bool> isDirectoryExists(String directoryPath) async {
    final directory = Directory(directoryPath);
    return await directory.exists();
  }

  Future<void> createDirectory(String directoryPath) async {
    try {
      final directory = Directory(directoryPath);
      await directory.create(recursive: true);
      print('디렉토리 생성 성공: $directoryPath');
    } catch (e) {
      print('디렉토리 생성 실패: $e');
    }
  }

  Future<void> moveFile(
      String sourceFilePath, String destinationFilePath) async {
    try {
      final file = File(sourceFilePath);
      await file.copy(destinationFilePath);
      await file.delete();
      print('파일 이동 성공: $sourceFilePath -> $destinationFilePath');
    } catch (e) {
      print('파일 이동 실패: $e');
    }
  }

  Future<void> _folderize() async {
    // 폴더 안에 있는 파일들을 가져온다
    setState(() {
      onFolderize = true;
    });
    if (folderPath != null) {
      final directory = Directory(folderPath);
      debugPrint(folderPath);
      final Stream<FileSystemEntity> files = directory.list();
      files.listen((item) async {
        final file = File(item.path);
        debugPrint(item.path);
        final FileStat stats = await file.stat();
        final DateTime lastModified = stats.modified;
        if (lastModified.isAfter(selectedDate) ||
            DateUtils.isSameDay(lastModified, selectedDate)) {
          int year = lastModified.year;
          int month = lastModified.month;
          int day = lastModified.day;
          String newFolderPath = '${folderPath}/${year}/${month}/${day}';
          debugPrint(newFolderPath);
          // 날짜에 맞는 폴더가 없으면 만든다
          if (!await isDirectoryExists(newFolderPath)) {
            //await createDirectory(newFolderPath);
          }
          // 폴더에 파일을 이동시킨다
          //await moveFile(item.path, newFolderPath);
        }
      }, onDone: () {
        setState(() {
          onFolderize = false;
        });
      });
    }
  }

  DateTime selectedDate = DateTime.now();
  String dateStr = "시작 날짜 선택";
  bool hasDate = false;

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
        dateStr = '${selectedDate.year}년 ${selectedDate.month}월 ${selectedDate.day}일';
        hasDate = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        // TRY THIS: Try changing the color here to a specific color (to
        // Colors.amber, perhaps?) and trigger a hot reload to see the AppBar
        // change color while the other colors stay the same.
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: Column(
          // Column is also a layout widget. It takes a list of children and
          // arranges them vertically. By default, it sizes itself to fit its
          // children horizontally, and tries to be as tall as its parent.
          //
          // Column has various properties to control how it sizes itself and
          // how it positions its children. Here we use mainAxisAlignment to
          // center the children vertically; the main axis here is the vertical
          // axis because Columns are vertical (the cross axis would be
          // horizontal).
          //
          // TRY THIS: Invoke "debug painting" (choose the "Toggle Debug Paint"
          // action in the IDE, or press "p" in the console), to see the
          // wireframe for each widget.
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text('선택된 폴더: $folderPath'),
            ElevatedButton(
              onPressed: _pickFolder,
              child: Text('폴더 선택'),
            ),
            ElevatedButton(
              onPressed: () => _selectDate(context),
              child: Text(dateStr)
            ),
            ElevatedButton(
              onPressed: hasDate && onFolderize == false ? _folderize : null,
              child: Text('날짜별로 나누기'),
            ),
          ],
        ),
      ),
    );
  }
}
