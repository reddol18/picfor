import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';

import 'FolderSelector.dart';

class DirectoryList extends StatefulWidget {
  const DirectoryList({super.key});

  @override
  _DirectoryListState createState() => _DirectoryListState();
}

class _DirectoryListState extends State<DirectoryList> {
  Directory? initDir;
  Directory? currentDirectory;
  List<FileSystemEntity> directories = [];
  late Stream<FileSystemEntity> dstream;
  bool hasDstream = false;
  bool isDone = true;
  late StreamSubscription ss;

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration.zero).then((_) => _init());
  }

  Widget _buildBackNav(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return ListTile(
      leading: Icon(Icons.folder, color: theme.primaryColor),
      title: const Text('..'),
      onTap: () => _setDirectory(currentDirectory!.parent),
    );
  }

  Column _buildDirectories(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    int count = directories.length + 1;
    if (!isDone) {
      count += 1;
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisAlignment: MainAxisAlignment.start,
      mainAxisSize: MainAxisSize.max,
      children: [
        Expanded(
          child: ListView.builder(
            scrollDirection: Axis.vertical,
            itemBuilder: (context, index) {
              if (index == 0) {
                if (directories.isEmpty) {
                  return const ListTile(
                    leading: CircularProgressIndicator(),
                    title: Text("탐색중"),
                    onTap: null,
                  );
                } else {
                  return _buildBackNav(context);
                }
              } else if (count == directories.length + 2 &&
                  index == count - 1) {
                return const ListTile(
                  leading: CircularProgressIndicator(),
                  title: Text("탐색중"),
                  onTap: null,
                );
              } else {
                return ListTile(
                  leading:
                  Icon(Icons.folder, color: theme.colorScheme.secondary),
                  title: Text(_getDirectoryName(directories[index - 1].path)),
                  onTap: () =>
                      _setDirectory(Directory(directories[index - 1].path)),
                );
              }
            },
            itemCount: count,
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    var path = (currentDirectory != null)
        ? currentDirectory?.path.replaceAll(FolderSelector.rootPath, "") ?? ''
        : "";

    return Container(
      decoration: BoxDecoration(
          border:
              Border(bottom: BorderSide(color: theme.primaryColor, width: 2))),
      padding: const EdgeInsets.all(8),
      child: Row(
        mainAxisSize: MainAxisSize.max,
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('선택된 폴더', style: theme.textTheme.labelMedium),
                const SizedBox(height: 4),
                Text(path, style: theme.textTheme.labelSmall)
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: IconButton(
                color: theme.primaryColor,
                icon: const Icon(Icons.check),
                onPressed: () {
                  if (!isDone) {
                    setState(() {
                      isDone = true;
                      ss.cancel();
                    });
                  }
                  Navigator.pop(context, currentDirectory);
                }),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.max,
      children: <Widget>[
        _buildHeader(context),
        Expanded(
          child: hasDstream ? _buildDirectories(context) : const Text(""),
        ),
      ],
    );
  }

  Future<void> _init() async {
    directories = [];
    initDir = data!.initDir;
    _setDirectory(initDir);
    hasDstream = true;
  }

  Future<void> _setDirectory(Directory? directory) async {
    setState(() {
      try {
        isDone = false;
        currentDirectory = directory;
        directories = [];
        dstream = directory!.list();
        ss = dstream.listen((item) {
          debugPrint(item.path);
          if (FileSystemEntity.isDirectorySync(item.path)) {
            setState(() {
              directories.add(item);
            });
          }
        }, onDone: () {
          setState(() {
            debugPrint("Done Path Find");
            isDone = true;
          });
        });
      } catch (e) {
        debugPrint(e.toString());
      }
    });
  }

  String _getDirectoryName(String directoryPath) {
    return directoryPath.split('/').last;
  }

  PicForWrapper? get data => PicForWrapper.of(context);
}
