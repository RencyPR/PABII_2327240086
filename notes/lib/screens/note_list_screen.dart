import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart'; // ✅ tambah ini
import 'package:notes/models/note.dart';
import 'package:notes/services/note_service.dart';
import 'package:notes/widgets/note_dialog.dart';

class NoteListScreen extends StatefulWidget {
  const NoteListScreen({super.key});

  @override
  State<NoteListScreen> createState() => _NoteListScreenState();
}

class _NoteListScreenState extends State<NoteListScreen> {
  final NoteService _noteService = NoteService();

  /// ================= MAP =================
  Future<void> _openMap(double lat, double lng) async {
    final uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$lat,$lng',
    );

    final success =
        await launchUrl(uri, mode: LaunchMode.externalApplication);

    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Gagal membuka Google Maps")),
      );
    }
  }

  /// ================= ADD =================
  Future<void> _addNote() async {
    final note = await showDialog<Note>(
      context: context,
      builder: (context) => const NoteDialog(),
    );

    if (note != null) {
      await _noteService.addNote(note);
    }
  }

  /// ================= EDIT =================
  Future<void> _editNote(Note note) async {
    final updatedNote = await showDialog<Note>(
      context: context,
      builder: (context) => NoteDialog(note: note),
    );

    if (updatedNote != null) {
      await _noteService.updateNote(updatedNote);
    }
  }

  /// ================= DELETE =================
  Future<void> _deleteNote(Note note) async {
    if (note.id != null) {
      await _noteService.deleteNote(note.id!);
    }
  }

  /// ================= FORMAT DATE =================
  String _formatDate(DateTime date) {
    return "${date.day}/${date.month}/${date.year}";
  }

  /// ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("My Notes"),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<List<Note>>(
        stream: _noteService.getNotes(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final notes = snapshot.data!;

          if (notes.isEmpty) {
            return const Center(child: Text("Belum ada note"));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: notes.length,
            itemBuilder: (context, index) {
              final note = notes[index];
              return _buildNoteCard(note);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addNote,
        child: const Icon(Icons.add),
      ),
    );
  }

  /// ================= CARD =================
  Widget _buildNoteCard(Note note) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// IMAGE
          if (note.imageBase64 != null && note.imageBase64!.isNotEmpty)
            Image.memory(
              base64Decode(note.imageBase64!),
              height: 200,
              width: double.infinity,
              fit: BoxFit.cover,
            ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// TITLE
                Text(
                  note.title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 8),

                /// DESC
                Text(note.description),

                const SizedBox(height: 10),

                /// ✅ LOKASI (FIX UTAMA DI SINI)
                if (note.latitude != null && note.longitude != null)
                  InkWell(
                    onTap: () =>
                        _openMap(note.latitude!, note.longitude!),
                    child: Row(
                      children: [
                        const Icon(Icons.location_on,
                            size: 16, color: Colors.red),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            "${note.latitude}, ${note.longitude}",
                            style: const TextStyle(
                              color: Colors.blue,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 10),

                /// DATE + ACTION
                Row(
                  children: [
                    Text(
                      _formatDate(note.createdAt),
                      style: const TextStyle(fontSize: 12),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => _editNote(note),
                      icon: const Icon(Icons.edit),
                    ),
                    IconButton(
                      onPressed: () => _deleteNote(note),
                      icon: const Icon(Icons.delete),
                    ),
                  ],
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}