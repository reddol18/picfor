/*
 * Copyright (c) 2020. Kapil. All Rights Reserved
 *  This file is protected by copyright and distributed under
 *  licenses restricting copying, distribution and decompilation.
 */
import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;

import 'FolderPicker.dart';

/// Internal widget used for rendering directory list
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

  @override
  void initState() {
    super.initState();
    // To make context available when init runs
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

  /*StreamBuilder _buildDirectories(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return StreamBuilder(
        stream: dirList(),
        builder: (context, snapshot) {
              debugPrint(snapshot.hasData.toString());
              int count = directories.length + 1;
              if (snapshot.connectionState == ConnectionState.waiting) {
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

        });
    /*

    if (directoryList == null) {
      return [
        Expanded(
          child: Center(
            child: CircularProgressIndicator(),
          ),
        )
      ];
    } else if (directoryList!.length == 0) {
      return [
        _buildBackNav(context),
        Expanded(
          child: Center(
              child: Text('Directory is empty!', textAlign: TextAlign.center)),
        )
      ];
    } else {
      return [
        Expanded(
          child: ListView(
            scrollDirection: Axis.vertical,
            children: [_buildBackNav(context)]
              ..addAll(directoryList!.map((directory) {
                return ListTile(
                  leading: Icon(Icons.folder, color: theme.colorScheme.secondary),
                  title: Text(_getDirectoryName(directory!)),
                  onTap: () => _setDirectory(directory),
                );
              })),
          ),
        )
      ];
    }*/
  }*/

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
          data!.allowFolderCreation!
              ? Padding(
              child: IconButton(
                  color: theme.primaryColor,
                  icon: Icon(Icons.create_new_folder),
                  onPressed: _createNewFolder),
              padding: EdgeInsets.only(left: spacing / 2))
              : SizedBox(height: 0, width: 0),
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



  Future<void> _createNewFolder() async {
    final newDirectory = await showDialog<Directory>(
        builder: (_) => _NewFolderDialog(data: data, parent: currentDirectory),
        context: context);

    if (newDirectory != null) {
      _setDirectory(newDirectory);
    }
  }

  bool isDone = true;
  late StreamSubscription ss;
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

class _NewFolderDialog extends StatefulWidget {
  final DirectoryPickerData? data;
  final Directory? parent;

  _NewFolderDialog({this.data, this.parent});

  @override
  _NewFolderDialogState createState() => _NewFolderDialogState();
}

class _NewFolderDialogState extends State<_NewFolderDialog> {
  String? name;
  bool isSubmitting = false;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
  }

  Future<void> _createDirectory() async {
    if (name == null || name!.trim() == '') {
      setState(() => errorMessage = 'Enter a valid folder name');
      return;
    }

    try {
      setState(() => isSubmitting = true);
      Directory newDirectory =
      await Directory(path.join(widget.parent!.path, name)).create();
      Navigator.pop(context, newDirectory);
    } catch (e) {
      setState(() => errorMessage = 'Failed to create folder');
    }
    setState(() => isSubmitting = false);
  }

  void _onNameChanged(String value) {
    setState(() {
      name = value;
      errorMessage = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: widget.data!.backgroundColor,
      content: TextField(
        autofocus: true,
        decoration: InputDecoration(errorText: errorMessage),
        onChanged: _onNameChanged,
      ),
      actions: <Widget>[
        MaterialButton(
            child: Text('Cancel'),
            onPressed: isSubmitting ? null : () => Navigator.pop(context)),
        MaterialButton(
          child: Text('Create Folder'),
          onPressed: isSubmitting ? null : _createDirectory,
        )
      ],
      shape: widget.data!.shape,
      title: Text('Create New Folder'),
    );
  }
}