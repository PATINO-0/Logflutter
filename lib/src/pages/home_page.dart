import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';


class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  
  static const bucket = 'samuel';

  List<FileObject> _objects = [];
  bool _loading = true;

  User get _user => Supabase.instance.client.auth.currentUser!;
  String get _prefix => '${_user.id}/'; // p. ej. "uuid/"

  @override
  void initState() {
    super.initState();
    _refreshList();
  }

  Future<void> _refreshList() async {
    setState(() => _loading = true);
    try {
      
      final res = await Supabase.instance.client.storage
          .from(bucket)
          .list(path: _prefix);

      
      _objects = res.where((e) => !e.name.endsWith('/')).toList();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('List error: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _pickAndUpload() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: ['pdf', 'txt', 'doc', 'docx'],
    );
    if (result == null) return;

    final storage = Supabase.instance.client.storage.from(bucket);

    for (final file in result.files) {
      final filename = file.name;
      final path = '$_prefix$filename';

      try {
        if (kIsWeb) {
          final bytes = file.bytes!;
          await storage.uploadBinary(
            path,
            bytes,
            fileOptions: const FileOptions(upsert: true),
          );
        } else {
          final fpath = file.path!;
          await storage.upload(
            path,
            File(fpath),
            fileOptions: const FileOptions(upsert: true),
          );
        }
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload error ($filename): $e')),
        );
      }
    }

    await _refreshList();
  }

  Future<void> _downloadAndOpen(FileObject obj) async {
    try {
      final signedUrl = await Supabase.instance.client.storage
          .from(bucket)
          .createSignedUrl('$_prefix${obj.name}', 60 * 10); 

      if (kIsWeb) {
        final uri = Uri.parse(signedUrl);
        if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
          throw 'Could not launch download URL';
        }
      } else {
        final tempDir = await getTemporaryDirectory();
        final localPath = '${tempDir.path}/${obj.name}';
        final response = await http.get(Uri.parse(signedUrl));
        final file = File(localPath);
        await file.writeAsBytes(response.bodyBytes);
        await OpenFilex.open(file.path);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Download error: $e')));
    }
  }

  Future<void> _deleteObject(FileObject obj) async {
    try {
      await Supabase.instance.client.storage
          .from(bucket)
          .remove(['$_prefix${obj.name}']);
      await _refreshList();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Delete error: $e')));
    }
  }

  
  int? _objectSize(FileObject o) {
    final m = o.metadata;
    if (m == null) return null;
    final dynamic v =
        m['size'] ?? m['contentLength'] ?? m['content_length'] ?? m['Content-Length'];
    if (v is int) return v;
    if (v is String) return int.tryParse(v);
    return null;
  }

  DateTime? _toDate(dynamic v) {
    if (v == null) return null;
    if (v is DateTime) return v;
    if (v is String) return DateTime.tryParse(v);
    return null;
  }

  DateTime? _objectUpdatedAt(FileObject obj) {
    return _toDate(obj.updatedAt) ?? _toDate(obj.createdAt);
  }

  String _formatBytes(int? size) {
    if (size == null) return '--';
    const kb = 1024;
    const mb = kb * 1024;
    if (size >= mb) return '${(size / mb).toStringAsFixed(2)} MB';
    if (size >= kb) return '${(size / kb).toStringAsFixed(1)} KB';
    return '$size B';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFmt = DateFormat('yyyy-MM-dd HH:mm');

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Files'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: theme.colorScheme.secondary.withOpacity(.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.person_rounded, size: 18),
                    const SizedBox(width: 6),
                    Text(
                      Supabase.instance.client.auth.currentUser?.email ?? 'User',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ),
          ),
          IconButton(
            tooltip: 'Sign out',
            onPressed: () async {
              await Supabase.instance.client.auth.signOut();
            },
            icon: const Icon(Icons.logout_rounded),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _pickAndUpload,
        icon: const Icon(Icons.upload_rounded),
        label: const Text('Upload'),
      ),
      body: RefreshIndicator(
        onRefresh: _refreshList,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withOpacity(.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.cloud_upload_rounded),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Upload PDFs, TXT or Word files. Files are private and scoped to your profile.',
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      onPressed: _pickAndUpload,
                      icon: const Icon(Icons.add_rounded),
                      label: const Text('Add files'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            if (_loading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(30),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_objects.isEmpty)
              _EmptyState(onUpload: _pickAndUpload)
            else
              ..._objects.map((obj) {
                final updatedAt = _objectUpdatedAt(obj);
                final size = _objectSize(obj);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Material(
                    color: Colors.white,
                    elevation: 1,
                    borderRadius: BorderRadius.circular(14),
                    child: ListTile(
                      leading: _FileIcon(name: obj.name),
                      title: Text(obj.name, maxLines: 1, overflow: TextOverflow.ellipsis),
                      subtitle: Text(
                        '${_formatBytes(size)} • ${updatedAt != null ? dateFmt.format(updatedAt) : ''}',
                      ),
                      trailing: Wrap(
                        spacing: 4,
                        children: [
                          IconButton(
                            tooltip: 'Download / Open',
                            onPressed: () => _downloadAndOpen(obj),
                            icon: const Icon(Icons.download_rounded),
                          ),
                          IconButton(
                            tooltip: 'Delete',
                            onPressed: () => _deleteObject(obj),
                            icon: const Icon(Icons.delete_rounded, color: Colors.redAccent),
                          ),
                        ],
                      ),
                      onTap: () => _downloadAndOpen(obj),
                    ),
                  ),
                );
              }),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onUpload;
  const _EmptyState({required this.onUpload});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black12),
      ),
      child: Column(
        children: [
          Icon(Icons.folder_open_rounded, size: 44, color: theme.colorScheme.primary),
          const SizedBox(height: 10),
          Text('No files yet',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          const Text('Upload your first PDF, TXT or Word file.'),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: onUpload,
            icon: const Icon(Icons.upload_rounded),
            label: const Text('Upload now'),
          ),
        ],
      ),
    );
  }
}

class _FileIcon extends StatelessWidget {
  final String name;
  const _FileIcon({required this.name});

  @override
  Widget build(BuildContext context) {
    final ext = name.split('.').last.toLowerCase();
    IconData icon;
    if (ext == 'pdf') {
      icon = Icons.picture_as_pdf_rounded;
    } else if (ext == 'txt') {
      icon = Icons.description_rounded;
    } else if (ext == 'doc' || ext == 'docx') {
      icon = Icons.article_rounded;
    } else {
      icon = Icons.insert_drive_file_rounded;
    }
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withOpacity(.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon),
    );
  }
}
