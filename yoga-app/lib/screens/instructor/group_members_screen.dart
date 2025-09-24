//lib/screens/instructor/group_members_screen.dart

import 'package:flutter/material.dart';
import '../../api_service.dart';
import '../../models/user.dart';

class GroupMembersScreen extends StatefulWidget {
  final String groupId;
  final String groupName;
  final ApiService apiService;

  const GroupMembersScreen({
    super.key,
    required this.groupId,
    required this.groupName,
    required this.apiService,
  });

  @override
  State<GroupMembersScreen> createState() => _GroupMembersScreenState();
}

class _GroupMembersScreenState extends State<GroupMembersScreen> {
  late Future<List<User>> _membersFuture;

  @override
  void initState() {
    super.initState();
    _membersFuture = widget.apiService.getGroupMembers(groupId: widget.groupId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.groupName),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(20.0),
          child: Padding(
            padding: EdgeInsets.only(bottom: 8.0),
            child: Text('Participants', style: TextStyle(color: Colors.grey)),
          ),
        ),
      ),
      body: FutureBuilder<List<User>>(
        future: _membersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final members = snapshot.data ?? [];
          if (members.isEmpty) {
            return const Center(child: Text('No participants have joined this group yet.'));
          }

          return ListView.builder(
            itemCount: members.length,
            itemBuilder: (context, index) {
              final member = members[index];
              return ListTile(
                leading: CircleAvatar(
                  child: Text(member.fullName.isNotEmpty ? member.fullName[0].toUpperCase() : '?'),
                ),
                title: Text(member.fullName),
                subtitle: Text(member.email),
              );
            },
          );
        },
      ),
    );
  }
}