import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: ImageEncryptor(),
    );
  }
}

class ImageEncryptor extends StatefulWidget {
  const ImageEncryptor({super.key});

  @override
  State<ImageEncryptor> createState() => _ImageEncryptorState();
}

class _ImageEncryptorState extends State<ImageEncryptor> {
  File? _image; // File for displaying the image
  File? _decryptedImage; // File for displaying decrypted image
  File? _encryptedFile;
  final ImagePicker _picker = ImagePicker();
  final key = encrypt.Key.fromLength(32); // AES requires a key of 16, 24, or 32 bytes
  final iv = encrypt.IV.fromLength(16); // AES requires a 16-byte IV

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
        _decryptedImage = null; // Clear any previously decrypted image
      });
    }
  }

  Future<void> _pickEncryptedFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['aes'], // Limit to encrypted files
    );

    if (result != null) {
      setState(() {
        _encryptedFile = File(result.files.single.path!);
        _image = null; // Clear the currently displayed image
        _decryptedImage = null; // Clear any previously decrypted image
      });
    }
  }

  Future<void> _encryptImage() async {
    if (_image == null) return;

    final bytes = await _image!.readAsBytes();
    final encrypter = encrypt.Encrypter(encrypt.AES(key)); // AES encryption
    final encrypted = encrypter.encryptBytes(bytes, iv: iv);

    final directory = await getApplicationDocumentsDirectory();
    final encryptedPath = '${directory.path}/encrypted_image.aes';

    await File(encryptedPath).writeAsBytes(encrypted.bytes);

    setState(() {
      _image = null; // Remove the displayed image after encryption
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Image encrypted and saved at $encryptedPath')),
    );
  }

  Future<void> _decryptImage() async {
    if (_encryptedFile == null) return;

    final bytes = await _encryptedFile!.readAsBytes();
    final encrypter = encrypt.Encrypter(encrypt.AES(key)); // AES decryption
    final decrypted = encrypter.decryptBytes(encrypt.Encrypted(bytes), iv: iv);

    final directory = await getApplicationDocumentsDirectory();
    final decryptedPath = '${directory.path}/decrypted_image.png';

    final decryptedFile = File(decryptedPath);
    await decryptedFile.writeAsBytes(decrypted);

    setState(() {
      _decryptedImage = decryptedFile; // Display the decrypted image
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Image decrypted and saved at $decryptedPath')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Image Encryptor'),
        centerTitle: true, // Center the title
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _image != null
                ? Image.file(
              _image!,
              height: 200,
            )
                : _decryptedImage != null
                ? Image.file(
              _decryptedImage!,
              height: 200,
            )
                : const Text('No image selected or decrypted'),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _pickImage,
              child: const Text('Pick Image'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _encryptImage,
              child: const Text('Encrypt Image'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _pickEncryptedFile,
              child: const Text('Pick Encrypted File'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _decryptImage,
              child: const Text('Decrypt Image'),
            ),
          ],
        ),
      ),
    );
  }
}
