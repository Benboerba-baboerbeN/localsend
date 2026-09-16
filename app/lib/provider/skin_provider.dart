import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:localsend_app/provider/persistence_provider.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:refena_flutter/refena_flutter.dart';

final skinProvider = NotifierProvider<SkinService, SkinState>((ref) {
  return SkinService(ref.read(persistenceProvider));
});

@immutable
class SkinState {
  final String? wallpaperPath;
  final String? homeLogoPath;

  const SkinState({required this.wallpaperPath, required this.homeLogoPath});
}

@immutable
class HomeLogoCrop {
  final double zoom;
  final double offsetX;
  final double offsetY;

  const HomeLogoCrop({required this.zoom, required this.offsetX, required this.offsetY});
}

class SkinService extends PureNotifier<SkinState> {
  final PersistenceService _persistence;

  SkinService(this._persistence);

  @override
  SkinState init() {
    final wallpaperPath = _persistence.getWallpaperPath();
    final homeLogoPath = _persistence.getHomeLogoPath();
    return SkinState(
      wallpaperPath: wallpaperPath != null && File(wallpaperPath).existsSync() ? wallpaperPath : null,
      homeLogoPath: homeLogoPath != null && File(homeLogoPath).existsSync() ? homeLogoPath : null,
    );
  }

  Future<void> setWallpaper(String sourcePath) async {
    final source = File(sourcePath);
    if (!await source.exists()) {
      throw const FileSystemException('The selected wallpaper does not exist.');
    }

    final supportDirectory = await getApplicationSupportDirectory();
    final skinDirectory = Directory(p.join(supportDirectory.path, 'skin'));
    await skinDirectory.create(recursive: true);

    final extension = p.extension(sourcePath).toLowerCase();
    final target = File(p.join(skinDirectory.path, 'wallpaper_${DateTime.now().microsecondsSinceEpoch}$extension'));
    await source.copy(target.path);

    final previousPath = state.wallpaperPath;
    await _persistence.setWallpaperPath(target.path);
    state = SkinState(wallpaperPath: target.path, homeLogoPath: state.homeLogoPath);

    if (previousPath != null && previousPath != target.path) {
      await FileImage(File(previousPath)).evict();
      final previous = File(previousPath);
      if (await previous.exists()) {
        await previous.delete();
      }
    }
  }

  Future<void> clearWallpaper() async {
    final previousPath = state.wallpaperPath;
    await _persistence.setWallpaperPath(null);
    state = SkinState(wallpaperPath: null, homeLogoPath: state.homeLogoPath);

    if (previousPath != null) {
      await FileImage(File(previousPath)).evict();
      final previous = File(previousPath);
      if (await previous.exists()) {
        await previous.delete();
      }
    }
  }

  Future<void> setHomeLogo(String sourcePath, {required HomeLogoCrop crop}) async {
    final source = File(sourcePath);
    if (!await source.exists()) {
      throw const FileSystemException('The selected home logo does not exist.');
    }

    final supportDirectory = await getApplicationSupportDirectory();
    final skinDirectory = Directory(p.join(supportDirectory.path, 'skin'));
    await skinDirectory.create(recursive: true);

    final target = File(p.join(skinDirectory.path, 'home_logo_${DateTime.now().microsecondsSinceEpoch}.png'));
    final croppedBytes = await compute(
      _cropHomeLogo,
      (sourcePath: sourcePath, zoom: crop.zoom, offsetX: crop.offsetX, offsetY: crop.offsetY),
    );
    await target.writeAsBytes(croppedBytes, flush: true);

    final previousPath = state.homeLogoPath;
    await _persistence.setHomeLogoPath(target.path);
    state = SkinState(wallpaperPath: state.wallpaperPath, homeLogoPath: target.path);

    if (previousPath != null && previousPath != target.path) {
      await FileImage(File(previousPath)).evict();
      final previous = File(previousPath);
      if (await previous.exists()) {
        await previous.delete();
      }
    }
  }

  Future<void> clearHomeLogo() async {
    final previousPath = state.homeLogoPath;
    await _persistence.setHomeLogoPath(null);
    state = SkinState(wallpaperPath: state.wallpaperPath, homeLogoPath: null);

    if (previousPath != null) {
      await FileImage(File(previousPath)).evict();
      final previous = File(previousPath);
      if (await previous.exists()) {
        await previous.delete();
      }
    }
  }
}

Uint8List _cropHomeLogo(({String sourcePath, double zoom, double offsetX, double offsetY}) request) {
  final decoded = img.decodeImage(File(request.sourcePath).readAsBytesSync());
  if (decoded == null) {
    throw const FormatException('The selected home logo could not be decoded.');
  }

  final source = img.bakeOrientation(decoded);
  final minDimension = math.min(source.width, source.height);
  final zoom = request.zoom.clamp(1.0, 4.0);
  final cropSize = (minDimension / zoom).round().clamp(1, minDimension);
  final maxLeft = source.width - cropSize;
  final maxTop = source.height - cropSize;
  final left = (((request.offsetX.clamp(-1.0, 1.0) + 1) / 2) * maxLeft).round().clamp(0, maxLeft);
  final top = (((request.offsetY.clamp(-1.0, 1.0) + 1) / 2) * maxTop).round().clamp(0, maxTop);
  final cropped = img.copyCrop(source, x: left, y: top, width: cropSize, height: cropSize);
  final resized = img.copyResize(cropped, width: 512, height: 512, interpolation: img.Interpolation.cubic);
  return Uint8List.fromList(img.encodePng(resized, level: 6));
}
