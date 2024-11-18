import 'dart:io';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:file_picker/file_picker.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:PhotoGuard/pages/ProfilePage.dart'; // Asegúrate de ajustar la ruta correcta
import 'package:firebase_auth/firebase_auth.dart';

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

  @override
  void initState() {
    super.initState();
    _initializeFirebase();
  }

  Future<void> _initializeFirebase() async {
    await Firebase.initializeApp();
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      await FirebaseAuth.instance.signInAnonymously();
    }
  }

  Future<void> _requestStoragePermission() async {
    if (Platform.isIOS) {
      final PermissionState result = await PhotoManager.requestPermissionExtend();
      if (result.isAuth) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Permiso de fotos concedido')),
        );
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
        _loadAndroidFolder();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Permiso no otorgado para acceder a archivos')),
        );
      }
    }
  }

  Future<void> _loadAndroidFolder() async {
    String? selectedFolder = await FilePicker.platform.getDirectoryPath();
    if (selectedFolder != null) {
      _loadImagesFromFolder(selectedFolder);
    }
  }

  void _loadImagesFromFolder(String folderPath) {
    final folder = Directory(folderPath);
    final images = folder
        .listSync()
        .whereType<File>()
        .where((file) =>
    file.path.endsWith('.jpg') ||
        file.path.endsWith('.jpeg') ||
        file.path.endsWith('.png'))
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
          bucket: 'gs://photoguard-e9739.firebasestorage.app');

      int totalImages = Platform.isAndroid
          ? folderImages.values.fold(0, (sum, list) => sum + list.length)
          : galleryImages.length;
      int uploadedImages = 0;

      if (Platform.isAndroid) {
        // Procesamos las imágenes de folderImages para Android
        for (var folder in folderImages.values) {
          for (var image in folder) {
            final fileName = image.path.split('/').last;
            final ref = storage.ref('$userId/$fileName');

            UploadTask uploadTask = ref.putFile(image);

            uploadTask.snapshotEvents.listen((event) {
              setState(() {
                _uploadProgress = (uploadedImages +
                    event.bytesTransferred / event.totalBytes) /
                    totalImages;
              });
            });

            await uploadTask;

            uploadedImages++;
          }
        }
      } else if (Platform.isIOS) {
        // Procesamos las imágenes de galleryImages para iOS
        for (var asset in galleryImages) {
          final file = await asset.file;
          if (file != null) {
            final fileName = file.path.split('/').last;
            final ref = storage.ref('$userId/$fileName');

            UploadTask uploadTask = ref.putFile(file);

            uploadTask.snapshotEvents.listen((event) {
              setState(() {
                _uploadProgress = (uploadedImages +
                    event.bytesTransferred / event.totalBytes) /
                    totalImages;
              });
            });

            await uploadTask;

            uploadedImages++;
          }
        }
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Copia de seguridad completada')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error durante la copia de seguridad: $e')),
      );
    } finally {
      setState(() {
        _uploadProgress = 0.0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fotos'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _requestPermissionAndLoadFolders,
          ),
        ],
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
          ],
        ),
      ),
      body: Platform.isAndroid
          ? accessibleFolders.isEmpty
          ? const Center(
        child: Text('Presiona el ícono de refrescar para buscar carpetas'),
      )
          : ListView.builder(
        itemCount: accessibleFolders.length,
        itemBuilder: (context, index) {
          String folderPath = accessibleFolders[index];
          String folderName = folderPath.split('/').last;
          return Card(
            margin: const EdgeInsets.symmetric(
                vertical: 8.0, horizontal: 16.0),
            child: ListTile(
              leading: const Icon(Icons.folder, color: Colors.purple),
              title: Text(folderName),
              subtitle: Text(
                  '${folderImages[folderPath]?.length ?? 0} imágenes'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => FilesPage(
                      folderName: folderName,
                      images: folderImages[folderPath] ?? [],
                    ),
                  ),
                );
              },
            ),
          );
        },
      )
          : galleryImages.isEmpty
          ? const Center(
        child:
        Text('Presiona el ícono de refrescar para cargar imágenes'),
      )
          : GridView.builder(
        padding: const EdgeInsets.all(8.0),
        gridDelegate:
        const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 4.0,
          mainAxisSpacing: 4.0,
        ),
        itemCount: galleryImages.length,
        itemBuilder: (context, index) {
          return FutureBuilder<File?>(
            future: galleryImages[index].file,
            builder: (context, snapshot) {
              if (snapshot.connectionState ==
                  ConnectionState.done &&
                  snapshot.data != null) {
                return Image.file(
                  snapshot.data!,
                  fit: BoxFit.cover,
                );
              }
              return const Center(
                  child: CircularProgressIndicator());
            },
          );
        },
      ),
    );
  }
}

class FilesPage extends StatelessWidget {
  final String folderName;
  final List<File> images;

  const FilesPage({super.key, required this.folderName, required this.images});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(folderName),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: images.isEmpty
          ? const Center(child: Text('No hay imágenes en esta carpeta.'))
          : GridView.builder(
        padding: const EdgeInsets.all(8.0),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 4.0,
          mainAxisSpacing: 4.0,
        ),
        itemCount: images.length,
        itemBuilder: (context, index) {
          return Image.file(
            images[index],
            fit: BoxFit.cover,
          );
        },
      ),
    );
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MaterialApp(home: HomePage()));
}
