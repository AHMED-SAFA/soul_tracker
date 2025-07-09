import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import 'package:map_tracker/controllers/connector_controller.dart';
import '../../../services/share_service.dart';
import '../../../widgets/common_alert_dialog.dart';
import '../../../widgets/custom_app_bar.dart';
import '../../../widgets/toast_widget.dart';

class GeneratedCodesPage extends StatefulWidget {
  const GeneratedCodesPage({super.key});

  @override
  State<GeneratedCodesPage> createState() => _GeneratedCodesPageState();
}

class _GeneratedCodesPageState extends State<GeneratedCodesPage> {
  final ConnectorController _connectorController = ConnectorController();
  late Future<List<Map<String, dynamic>>> _futureCodes;

  @override
  void initState() {
    super.initState();
    _futureCodes = _connectorController.displayAllGeneratedCodesDetails();
  }

  String formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return 'Unknown';
    final dt = timestamp.toDate();
    return DateFormat('dd-MM-yyyy, hh:mm a, zzzz').format(dt);
  }

  Future<void> _refreshData() async {
    setState(() {
      _futureCodes = _connectorController.displayAllGeneratedCodesDetails();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Generated Codes',
        titleColor: Colors.black,
        showBackButton: true,
        backgroundColor: Colors.white,
        showEnterCodeButton: false,
        showShareButton: false,
      ),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: FutureBuilder<List<Map<String, dynamic>>>(
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
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
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
                        ? [Text("No Trackers available")]
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
                              trailing: IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.red,
                                ),
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    barrierDismissible: false,
                                    builder: (_) => CommonAlertDialog(
                                      title: "Sure Delete Tracker?",
                                      backgroundColor: Color(0xff7f0505),
                                      subtitle:
                                          "Are you sure you want to Delete the Tracker?",
                                      icon: Icons.warning_amber_rounded,
                                      okButtonText: "Delete",
                                      cancelButtonText: "Cancel",
                                      onOkButtonTap: () async {
                                        try {
                                          await _connectorController
                                              .deleteConnector(
                                                code: code,
                                                connectorId: conn['uid'],
                                              );
                                          _refreshData();

                                          if (!context.mounted) return;

                                          ToastWidget.show(
                                            context: context,
                                            title: "Deleted successfully",
                                            iconColor: Colors.black,
                                            backgroundColor: Colors.green,
                                            icon: Icons.logout,
                                          );
                                          Navigator.pop(context, true);
                                        } catch (e) {
                                          Fluttertoast.showToast(
                                            msg: 'Delete failed: $e',
                                            toastLength: Toast.LENGTH_LONG,
                                            gravity: ToastGravity.BOTTOM,
                                            backgroundColor: Colors.red,
                                            textColor: Colors.white,
                                            fontSize: 14.0,
                                          );
                                          debugPrint("Delete Error: $e");
                                        }
                                      },
                                      onCancelButtonTap: () {
                                        Navigator.pop(context);
                                      },
                                    ),
                                  );
                                },
                              ),
                            );
                          }).toList(),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
