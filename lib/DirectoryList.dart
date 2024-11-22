import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';

import 'FolderPicker.dart';

class DirectoryList extends StatefulWidget {
  @override
  _DirectoryListState createState() => _DirectoryListState();
}

class _DirectoryListState extends State<DirectoryList> {
  static final double spacing = 8;

  Directory? rootDirectory;
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
      title: Text('..'),
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
      children: [
        Expanded(
          child: ListView.builder(
            scrollDirection: Axis.vertical,
            itemBuilder: (context, index) {
              if (index == 0) {
                if (directories.length == 0) {
                  return ListTile(
                    leading: CircularProgressIndicator(),
                    title: Text("탐색중"),
                    onTap: null,
                  );
                } else {
                  return _buildBackNav(context);
                }
              } else if (count == directories.length + 2 && index == count - 1) {
                return ListTile(
                  leading: CircularProgressIndicator(),
                  title: Text("탐색중"),
                  onTap: null,
                );
              } else {
                return ListTile(
                  leading: Icon(
                      Icons.folder,
                      color: theme.colorScheme.secondary),
                  title: Text(_getDirectoryName(
                      directories[index - 1].path)),
                  onTap: () =>
                      _setDirectory(
                          Directory(directories[index - 1].path)),
                );
              }
            },
            itemCount: count,
          ),
        ),
      ],
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisAlignment: MainAxisAlignment.start,
      mainAxisSize: MainAxisSize.max,
    );
  }

  Widget _buildHeader(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    var path = (currentDirectory != null)
        ? currentDirectory?.path.replaceAll(FolderPicker.rootPath, "") ?? ''
        : "";

    return Container(
      child: Row(
        children: <Widget>[
          Expanded(
            child: Column(
              children: [
                Text('Selected directory', style: theme.textTheme.labelMedium),
                SizedBox(height: spacing / 2),
                Text(path, style: theme.textTheme.labelSmall)
              ],
              crossAxisAlignment: CrossAxisAlignment.start,
            ),
          ),
          Padding(
            padding: EdgeInsets.only(left: spacing / 2),
            child: IconButton(
                color: theme.primaryColor,
                icon: Icon(Icons.check),
                onPressed: () {
                  if (!isDone) {
                    setState(() {
                      isDone = true;
                      if (ss != null) {
                        ss.cancel();
                      }
                    });
                  }
                  Navigator.pop(context, currentDirectory);
                }),
          )
        ],
        mainAxisSize: MainAxisSize.max,
      ),
      decoration: BoxDecoration(
          border:
          Border(bottom: BorderSide(color: theme.primaryColor, width: 2))),
      padding: EdgeInsets.all(spacing),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        _buildHeader(context),
        Expanded(
          child: hasDstream ? _buildDirectories(context) : Text(""),
        ),
      ],
      mainAxisSize: MainAxisSize.max,
    );
  }

  Future<void> _init() async {
    directories = [];
    rootDirectory = data!.rootDirectory;
    _setDirectory(rootDirectory);
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
        // Ignore when tried navigating to directory that does not exist
        // or to which user does not have permission to read
        print(e);
      }
    });
  }

  String _getDirectoryName(String directoryPath) {
    return directoryPath.split('/').last;
  }

  DirectoryPickerData? get data => DirectoryPickerData.of(context);
}
