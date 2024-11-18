import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Archivos'),
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () {
              Scaffold.of(context).openDrawer();
            },
          ),
        ),
        actions: [
          IconButton(
            icon: const CircleAvatar(
              backgroundImage: NetworkImage('https://media.istockphoto.com/id/1337144146/vector/default-avatar-profile-icon-vector.jpg?s=612x612&w=0&k=20&c=BIbFwuv7FxTWvh5S3vB6bkT0Qv8Vn8N5Ffseq84ClGI='),
            ),
            onPressed: () {
              // Acción al presionar la imagen de usuario
            },
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            const DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.deepPurple,
              ),
              child: Text(
                'Directorios',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                ),
              ),
            ),
            ListTile(
              leading: Icon(Icons.storage, color: Colors.purple),
              title: Text('Almacenamiento Interno'),
              onTap: () {},
            ),
            ListTile(
              leading: Icon(Icons.play_arrow, color: Colors.purple),
              title: Text('Google'),
              onTap: () {},
            ),
            ListTile(
              leading: Icon(Icons.favorite, color: Colors.purple),
              title: Text('Microsoft'),
              onTap: () {},
            ),
            ListTile(
              leading: Icon(Icons.delete, color: Colors.purple),
              title: Text('Trash'),
              onTap: () {},
            ),
            Divider(),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text('Carpetas'),
            ),
            ListTile(
              leading: Icon(Icons.folder, color: Colors.purple),
              title: Text('Label 1'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => FilesPage(folderName: 'Label 1'),
                  ),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.folder, color: Colors.purple),
              title: Text('Label 2'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => FilesPage(folderName: 'Label 2'),
                  ),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.folder, color: Colors.purple),
              title: Text('Label 3'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => FilesPage(folderName: 'Label 3'),
                  ),
                );
              },
            ),
          ],
        ),
      ),
      body: ListView.builder(
        itemCount: 5,
        itemBuilder: (context, index) {
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
            child: ListTile(
              leading: Icon(Icons.folder, color: Colors.purple, size: 40),
              title: Text('Folder $index'),
              subtitle: Text('Subhead'),
              onTap: () {
                // Navegar a la página de archivos de la carpeta seleccionada
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => FilesPage(folderName: 'Folder $index'),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class FilesPage extends StatelessWidget {
  final String folderName;

  const FilesPage({super.key, required this.folderName});

  @override
  Widget build(BuildContext context) {
    // Lista de archivos simulados para la carpeta seleccionada
    List<String> files = ['File 1', 'File 2', 'File 3', 'File 4'];

    return Scaffold(
      appBar: AppBar(
        title: Text(folderName),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: ListView.builder(
        itemCount: files.length,
        itemBuilder: (context, index) {
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
            child: ListTile(
              leading: Icon(Icons.insert_drive_file, color: Colors.blue, size: 40),
              title: Text(files[index]),
              subtitle: Text('Archivo $index'),
              onTap: () {
                // Acción al seleccionar un archivo
              },
            ),
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
