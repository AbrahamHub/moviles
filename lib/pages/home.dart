import 'dart:io';
import 'dart:convert'; // Para utf8.encode en testUpload
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:PhotoGuard/pages/ProfilePage.dart'; // Ajusta la ruta si es necesario
import 'package:firebase_auth/firebase_auth.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<String> accessibleFolders = [];
  Map<String, List<File>> folderImages = {};
  List<AssetEntity> galleryImages = [];
  double _uploadProgress = 0.0;
  double _downloadProgress = 0.0;
  List<File> downloadedImages = []; // Lista para almacenar las imágenes descargadas

  @override
  void initState() {
    super.initState();
    _initializeFirebase();
    _requestPermissionAndLoadFolders(); // Cargar imágenes locales automáticamente
  }

  Future<void> _initializeFirebase() async {
    await Firebase.initializeApp();
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      try {
        UserCredential userCredential = await FirebaseAuth.instance.signInAnonymously();
        user = userCredential.user;
        print('Usuario autenticado: ${user?.uid}');
      } catch (e) {
        print('Error durante la autenticación anónima: $e');
      }
    }
  }

  Future<void> _requestStoragePermission() async {
    if (Platform.isIOS) {
      final PermissionState result = await PhotoManager.requestPermissionExtend();
      if (result.isAuth) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Permiso de fotos concedido')),
        );
        _loadDefaultIOSGallery();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Permiso de fotos denegado')),
        );
      }
    } else {
      var status = await Permission.storage.status;
      if (status.isDenied || status.isPermanentlyDenied) {
        status = await Permission.storage.request();
      }

      if (status.isGranted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Permiso de almacenamiento concedido')),
        );
        _loadAndroidFolders();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Permiso de almacenamiento denegado')),
        );
      }
    }
  }

  Future<void> _requestPermissionAndLoadFolders() async {
    if (Platform.isIOS) {
      final PermissionState result = await PhotoManager.requestPermissionExtend();
      if (result.isAuth) {
        _loadDefaultIOSGallery();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Permiso no otorgado para acceder a la galería')),
        );
      }
    } else {
      var status = await Permission.storage.status;
      if (status.isDenied || status.isPermanentlyDenied) {
        await Permission.storage.request();
      }

      if (await Permission.storage.isGranted) {
        _loadAndroidFolders();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Permiso no otorgado para acceder a archivos')),
        );
      }
    }
  }

  Future<void> _loadAndroidFolders() async {
    // Obtener directorios comunes de imágenes en Android
    List<Directory> directories = [
      Directory('/storage/emulated/0/DCIM/Camera'),
      Directory('/storage/emulated/0/Pictures'),
      Directory('/storage/emulated/0/Download'),
      // Agrega otros directorios comunes si lo deseas
    ];

    for (var dir in directories) {
      if (await dir.exists()) {
        _loadImagesFromFolder(dir.path);
      }
    }
  }

  void _loadImagesFromFolder(String folderPath) {
    final folder = Directory(folderPath);
    final images = folder
        .listSync()
        .whereType<File>()
        .where((file) =>
    file.path.toLowerCase().endsWith('.jpg') ||
        file.path.toLowerCase().endsWith('.jpeg') ||
        file.path.toLowerCase().endsWith('.png'))
        .toList();

    setState(() {
      accessibleFolders.add(folderPath);
      folderImages[folderPath] = images;
    });
  }

  Future<void> _loadDefaultIOSGallery() async {
    final PermissionState ps = await PhotoManager.requestPermissionExtend();
    if (!ps.isAuth) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Permiso no otorgado para acceder a la galería')),
      );
      return;
    }

    final List<AssetPathEntity> albums = await PhotoManager.getAssetPathList(
      type: RequestType.image,
    );

    if (albums.isNotEmpty) {
      final List<AssetEntity> images = await albums[0].getAssetListPaged(
        page: 0,
        size: 100,
      );
      setState(() {
        galleryImages = images;
      });
    }
  }

  Future<void> _backupImagesToFirebase() async {
    if ((folderImages.isEmpty && Platform.isAndroid) ||
        (galleryImages.isEmpty && Platform.isIOS)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hay imágenes para respaldar')),
      );
      return;
    }

    try {
      final user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Usuario no autenticado')),
        );
        return;
      }

      final userId = user.uid;
      final storage = FirebaseStorage.instanceFor(
        bucket: 'gs://photoguard-e9739.firebasestorage.app', // Bucket corregido
      );

      print('Iniciando copia de seguridad para el usuario $userId');

      int totalImages = Platform.isAndroid
          ? folderImages.values.fold(0, (sum, list) => sum + list.length)
          : galleryImages.length;
      int uploadedImages = 0;

      if (Platform.isAndroid) {
        for (var folder in folderImages.values) {
          for (var image in folder) {
            if (await image.exists()) {
              final fileName = path.basename(image.path);
              final ref = storage.ref().child('$userId/$fileName');

              print('Subiendo archivo: ${image.path} a ${ref.fullPath}');

              try {
                UploadTask uploadTask = ref.putFile(image);

                uploadTask.snapshotEvents.listen((event) {
                  setState(() {
                    _uploadProgress = (uploadedImages +
                        event.bytesTransferred / event.totalBytes) /
                        totalImages;
                  });
                });

                await uploadTask;

                print('Archivo subido: $fileName');

                uploadedImages++;
              } catch (e) {
                print('Error al subir el archivo $fileName: $e');
              }
            } else {
              print('El archivo no existe: ${image.path}');
            }
          }
        }
      } else if (Platform.isIOS) {
        for (var asset in galleryImages) {
          final file = await asset.file;
          if (file != null && await file.exists()) {
            final fileName = path.basename(file.path);
            final ref = storage.ref().child('$userId/$fileName');

            print('Subiendo archivo: ${file.path} a ${ref.fullPath}');

            try {
              UploadTask uploadTask = ref.putFile(file);

              uploadTask.snapshotEvents.listen((event) {
                setState(() {
                  _uploadProgress = (uploadedImages +
                      event.bytesTransferred / event.totalBytes) /
                      totalImages;
                });
              });

              await uploadTask;

              print('Archivo subido: $fileName');

              uploadedImages++;
            } catch (e) {
              print('Error al subir el archivo $fileName: $e');
            }
          } else {
            print('El archivo no existe o no se pudo obtener: ${asset.id}');
          }
        }
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Copia de seguridad completada')),
      );

      print('Copia de seguridad completada');
    } catch (e) {
      print('Error durante la copia de seguridad: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error durante la copia de seguridad: $e')),
      );
    } finally {
      setState(() {
        _uploadProgress = 0.0;
      });
    }
  }

  Future<void> _restoreImagesFromFirebase() async {
    try {
      final user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Usuario no autenticado')),
        );
        return;
      }

      final userId = user.uid;
      final storage = FirebaseStorage.instanceFor(
        bucket: 'gs://photoguard-e9739.firebasestorage.app', // Bucket corregido
      );

      print('Obteniendo la lista de archivos en Firebase Storage para el usuario $userId');

      final ListResult result = await storage.ref().child(userId).listAll();

      print('Número de archivos encontrados: ${result.items.length}');

      if (result.items.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No hay imágenes respaldadas')),
        );
        return;
      }

      int totalFiles = result.items.length;
      int downloadedFiles = 0;

      List<File> tempImages = [];

      for (var ref in result.items) {
        try {
          final fileName = ref.name;

          // Obtener el directorio temporal o de aplicación para almacenar las imágenes
          final Directory appDocDir = await getApplicationDocumentsDirectory();
          final String filePath = path.join(appDocDir.path, 'restored_images', fileName);
          final File file = File(filePath);

          // Crear el directorio si no existe
          await file.parent.create(recursive: true);

          // Descargar el archivo desde Firebase Storage
          print('Descargando archivo: ${ref.fullPath}');
          await ref.writeToFile(file);

          tempImages.add(file);

          downloadedFiles++;

          setState(() {
            _downloadProgress = downloadedFiles / totalFiles;
          });
        } catch (e) {
          print('Error al descargar el archivo ${ref.fullPath}: $e');
          continue;
        }
      }

      setState(() {
        downloadedImages = tempImages;
        _downloadProgress = 0.0;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Imágenes restauradas exitosamente')),
      );
    } catch (e) {
      print('Error al restaurar imágenes: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al restaurar imágenes: $e')),
      );
    }
  }

  // Función de prueba para subir un archivo simple
  Future<void> testUpload() async {
    try {
      final storage = FirebaseStorage.instanceFor(
        bucket: 'gs://photoguard-e9739.firebasestorage.app', // Bucket corregido
      );
      final userId = FirebaseAuth.instance.currentUser?.uid ?? 'unknown_user';
      final ref = storage.ref().child('$userId/test.txt');
      final data = utf8.encode('Contenido de prueba');
      await ref.putData(data);
      print('Archivo de prueba subido exitosamente.');
    } catch (e) {
      print('Error al subir el archivo de prueba: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> imageWidgets = [];

    // Imágenes locales en Android
    if (Platform.isAndroid) {
      folderImages.forEach((folderPath, images) {
        imageWidgets.addAll(images.map((file) => Image.file(file, fit: BoxFit.cover)));
      });
    } else if (Platform.isIOS) {
      // Imágenes locales en iOS
      imageWidgets.addAll(galleryImages.map((asset) {
        return FutureBuilder<File?>(
          future: asset.file,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.done && snapshot.data != null) {
              return Image.file(snapshot.data!, fit: BoxFit.cover);
            }
            return const Center(child: CircularProgressIndicator());
          },
        );
      }));
    }

    // Añadir imágenes descargadas de Firebase Storage
    imageWidgets.addAll(downloadedImages.map((file) => Image.file(file, fit: BoxFit.cover)));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Fotos'),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.deepPurple,
              ),
              child: Text(
                'PhotoGuard',
                style: TextStyle(color: Colors.white, fontSize: 24),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.person, color: Colors.purple),
              title: const Text('Perfil'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ProfilePage(),
                  ),
                );
              },
            ),
            const Divider(),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
              child: Text(
                'Conceder acceso a:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black54,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.storage, color: Colors.purple),
              title: const Text('Almacenamiento local'),
              onTap: _requestStoragePermission,
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: Colors.red),
              title: const Text('Google Fotos'),
              onTap: _requestStoragePermission,
            ),
            ListTile(
              leading: const Icon(Icons.cloud, color: Colors.blue),
              title: const Text('Microsoft OneDrive'),
              onTap: _requestStoragePermission,
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.backup, color: Colors.green),
              title: const Text('Realizar copia de seguridad'),
              onTap: _backupImagesToFirebase,
            ),
            if (_uploadProgress > 0)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: LinearProgressIndicator(value: _uploadProgress),
              ),
            ListTile(
              leading: const Icon(Icons.restore, color: Colors.orange),
              title: const Text('Recuperar copia de seguridad'),
              onTap: _restoreImagesFromFirebase,
            ),
            if (_downloadProgress > 0)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: LinearProgressIndicator(value: _downloadProgress),
              ),
          ],
        ),
      ),
      body: imageWidgets.isEmpty
          ? const Center(
        child: Text('No se encontraron imágenes o no se concedieron permisos'),
      )
          : GridView.builder(
        padding: const EdgeInsets.all(8.0),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 4.0,
          mainAxisSpacing: 4.0,
        ),
        itemCount: imageWidgets.length,
        itemBuilder: (context, index) {
          return imageWidgets[index];
        },
      ),
    );
  }
}
