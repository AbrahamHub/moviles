import 'dart:io';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:file_picker/file_picker.dart';
import 'package:photo_manager/photo_manager.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<String> accessibleFolders = [];
  Map<String, List<File>> folderImages = {};
  List<AssetEntity> galleryImages = [];

  // Solicita permisos y lista carpetas
  Future<void> _requestPermissionAndLoadFolders() async {
    if (Platform.isIOS) {
      // Solicitar permiso de fotos en iOS
      final PermissionState result = await PhotoManager.requestPermissionExtend();
      if (result.isAuth) {
        _loadDefaultIOSGallery();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Permiso no otorgado para acceder a la galería')),
        );
      }
    } else {
      // Solicitar permiso de almacenamiento en Android
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

  // Abre un selector de carpetas en Android
  Future<void> _loadAndroidFolder() async {
    String? selectedFolder = await FilePicker.platform.getDirectoryPath();
    if (selectedFolder != null) {
      _loadImagesFromFolder(selectedFolder);
    }
  }

  // Carga imágenes desde una carpeta específica
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

  // Cargar imágenes desde la galería en iOS
  Future<void> _loadDefaultIOSGallery() async {
    final List<AssetPathEntity> albums = await PhotoManager.getAssetPathList(
      type: RequestType.image,
    );

    if (albums.isNotEmpty) {
      final List<AssetEntity> images = await albums[0].getAssetListPaged(
        page: 0, // Primera página
        size: 100, // Máximo 100 imágenes por página
      );
      setState(() {
        galleryImages = images;
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
                'Directorios',
                style: TextStyle(color: Colors.white, fontSize: 24),
              ),
            ),
            if (Platform.isAndroid) ...accessibleFolders.map((folderPath) {
              String folderName = folderPath.split('/').last; // Extrae el nombre de la carpeta
              return ListTile(
                leading: const Icon(Icons.folder, color: Colors.purple),
                title: Text(folderName),
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
              );
            }).toList(),
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
        child: Text('No hay imágenes disponibles.'),
      )
          : GridView.builder(
        padding: const EdgeInsets.all(8.0),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 4.0,
          mainAxisSpacing: 4.0,
        ),
        itemCount: galleryImages.length,
        itemBuilder: (context, index) {
          return FutureBuilder<File?>(
            future: galleryImages[index].file,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.done &&
                  snapshot.data != null) {
                return Image.file(
                  snapshot.data!,
                  fit: BoxFit.cover,
                );
              }
              return const Center(child: CircularProgressIndicator());
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

void main() {
  runApp(const MaterialApp(
    home: HomePage(),
  ));
}
