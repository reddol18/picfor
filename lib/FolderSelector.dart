import 'dart:io';

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import 'DirectoryList.dart';

class FolderSelector {
  static Future<Directory?> pick(
      {
        required BuildContext context,
        required Directory initDir,
      }) async {
    if (Platform.isAndroid) {
      Directory? directory = await showDialog<Directory>(
          context: context,
          barrierDismissible: true,
          builder: (BuildContext context) {
            return PicForWrapper(
              initDir: initDir,
              child: _PicForDialog(),
            );
          });

      return directory;
    } else {
      throw UnsupportedError('안드로이드만 지원합니다');
    }
  }

  static String rootPath = "/storage/emulated/0/";
}

class PicForWrapper extends InheritedWidget {
  final Directory? initDir;

  const PicForWrapper({
    super.key,
    required super.child,
    this.initDir,
  });

  static PicForWrapper? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType(aspect: PicForWrapper);
  }

  @override
  bool updateShouldNotify(InheritedWidget oldWidget) {
    return false;
  }
}

class _PicForDialog extends StatefulWidget {
  @override
  _PicForDialogState createState() => _PicForDialogState();
}

class _PicForDialogState extends State<_PicForDialog>
    with WidgetsBindingObserver {
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
        status = await Permission.manageExternalStorage.request();
      }

      if (status!.isDenied) {
        status = await Permission.manageExternalStorage.request();
      }

      if (status!.isPermanentlyDenied) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          backgroundColor: Colors.amber,
          content: Text('먼저 권한 설정을 해주세요'),
        ));
      }
    }
  }

  PicForWrapper? get data => PicForWrapper.of(context);

  Widget _buildBody(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    // print("status $status");
    if (status == null) {
      return const Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.max,
            children: <Widget>[
              CircularProgressIndicator(),
              SizedBox(height: 8),
              Text('권한 체크 중', textAlign: TextAlign.center)
            ],
          ));
    } else if (status == PermissionStatus.granted) {
      return const DirectoryList();
    } else if (status == PermissionStatus.denied) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            '기기 저장소 접근이 제한되어 있습니다',
            textAlign: TextAlign.center,
          ),
        ),
      );
    } else {
      return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.max,
            children: <Widget>[
              const Text("", textAlign: TextAlign.center),
              const SizedBox(height: 8),
              MaterialButton(
                  color: theme.primaryColor,
                  onPressed: _requestPermission,
                  child: const Text('권한 설정 하기'),
              )
            ],
          ));
    }
  }

  @override
  Widget build(BuildContext context) {
    _getPermissionStatus();
    return Dialog(
      child: _buildBody(context),
    );
  }
}
