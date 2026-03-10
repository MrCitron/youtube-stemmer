import 'dart:ffi' as ffi;
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:ffi/ffi.dart';

typedef HelloWorldFunc = ffi.Void Function();
typedef HelloWorld = void Function();

typedef GetMetadataFunc = ffi.Pointer<Utf8> Function(ffi.Pointer<Utf8> url);
typedef GetMetadata = ffi.Pointer<Utf8> Function(ffi.Pointer<Utf8> url);

typedef ProgressCallbackFunc = ffi.Void Function(ffi.Double progress);

typedef DownloadAudioFunc = ffi.Pointer<Utf8> Function(
  ffi.Pointer<Utf8> url,
  ffi.Pointer<Utf8> outputPath,
  ffi.Pointer<ffi.NativeFunction<ProgressCallbackFunc>> cb,
);
typedef DownloadAudio = ffi.Pointer<Utf8> Function(
  ffi.Pointer<Utf8> url,
  ffi.Pointer<Utf8> outputPath,
  ffi.Pointer<ffi.NativeFunction<ProgressCallbackFunc>> cb,
);

typedef InitStemmerFunc = ffi.Pointer<Utf8> Function(ffi.Pointer<Utf8> modelPath, ffi.Pointer<Utf8> libPath);
typedef InitStemmer = ffi.Pointer<Utf8> Function(ffi.Pointer<Utf8> modelPath, ffi.Pointer<Utf8> libPath);

typedef SplitAudioFunc = ffi.Pointer<Utf8> Function(
  ffi.Pointer<Utf8> inputPath,
  ffi.Pointer<Utf8> outputDir,
  ffi.Pointer<Utf8> stemNames,
  ffi.Pointer<ffi.NativeFunction<ProgressCallbackFunc>> cb,
);
typedef SplitAudio = ffi.Pointer<Utf8> Function(
  ffi.Pointer<Utf8> inputPath,
  ffi.Pointer<Utf8> outputDir,
  ffi.Pointer<Utf8> stemNames,
  ffi.Pointer<ffi.NativeFunction<ProgressCallbackFunc>> cb,
);

typedef MixStemsFunc = ffi.Pointer<Utf8> Function(
  ffi.Pointer<Utf8> paths,
  ffi.Pointer<ffi.Double> weights,
  ffi.IntPtr weightsLen,
  ffi.Pointer<Utf8> outputPath,
);
typedef MixStems = ffi.Pointer<Utf8> Function(
  ffi.Pointer<Utf8> paths,
  ffi.Pointer<ffi.Double> weights,
  int weightsLen,
  ffi.Pointer<Utf8> outputPath,
);

typedef CreateZipFunc = ffi.Pointer<Utf8> Function(ffi.Pointer<Utf8> paths, ffi.Pointer<Utf8> outputPath);
typedef CreateZip = ffi.Pointer<Utf8> Function(ffi.Pointer<Utf8> paths, ffi.Pointer<Utf8> outputPath);

typedef CreateMp3ZipFunc = ffi.Pointer<Utf8> Function(ffi.Pointer<Utf8> paths, ffi.Pointer<Utf8> outputPath);
typedef CreateMp3Zip = ffi.Pointer<Utf8> Function(ffi.Pointer<Utf8> paths, ffi.Pointer<Utf8> outputPath);

typedef FreeStringFunc = ffi.Void Function(ffi.Pointer<Utf8> str);
typedef FreeString = void Function(ffi.Pointer<Utf8> str);

typedef CancelTasksFunc = ffi.Void Function();
typedef CancelTasks = void Function();

class BackendFFI {
  static final BackendFFI _instance = BackendFFI._internal();
  factory BackendFFI() => _instance;

  late final ffi.DynamicLibrary _lib;
  late final HelloWorld _helloWorld;
  late final GetMetadata _getMetadata;
  late final DownloadAudio _downloadAudio;
  late final InitStemmer _initStemmer;
  late final SplitAudio _splitAudio;
  late final MixStems _mixStems;
  late final CreateZip _createZip;
  late final CreateMp3Zip _createMp3Zip;
  late final FreeString _freeString;
  late final GetMetadata _checkStatus;
  late final CancelTasks _cancelTasks;

  BackendFFI._internal() {
    final libPath = _getLibraryPath();
    _lib = ffi.DynamicLibrary.open(libPath);

    _helloWorld = _lib.lookup<ffi.NativeFunction<HelloWorldFunc>>('HelloWorld').asFunction();

    _getMetadata = _lib.lookup<ffi.NativeFunction<GetMetadataFunc>>('GetMetadata').asFunction();

    _downloadAudio = _lib.lookup<ffi.NativeFunction<DownloadAudioFunc>>('DownloadAudio').asFunction();

    _initStemmer = _lib.lookup<ffi.NativeFunction<InitStemmerFunc>>('InitStemmer').asFunction();

    _splitAudio = _lib.lookup<ffi.NativeFunction<SplitAudioFunc>>('SplitAudio').asFunction();

    _mixStems = _lib.lookup<ffi.NativeFunction<MixStemsFunc>>('MixStems').asFunction();

    _createZip = _lib.lookup<ffi.NativeFunction<CreateZipFunc>>('CreateZip').asFunction();

    _createMp3Zip = _lib.lookup<ffi.NativeFunction<CreateMp3ZipFunc>>('CreateMp3Zip').asFunction();

    _freeString = _lib.lookup<ffi.NativeFunction<FreeStringFunc>>('FreeString').asFunction();

    _checkStatus = _lib.lookup<ffi.NativeFunction<GetMetadataFunc>>('CheckStatus').asFunction();

    _cancelTasks = _lib.lookup<ffi.NativeFunction<CancelTasksFunc>>('CancelTasks').asFunction();
  }

  void helloWorld() => _helloWorld();

  void cancelTasks() => _cancelTasks();

  String checkStatus() {
    try {
      final resPtr = _checkStatus(ffi.nullptr);
      if (resPtr == ffi.nullptr) return "Error: Null from CheckStatus";
      final res = resPtr.toDartString();
      _freeString(resPtr);
      return res;
    } catch (e) {
      return "Error: $e";
    }
  }

  String getMetadata(String url) {
    final urlPtr = url.toNativeUtf8();
    try {
      final resPtr = _getMetadata(urlPtr);
      if (resPtr == ffi.nullptr) {
        return "Error: Go library returned a null pointer for metadata";
      }
      final res = resPtr.toDartString();
      _freeString(resPtr);
      return res;
    } catch (e) {
      return "Error: FFI call failed: $e";
    } finally {
      malloc.free(urlPtr);
    }
  }

  String? downloadAudio(String url, String outputPath, {void Function(double)? onProgress}) {
    final urlPtr = url.toNativeUtf8();
    final pathPtr = outputPath.toNativeUtf8();

    ffi.NativeCallable<ProgressCallbackFunc>? callback;
    if (onProgress != null) {
      callback = ffi.NativeCallable<ProgressCallbackFunc>.isolateLocal((double progress) {
        onProgress(progress);
      });
    }

    try {
      final resPtr = _downloadAudio(urlPtr, pathPtr, callback?.nativeFunction ?? ffi.Pointer.fromAddress(0));
      if (resPtr == ffi.nullptr) {
        return null; // Success
      }
      final res = resPtr.toDartString();
      _freeString(resPtr);
      return res;
    } finally {
      malloc.free(urlPtr);
      malloc.free(pathPtr);
      callback?.close();
    }
  }

  String? initStemmer(String modelPath, String sharedLibPath) {
    final modelPtr = modelPath.toNativeUtf8();
    final libPtr = sharedLibPath.toNativeUtf8();
    try {
      final resPtr = _initStemmer(modelPtr, libPtr);
      if (resPtr == ffi.nullptr) {
        return null; // Success
      }
      final res = resPtr.toDartString();
      _freeString(resPtr);
      return res;
    } finally {
      malloc.free(modelPtr);
      malloc.free(libPtr);
    }
  }

  String? splitAudio(String inputPath, String outputDir, List<String> stemNames, {void Function(double)? onProgress}) {
    final inputPtr = inputPath.toNativeUtf8();
    final outputPtr = outputDir.toNativeUtf8();
    final stemsStr = stemNames.join(';');
    final stemsPtr = stemsStr.toNativeUtf8();

    ffi.NativeCallable<ProgressCallbackFunc>? callback;
    if (onProgress != null) {
      callback = ffi.NativeCallable<ProgressCallbackFunc>.isolateLocal((double progress) {
        onProgress(progress);
      });
    }

    try {
      final resPtr = _splitAudio(inputPtr, outputPtr, stemsPtr, callback?.nativeFunction ?? ffi.Pointer.fromAddress(0));
      if (resPtr == ffi.nullptr) {
        return null; // Success
      }
      final res = resPtr.toDartString();
      _freeString(resPtr);
      return res;
    } finally {
      malloc.free(inputPtr);
      malloc.free(outputPtr);
      malloc.free(stemsPtr);
      callback?.close();
    }
  }

  String? mixStems(List<String> paths, List<double> weights, String outputPath) {
    final pathsStr = paths.join(';');
    final pathsPtr = pathsStr.toNativeUtf8();
    final weightsPtr = malloc<ffi.Double>(weights.length);
    for (var i = 0; i < weights.length; i++) {
      weightsPtr[i] = weights[i];
    }
    final outPtr = outputPath.toNativeUtf8();
    try {
      final resPtr = _mixStems(pathsPtr, weightsPtr, weights.length, outPtr);
      if (resPtr == ffi.nullptr) {
        return null; // Success
      }
      final res = resPtr.toDartString();
      _freeString(resPtr);
      return res;
    } finally {
      malloc.free(pathsPtr);
      malloc.free(weightsPtr);
      malloc.free(outPtr);
    }
  }

  String? createZip(List<String> paths, String outputPath) {
    final pathsStr = paths.join(';');
    final pathsPtr = pathsStr.toNativeUtf8();
    final outPtr = outputPath.toNativeUtf8();
    try {
      final resPtr = _createZip(pathsPtr, outPtr);
      if (resPtr == ffi.nullptr) {
        return null; // Success
      }
      final res = resPtr.toDartString();
      _freeString(resPtr);
      return res;
    } finally {
      malloc.free(pathsPtr);
      malloc.free(outPtr);
    }
  }

  String? createMp3Zip(List<String> paths, String outputPath) {
    final pathsStr = paths.join(';');
    final pathsPtr = pathsStr.toNativeUtf8();
    final outPtr = outputPath.toNativeUtf8();
    try {
      final resPtr = _createMp3Zip(pathsPtr, outPtr);
      if (resPtr == ffi.nullptr) {
        return null; // Success
      }
      final res = resPtr.toDartString();
      _freeString(resPtr);
      return res;
    } finally {
      malloc.free(pathsPtr);
      malloc.free(outPtr);
    }
  }

  static String _getLibraryPath() {
    final String libName = _getBackendLibraryName();
    // ignore: avoid_print
    print('FFI: Searching for $libName...');

    // 1. Check next to the executable
    final exeDir = p.dirname(Platform.resolvedExecutable);
    final portablePath = p.join(exeDir, libName);
    if (File(portablePath).existsSync()) {
      // ignore: avoid_print
      print('FFI: Found $libName at $portablePath');
      return portablePath;
    }

    // 2. Check in Contents/Frameworks/ (macOS)
    if (Platform.isMacOS) {
      final frameworksPath = p.join(p.dirname(exeDir), 'Frameworks', libName);
      if (File(frameworksPath).existsSync()) {
        // ignore: avoid_print
        print('FFI: Found $libName at $frameworksPath');
        return frameworksPath;
      }
    }

    // 3. Check in local development folder
    final projectRoot = p.dirname(p.dirname(Platform.resolvedExecutable));
    final devPath = p.join(projectRoot, Platform.isLinux ? 'linux' : (Platform.isMacOS ? 'macos' : 'windows'), libName);
    if (File(devPath).existsSync()) {
      // ignore: avoid_print
      print('FFI: Found $libName at $devPath');
      return devPath;
    }

    // 4. Check in backend/ folder (root)
    final rootBackendPath = p.join(p.dirname(projectRoot), 'backend', libName);
    if (File(rootBackendPath).existsSync()) {
      // ignore: avoid_print
      print('FFI: Found $libName at $rootBackendPath');
      return rootBackendPath;
    }

    // 5. Check in lib/ subdirectory
    final libSubPath = p.join(exeDir, 'lib', libName);
    if (File(libSubPath).existsSync()) {
      // ignore: avoid_print
      print('FFI: Found $libName at $libSubPath');
      return libSubPath;
    }

    // ignore: avoid_print
    print('FFI: $libName not found in known paths, falling back to system path');
    return libName;
  }

  static String getOnnxRuntimePath() {
    final String libName = _getOnnxLibraryName();
    // ignore: avoid_print
    print('FFI: Searching for $libName...');

    final exeDir = p.dirname(Platform.resolvedExecutable);
    final portablePath = p.join(exeDir, libName);
    if (File(portablePath).existsSync()) {
      // ignore: avoid_print
      print('FFI: Found $libName at $portablePath');
      return portablePath;
    }

    if (Platform.isMacOS) {
      final frameworksPath = p.join(p.dirname(exeDir), 'Frameworks', libName);
      if (File(frameworksPath).existsSync()) {
        // ignore: avoid_print
        print('FFI: Found $libName at $frameworksPath');
        return frameworksPath;
      }
    }

    final projectRoot = p.dirname(p.dirname(Platform.resolvedExecutable));
    final devPath = p.join(projectRoot, Platform.isLinux ? 'linux' : (Platform.isMacOS ? 'macos' : 'windows'), libName);
    if (File(devPath).existsSync()) {
      // ignore: avoid_print
      print('FFI: Found $libName at $devPath');
      return devPath;
    }

    final rootBackendPath = p.join(p.dirname(projectRoot), 'backend', libName);
    if (File(rootBackendPath).existsSync()) {
      // ignore: avoid_print
      print('FFI: Found $libName at $rootBackendPath');
      return rootBackendPath;
    }

    final libSubPath = p.join(exeDir, 'lib', libName);
    if (File(libSubPath).existsSync()) {
      // ignore: avoid_print
      print('FFI: Found $libName at $libSubPath');
      return libSubPath;
    }

    // ignore: avoid_print
    print('FFI: $libName not found in known paths, falling back to system path');
    return libName;
  }

  static String _getBackendLibraryName() {
    if (Platform.isWindows) return 'libbackend.dll';
    if (Platform.isMacOS || Platform.isIOS) return 'libbackend.dylib';
    return 'libbackend.so';
  }

  static String _getOnnxLibraryName() {
    if (Platform.isWindows) return 'onnxruntime.dll';
    if (Platform.isMacOS || Platform.isIOS) return 'libonnxruntime.dylib';
    return 'libonnxruntime.so';
  }
}
