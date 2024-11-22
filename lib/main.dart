import 'dart:io';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'FolderSelector.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '폴더라이징',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: '폴더라이징'),
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
    if (folderPath == '') {
      folderPath = FolderSelector.rootPath;
    }
    Directory dir = Directory(folderPath);
    Directory? newDirectory = await FolderSelector.pick(
        context: context,
        initDir: dir,
        );

    debugPrint("After Pick");
    if (newDirectory != null) {
      setState(() {
        folderPath = newDirectory.path;
        debugPrint(folderPath);
      });
      await _saveFolder(folderPath);
    }
  }

  Future<bool> _isDirectoryExists(String directoryPath) async {
    final directory = Directory(directoryPath);
    final bool result = await directory.exists();
    return result;
  }

  Future<void> _createDirectory(String directoryPath) async {
    try {
      final directory = Directory(directoryPath);
      await directory.create(recursive: true);
      debugPrint('디렉토리 생성 성공: $directoryPath');
    } catch (e) {
      debugPrint('디렉토리 생성 실패: $e');
    }
  }

  Future<void> _moveFile(
      String sourceFilePath, String destinationFilePath) async {
    try {
      final file = File(sourceFilePath);
      String destFile = "$destinationFilePath/${file.path.split('/').last}";
      await file.copy(destFile);
      await file.delete();
      debugPrint('파일 이동 성공: $sourceFilePath -> $destFile');
    } catch (e) {
      debugPrint('파일 이동 실패: $e');
    }
  }

  Future<void> _folderize() async {
    // 폴더 안에 있는 파일들을 가져온다
    setState(() {
      onFolderize = true;
    });
    if (folderPath != '') {
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
          String newFolderPath = '$folderPath/$year/$month/$day';
          debugPrint(newFolderPath);
          // 날짜에 맞는 폴더가 없으면 만든다
          final bool dirExist = await _isDirectoryExists(newFolderPath);
          if (!dirExist) {
            debugPrint("$newFolderPath 새로 만들어야 함");
            await _createDirectory(newFolderPath);
          }
          // 폴더에 파일을 이동시킨다
          await _moveFile(item.path, newFolderPath);
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
  void initState() {
    super.initState();
    _getSavedFolder();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text('선택된 폴더: $folderPath'),
            ElevatedButton(
              onPressed: _pickFolder,
              child: const Text('폴더 선택'),
            ),
            ElevatedButton(
              onPressed: () => _selectDate(context),
              child: Text(dateStr)
            ),
            ElevatedButton(
              onPressed: hasDate && onFolderize == false ? _folderize : null,
              child: const Text('날짜별로 나누기'),
            ),
          ],
        ),
      ),
    );
  }
}
