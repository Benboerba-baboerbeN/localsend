import 'dart:io';

import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/material.dart';
import 'package:localsend_app/config/init.dart';
import 'package:localsend_app/gen/strings.g.dart';
import 'package:localsend_app/pages/home_page_controller.dart';
import 'package:localsend_app/pages/tabs/receive_tab.dart';
import 'package:localsend_app/pages/tabs/send_tab.dart';
import 'package:localsend_app/pages/tabs/settings_tab.dart';
import 'package:localsend_app/provider/last_transfer_provider.dart';
import 'package:localsend_app/provider/selection/selected_sending_files_provider.dart';
import 'package:localsend_app/provider/skin_provider.dart';
import 'package:localsend_app/util/native/cross_file_converters.dart';
import 'package:localsend_app/widget/floating_navigation_bar.dart';
import 'package:localsend_app/widget/skin_background.dart';
import 'package:refena_flutter/refena_flutter.dart';

enum HomeTab {
  receive(Icons.wifi),
  send(Icons.send),
  settings(Icons.settings)
  ;

  const HomeTab(this.icon);

  final IconData icon;

  String get label {
    switch (this) {
      case HomeTab.receive:
        return t.receiveTab.title;
      case HomeTab.send:
        return t.sendTab.title;
      case HomeTab.settings:
        return t.settingsTab.title;
    }
  }
}

class HomePage extends StatefulWidget {
  final HomeTab initialTab;

  /// It is important for the initializing step
  /// because the first init clears the cache
  final bool appStart;

  const HomePage({
    required this.initialTab,
    required this.appStart,
    super.key,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with Refena {
  bool _dragAndDropIndicator = false;

  @override
  void initState() {
    super.initState();

    ensureRef((ref) async {
      ref.redux(homePageControllerProvider).dispatch(ChangeTabAction(widget.initialTab));
      await postInit(context, ref, widget.appStart);
    });
  }

  @override
  Widget build(BuildContext context) {
    Translations.of(context); // rebuild on locale change
    final vm = context.watch(homePageControllerProvider);
    final wallpaperPath = context.watch(skinProvider.select((state) => state.wallpaperPath));
    final lastTransfer = context.watch(lastTransferProvider);
    final bottomOverlayHeight = lastTransfer == null ? 94.0 : 132.0;

    return SkinBackground(
      wallpaperPath: wallpaperPath,
      child: DropTarget(
        onDragEntered: (_) {
          setState(() {
            _dragAndDropIndicator = true;
          });
        },
        onDragExited: (_) {
          setState(() {
            _dragAndDropIndicator = false;
          });
        },
        onDragDone: (event) async {
          // the drop may contain a mix of files and directories
          final droppedDirectories = event.files.where((file) => Directory(file.path).existsSync()).toList();
          final droppedFiles = event.files.where((file) => !Directory(file.path).existsSync()).toList();

          for (final directory in droppedDirectories) {
            await ref.redux(selectedSendingFilesProvider).dispatchAsync(AddDirectoryAction(directory.path));
          }

          if (droppedFiles.isNotEmpty) {
            await ref
                .redux(selectedSendingFilesProvider)
                .dispatchAsync(
                  AddFilesAction(
                    files: droppedFiles,
                    converter: CrossFileConverters.convertXFile,
                  ),
                );
          }
          vm.changeTab(HomeTab.send);
        },
        child: Scaffold(
          backgroundColor: wallpaperPath == null ? null : Colors.transparent,
          body: Stack(
            children: [
              Positioned.fill(
                child: SafeArea(
                  bottom: false,
                  child: PageView(
                    controller: vm.controller,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      Padding(
                        padding: EdgeInsets.only(bottom: bottomOverlayHeight),
                        child: const ReceiveTab(),
                      ),
                      Padding(
                        padding: EdgeInsets.only(bottom: bottomOverlayHeight),
                        child: const SendTab(),
                      ),
                      Padding(
                        padding: EdgeInsets.only(bottom: bottomOverlayHeight),
                        child: const SettingsTab(),
                      ),
                    ],
                  ),
                ),
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: SafeArea(
                  top: false,
                  minimum: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (lastTransfer != null) ...[
                        LastTransferStatusBar(record: lastTransfer),
                        const SizedBox(height: 6),
                      ],
                      FloatingNavigationBar(
                        selectedIndex: vm.currentTab.index,
                        onDestinationSelected: (index) => vm.changeTab(HomeTab.values[index]),
                        destinations: HomeTab.values.map((tab) {
                          return NavigationDestination(icon: Icon(tab.icon), label: tab.label);
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ),
              if (_dragAndDropIndicator)
                Positioned.fill(
                  child: ColoredBox(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.file_download, size: 128),
                        const SizedBox(height: 30),
                        Text(t.sendTab.placeItems, style: Theme.of(context).textTheme.titleLarge),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
