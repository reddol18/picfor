import 'dart:io';

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import 'DirectoryList.dart';

class FolderPicker {
  static Future<Directory?> pick(
      {
        required BuildContext context,
        bool barrierDismissible = true,
        Color? backgroundColor,
        required Directory rootDirectory,
        String? message,
        ShapeBorder? shape}) async {
    if (Platform.isAndroid) {
      Directory? directory = await showDialog<Directory>(
          context: context,
          barrierDismissible: barrierDismissible,
          builder: (BuildContext context) {
            return DirectoryPickerData(
                backgroundColor: backgroundColor,
                child: _DirectoryPickerDialog(),
                message: message,
                rootDirectory: rootDirectory,
                shape: shape);
          });

      return directory;
    } else {
      throw UnsupportedError('DirectoryPicker is only supported on android!');
    }
  }

  static String rootPath = "/storage/emulated/0/";
}

class DirectoryPickerData extends InheritedWidget {
  final Color? backgroundColor;
  final String? message;
  final Directory? rootDirectory;
  final ShapeBorder? shape;

  DirectoryPickerData(
      {required Widget child,
        this.backgroundColor,
        this.message,
        this.rootDirectory,
        this.shape})
      : super(child: child);

  static DirectoryPickerData? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType(
        aspect: DirectoryPickerData);
  }

  @override
  bool updateShouldNotify(InheritedWidget oldWidget) {
    return false;
  }
}

class _DirectoryPickerDialog extends StatefulWidget {
  @override
  _DirectoryPickerDialogState createState() => _DirectoryPickerDialogState();
}

class _DirectoryPickerDialogState extends State<_DirectoryPickerDialog>
    with WidgetsBindingObserver {
  static final double spacing = 8;

  bool canPrompt = true;
  bool checkingForPermission = false;
  PermissionStatus? status;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);
    Future.delayed(Duration.zero).then((_) => _requestPermission());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _getPermissionStatus();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);

    super.dispose();
  }

  Future<void> _getPermissionStatus() async {
    var updatedStatus = await Permission.manageExternalStorage.status;
    final updatedCanPrompt = await Permission.manageExternalStorage.isGranted;

    setState(() {
      canPrompt = updatedCanPrompt;
      status = updatedStatus;
    });
  }

  Future<void> _requestPermission() async {
    if (canPrompt) {
      status = await Permission.manageExternalStorage.status;
      print(status);
      if (status!.isRestricted) {
        // We didn't ask for permission
        status = await Permission.manageExternalStorage.request();
      }

      if (status!.isDenied) {
        status = await Permission.manageExternalStorage.request();
      }

      if (status!.isPermanentlyDenied) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          backgroundColor: Colors.green,
          content: Text('Please setup Permission from App Permission Settings'),
        ));
      }
    }
  }

  DirectoryPickerData? get data => DirectoryPickerData.of(context);

  String? get message {
    if (data!.message == null) {
      return 'Please setup Permission from App Permission Settings\n\nApp needs read access to your device storage to load directories';
    } else {
      return data!.message;
    }
  }

  Widget _buildBody(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    // print("status $status");
    if (status == null) {
      return Padding(
          padding: EdgeInsets.all(spacing * 2),
          child: Column(
            children: <Widget>[
              CircularProgressIndicator(),
              SizedBox(height: spacing),
              Text('Checking permission', textAlign: TextAlign.center)
            ],
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.max,
          ));
    } else if (status == PermissionStatus.granted) {
      return DirectoryList();
    } else if (status == PermissionStatus.denied) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(spacing * 2),
          child: Text(
            'App is restricted from accessing your device storage',
            textAlign: TextAlign.center,
          ),
        ),
      );
    } else {
      return Padding(
          padding: EdgeInsets.all(spacing * 2),
          child: Column(
            children: <Widget>[
              Text(message!, textAlign: TextAlign.center),
              SizedBox(height: spacing),
              MaterialButton(
                  child: Text('Grant Permission'),
                  color: theme.primaryColor,
                  onPressed: _requestPermission)
            ],
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.max,
          ));
    }
  }

  @override
  Widget build(BuildContext context) {
    _getPermissionStatus();
    return Dialog(
      backgroundColor: data!.backgroundColor,
      child: _buildBody(context),
      shape: data!.shape,
    );
  }
}
