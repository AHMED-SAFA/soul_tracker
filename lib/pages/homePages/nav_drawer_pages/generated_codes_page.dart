import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../services/share_service.dart';

class GeneratedCodesPage extends StatefulWidget {
  const GeneratedCodesPage({super.key});

  @override
  State<GeneratedCodesPage> createState() => _GeneratedCodesPageState();
}

class _GeneratedCodesPageState extends State<GeneratedCodesPage> {
  final ShareService _shareService = ShareService();
  late Future<List<Map<String, dynamic>>> _futureCodes;

  @override
  void initState() {
    super.initState();
    _futureCodes = _shareService.displayAllGeneratedCodesDetails();
  }

  String formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return 'Unknown';
    final dt = timestamp.toDate();
    return DateFormat('dd-MM-yyyy, hh:mm a, zzzz').format(dt);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Generated Codes')),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _futureCodes,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final codes = snapshot.data ?? [];
          if (codes.isEmpty) {
            return const Center(child: Text('No codes generated yet.'));
          }

          return ListView.builder(
            itemCount: codes.length,
            itemBuilder: (context, index) {
              final codeEntry = codes[index];
              final code = codeEntry['code'];
              final isActive = codeEntry['isActive'];
              final expiresAt = formatTimestamp(codeEntry['expiresAt']);
              final connectors = List<Map<String, dynamic>>.from(
                codeEntry['connectors'],
              );

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ExpansionTile(
                  title: Text(
                    'Code: $code',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Expires: $expiresAt'),
                      Text(
                        'Active: ${isActive ? "Yes" : "No"}',
                        style: TextStyle(
                          color: isActive ? Colors.green : Colors.red,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  children: connectors.isEmpty
                      ? [const ListTile(title: Text('No connectors yet.'))]
                      : connectors.map((conn) {
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundImage: NetworkImage(
                                conn['profileImageUrl'] ?? '',
                              ),
                              child: conn['profileImageUrl'] == null
                                  ? const Icon(Icons.person)
                                  : null,
                            ),
                            title: Text(conn['name'] ?? 'Unknown'),
                            subtitle: Text(conn['email'] ?? ''),
                          );
                        }).toList(),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
