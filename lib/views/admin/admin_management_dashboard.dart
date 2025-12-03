import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminManagementDashboardPage extends StatefulWidget {
  const AdminManagementDashboardPage({super.key});

  @override
  State<AdminManagementDashboardPage> createState() =>
      _AdminManagementDashboardPageState();
}

class _AdminManagementDashboardPageState
    extends State<AdminManagementDashboardPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String selectedFilter = "All";

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          Material(
            color: Colors.deepPurple.shade50,
            child: TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: "Admins"),
                Tab(text: "Users"),
              ],
              indicatorColor: Colors.black,
              labelColor: Colors.black,
              unselectedLabelColor: Colors.black,
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildRoleSection('admin'),
                _buildRoleSection('user'),
              ],
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildRoleSection(String role) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final allUsers = snapshot.data!.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return data['role'] == role;
        }).toList();

        int total = allUsers.length;

        // Active count নির্ণয়
        int activeCount = allUsers.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return data.containsKey('active') ? (data['active'] ?? true) : true;
        }).length;

        int disabledCount = total - activeCount;

        // Filtered users (Active/Disabled)
        final filteredUsers = allUsers.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final isActive = data.containsKey('active') ? (data['active'] ?? true) : true;

          if (selectedFilter == "Active") return isActive;
          if (selectedFilter == "Disabled") return !isActive;
          return true;
        }).toList();

        if (filteredUsers.isEmpty) {
          return const Center(child: Text("No users found"));
        }

        return Column(
          children: [
            Container(
              color: Colors.deepPurple.shade50,
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildCount("Total", total, Colors.black),
                  _buildCount("Active", activeCount, Colors.green),
                  _buildCount("Disabled", disabledCount, Colors.red),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: ["All", "Active", "Disabled"].map((f) {
                  final selected = selectedFilter == f;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: ChoiceChip(
                      label: Text(f),
                      selected: selected,
                      selectedColor: Colors.deepPurple,
                      labelStyle: TextStyle(
                          color: selected ? Colors.white : Colors.black),
                      onSelected: (_) {
                        setState(() => selectedFilter = f);
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
            const Divider(height: 0),
            Expanded(
              child: ListView.builder(
                itemCount: filteredUsers.length,
                itemBuilder: (context, index) {
                  final user = filteredUsers[index].data() as Map<String, dynamic>;
                  final docId = filteredUsers[index].id;
                  final isActive = user.containsKey('active') ? (user['active'] ?? true) : true;
                  final isSuperAdmin = user['isSuperAdmin'] ?? false;
                  final roleName = user['role'] ?? 'N/A';

                  // 🔹 CreatedAt & LastLogin তারিখ বের করা
                  final createdAt = user['createdAt'] != null
                      ? (user['createdAt'] as Timestamp).toDate()
                      : null;
                  final lastLogin = user['lastLogin'] != null
                      ? (user['lastLogin'] as Timestamp).toDate()
                      : null;

                  // 🔹 সময় ও তারিখ সুন্দরভাবে ফরম্যাট করা (AM/PM সহ)
                  String formatDate(DateTime? date) {
                    if (date == null) return 'N/A';
                    final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
                    final ampm = date.hour >= 12 ? 'PM' : 'AM';
                    final minute = date.minute.toString().padLeft(2, '0');
                    return "${date.day}/${date.month}/${date.year}  $hour:$minute $ampm";
                  }

                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: ListTile(
                      contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      title: Text(
                        user['name'] ?? 'No Name',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(user['email'] ?? 'No Email',
                              style:
                              const TextStyle(fontSize: 13, color: Colors.black)),
                          const SizedBox(height: 4),
                          Text("Role: $roleName",
                              style: const TextStyle(fontSize: 13, color: Colors.black)),
                          Text("Created: ${formatDate(createdAt)}",
                              style:
                              const TextStyle(fontSize: 12, color: Colors.black)),
                          Text("Last Login: ${formatDate(lastLogin)}",
                              style:
                              const TextStyle(fontSize: 12, color: Colors.black)),
                        ],
                      ),
                      trailing: isSuperAdmin
                          ? const Text(
                        "Super Admin",
                        style: TextStyle(
                          color: Colors.deepPurple,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                          : Wrap(
                        spacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          if (role == 'admin')
                            IconButton(
                              icon: const Icon(Icons.arrow_downward,
                                  color: Colors.orange),
                              onPressed: () => _downgradeToUser(docId),
                            ),
                          if (role == 'user')
                            IconButton(
                              icon: const Icon(Icons.arrow_upward,
                                  color: Colors.blue),
                              onPressed: () => _upgradeToAdmin(docId),
                            ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _deleteUser(docId),
                          ),
                          Switch(
                            value: isActive,
                            onChanged: (val) => _toggleActiveStatus(docId, val),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCount(String label, int count, Color color) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(
          count.toString(),
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: color,
          ),
        ),
      ],
    );
  }

  Future<void> _toggleActiveStatus(String docId, bool val) async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(docId)
        .update({'active': val});
  }

  Future<void> _downgradeToUser(String docId) async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(docId)
        .update({'role': 'user'});
  }

  Future<void> _upgradeToAdmin(String docId) async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(docId)
        .update({'role': 'admin'});
  }

  Future<void> _deleteUser(String docId) async {
    await FirebaseFirestore.instance.collection('users').doc(docId).delete();
  }
}