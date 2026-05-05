import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:notes/models/note.dart';
import 'package:url_launcher/url_launcher.dart';

class NoteDialog extends StatefulWidget {
  final Note? note;

  const NoteDialog({super.key, this.note});

  @override
  State<NoteDialog> createState() => _NoteDialogState();
}

class _NoteDialogState extends State<NoteDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;

  String? _imageBase64;
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;
  double? _latitude;
  double? _longitude;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.note?.title ?? '');
    _descriptionController =
        TextEditingController(text: widget.note?.description ?? '');
    _imageBase64 = widget.note?.imageBase64;
    _latitude = widget.note?.latitude;
    _longitude = widget.note?.longitude;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  /// ================= IMAGE =================
  Future<void> _pickImage() async {
    try {
      final pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 70,
      );

      if (pickedFile != null) {
        setState(() => _isLoading = true);

        final bytes = await pickedFile.readAsBytes();
        _imageBase64 = base64Encode(bytes);

        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memilih gambar: $e')),
      );
    }
  }

  void _removeImage() {
    setState(() => _imageBase64 = null);
  }

  /// ================= LOCATION =================
  Future<void> _getLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Layanan lokasi mati")),
        );
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied ||
            permission == LocationPermission.deniedForever) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Izin lokasi ditolak")),
          );
          return;
        }
      }

      final position = await Geolocator.getCurrentPosition();

      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
      });
    } catch (e) {
      debugPrint("Error lokasi: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Gagal ambil lokasi")),
      );
    }
  }

  Future<void> _openMap() async {
    if (_latitude == null || _longitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Lokasi belum tersedia")),
      );
      return;
    }

    final url =
        'https://www.google.com/maps/search/?api=1&query=$_latitude,$_longitude';

    final uri = Uri.parse(url);
    final success = await launchUrl(uri,
        mode: LaunchMode.externalApplication);

    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Gagal buka maps")),
      );
    }
  }

  /// ================= UI =================
  @override
  Widget build(BuildContext context) {
    final isEditing = widget.note != null;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                Text(
                  isEditing ? "Edit Note" : "Add Note",
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 16),

                /// TITLE
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(labelText: "Title"),
                  validator: (v) =>
                      v!.isEmpty ? "Tidak boleh kosong" : null,
                ),

                const SizedBox(height: 10),

                /// DESC
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 3,
                  decoration: const InputDecoration(labelText: "Description"),
                  validator: (v) =>
                      v!.isEmpty ? "Tidak boleh kosong" : null,
                ),

                const SizedBox(height: 16),

                /// IMAGE
                if (_isLoading)
                  const CircularProgressIndicator()
                else if (_imageBase64 != null)
                  Column(
                    children: [
                      Image.memory(base64Decode(_imageBase64!),
                          height: 150),
                      TextButton(
                          onPressed: _removeImage,
                          child: const Text("Hapus gambar"))
                    ],
                  )
                else
                  ElevatedButton(
                      onPressed: _pickImage,
                      child: const Text("Tambah Gambar")),

                const SizedBox(height: 16),

                /// LOCATION BUTTON
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _getLocation,
                        icon: const Icon(Icons.my_location),
                        label: const Text("Ambil Lokasi"),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _openMap,
                        icon: const Icon(Icons.map),
                        label: const Text("Maps"),
                      ),
                    ),
                  ],
                ),

                /// SHOW COORD
                if (_latitude != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                        "Lat: $_latitude, Lng: $_longitude"),
                  ),

                const SizedBox(height: 20),

                /// ACTION BUTTON
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text("Cancel")),
                    ElevatedButton(
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          final note = Note(
                            id: widget.note?.id,
                            title: _titleController.text.trim(),
                            description:
                                _descriptionController.text.trim(),
                            imageBase64: _imageBase64,
                            createdAt: widget.note?.createdAt ??
                                DateTime.now(),
                            latitude: _latitude,   // ✅ FIX
                            longitude: _longitude, // ✅ FIX
                          );

                          Navigator.pop(context, note);
                        }
                      },
                      child: Text(isEditing ? "Save" : "Add"),
                    )
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}