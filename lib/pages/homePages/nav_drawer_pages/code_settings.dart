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

class _GeneratedCodesPageState extends State<GeneratedCodesPage>
    with TickerProviderStateMixin {
  final ConnectorController _connectorController = ConnectorController();
  late Future<List<Map<String, dynamic>>> _futureCodes;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _futureCodes = _connectorController.displayAllGeneratedCodesDetails();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOutCubic,
          ),
        );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  String formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return 'Unknown';
    final dt = timestamp.toDate();
    return DateFormat('dd MMM yyyy, hh:mm a').format(dt);
  }

  Future<void> _refreshData() async {
    setState(() {
      _futureCodes = _connectorController.displayAllGeneratedCodesDetails();
    });
    _animationController.reset();
    _animationController.forward();
  }

  Widget _buildEmptyState() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A237E).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Icon(
                  Icons.code_off,
                  size: 80,
                  color: const Color(0xFF1A237E).withOpacity(0.6),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'No Codes Generated Yet',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Generate your first tracking code to get started',
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCodeCard(Map<String, dynamic> codeEntry, int index) {
    final code = codeEntry['code'];
    final isActive = codeEntry['isActive'];
    final expiresAt = formatTimestamp(codeEntry['expiresAt']);
    final connectors = List<Map<String, dynamic>>.from(codeEntry['connectors']);

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.white, Colors.grey[50]!],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              tilePadding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 8,
              ),
              childrenPadding: const EdgeInsets.only(bottom: 12),
              leading: Container(
                padding: const EdgeInsets.all(10), // Reduced from 12
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [const Color(0xFF1A237E), const Color(0xFF3949AB)],
                  ),
                  borderRadius: BorderRadius.circular(10), // Reduced from 12
                ),
                child: const Icon(
                  Icons.qr_code_2,
                  color: Colors.white,
                  size: 22, // Reduced from 24
                ),
              ),
              title: Row(
                children: [
                  // code & dates
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          code,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                            color: Color(0xFF1A237E),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.schedule,
                              size: 12, // Reduced from 14
                              color: Colors.grey[600],
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                expiresAt,
                                style: TextStyle(
                                  fontSize: 11, // Reduced from 12
                                  color: Colors.grey[600],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: isActive ? Colors.green : Colors.red,
                      borderRadius: BorderRadius.circular(
                        16,
                      ), // Reduced from 20
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isActive ? Icons.check_circle : Icons.cancel,
                          color: Colors.white,
                          size: 12, // Reduced from 14
                        ),
                        const SizedBox(width: 4),
                        Text(
                          isActive ? 'Active' : 'Inactive',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11, // Reduced from 12
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: IconButton(
                      padding: const EdgeInsets.all(4), // Reduced padding
                      constraints:
                          const BoxConstraints(), // Remove default constraints
                      onPressed: () => _showDeleteCodeDialog(code),
                      icon: const Icon(
                        Icons.delete_outline,
                        color: Colors.red,
                        size: 18, // Reduced from 20
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.arrow_drop_down, color: Colors.grey[600]),
                ],
              ),
              children: [
                if (connectors.isEmpty)
                  Container(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16,
                    ), // Reduced from 20
                    padding: const EdgeInsets.all(16), // Reduced from 24
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(
                            Icons.person_off,
                            size: 40, // Reduced from 48
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'No Trackers Connected',
                            style: TextStyle(
                              fontSize: 14, // Reduced from 16
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Share this code to connect trackers',
                            style: TextStyle(
                              fontSize: 11, // Reduced from 12
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  ...connectors.map((conn) => _buildConnectorTile(conn, code)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildConnectorTile(Map<String, dynamic> conn, String code) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!, width: 1),
      ),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: CircleAvatar(
              radius: 20, // Reduced from 24
              backgroundColor: const Color(0xFF1A237E).withOpacity(0.1),
              backgroundImage: conn['profileImageUrl'] != null
                  ? NetworkImage(conn['profileImageUrl'])
                  : null,
              child: conn['profileImageUrl'] == null
                  ? Icon(
                      Icons.person,
                      color: const Color(0xFF1A237E),
                      size: 20, // Reduced from 24
                    )
                  : null,
            ),
          ),
          const SizedBox(width: 12), // Reduced from 16
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  conn['name'] ?? 'Unknown User',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14, // Reduced from 16
                    color: Color(0xFF1A237E),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.email_outlined,
                      size: 12, // Reduced from 14
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        conn['email'] ?? 'No email',
                        style: TextStyle(
                          fontSize: 11, // Reduced from 12
                          color: Colors.grey[600],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: IconButton(
              padding: const EdgeInsets.all(4), // Reduced padding
              constraints: const BoxConstraints(), // Remove default constraints
              onPressed: () => _showDeleteTrackerDialog(code, conn['uid']),
              icon: const Icon(
                Icons.delete_outline,
                color: Colors.red,
                size: 18, // Reduced from 20
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteCodeDialog(String code) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => CommonAlertDialog(
        title: "Delete Code",
        backgroundColor: const Color(0xff7f0505),
        subtitle:
            "Are you sure you want to delete this code '$code'? This action cannot be undone.",
        icon: Icons.warning_amber_rounded,
        okButtonText: "Delete",
        cancelButtonText: "Cancel",
        onOkButtonTap: () async {
          try {
            await _connectorController.deleteGeneratedCode(code: code);
            _refreshData();

            if (!context.mounted) return;

            ToastWidget.show(
              context: context,
              title: "Code deleted successfully",
              iconColor: Colors.white,
              backgroundColor: Colors.green,
              icon: Icons.check_circle,
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
  }

  void _showDeleteTrackerDialog(String code, String connectorId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => CommonAlertDialog(
        title: "Remove Tracker",
        backgroundColor: const Color(0xff7f0505),
        subtitle:
            "Are you sure you want to remove this tracker? They will no longer be able to share their location.",
        icon: Icons.warning_amber_rounded,
        okButtonText: "Remove",
        cancelButtonText: "Cancel",
        onOkButtonTap: () async {
          try {
            await _connectorController.deleteConnector(
              code: code,
              connectorId: connectorId,
            );
            _refreshData();

            if (!context.mounted) return;

            ToastWidget.show(
              context: context,
              title: "Tracker removed successfully",
              iconColor: Colors.white,
              backgroundColor: Colors.green,
              icon: Icons.check_circle,
            );
            Navigator.pop(context, true);
          } catch (e) {
            Fluttertoast.showToast(
              msg: 'Remove failed: $e',
              toastLength: Toast.LENGTH_LONG,
              gravity: ToastGravity.BOTTOM,
              backgroundColor: Colors.red,
              textColor: Colors.white,
              fontSize: 14.0,
            );
            debugPrint("Remove Error: $e");
          }
        },
        onCancelButtonTap: () {
          Navigator.pop(context);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: const CustomAppBar(
        title: 'Generated Codes',
        titleColor: Colors.white,
        showBackButton: true,
        backgroundColor: Color(0xFF1A237E),
        showEnterCodeButton: false,
        showShareButton: false,
      ),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        color: const Color(0xFF1A237E),
        backgroundColor: Colors.white,
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: _futureCodes,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A237E).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Color(0xFF1A237E),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Loading codes...',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              );
            }

            if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.error_outline,
                        size: 48,
                        color: Colors.red,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Error loading codes',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[800],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${snapshot.error}',
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            }

            final codes = snapshot.data ?? [];
            if (codes.isEmpty) {
              return _buildEmptyState();
            }

            return ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 16),
              itemCount: codes.length,
              itemBuilder: (context, index) {
                return _buildCodeCard(codes[index], index);
              },
            );
          },
        ),
      ),
    );
  }
}
