import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../providers/auth_provider.dart';
import '../services/supabase_service.dart';

class ManageAccountScreen extends StatefulWidget {
  const ManageAccountScreen({super.key});

  @override
  State<ManageAccountScreen> createState() => _ManageAccountScreenState();
}

class _ManageAccountScreenState extends State<ManageAccountScreen> {
  final TextEditingController _usernameController = TextEditingController();
  bool _isSaving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthProvider>();
    _usernameController.text = auth.username ?? '';
  }

  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
  }

  Future<void> _saveUsername() async {
    final auth = context.read<AuthProvider>();
    final currentId = auth.userId;
    if (currentId == null) return;

    final newName = _usernameController.text.trim();
    if (newName.isEmpty) {
      setState(() => _error = 'Username cannot be empty.');
      return;
    }
    if (newName.length < 3) {
      setState(() => _error = 'Username should be at least 3 characters.');
      return;
    }

    if (newName == auth.username) {
      Navigator.of(context).pop();
      return;
    }

    setState(() {
      _isSaving = true;
      _error = null;
    });

    try {
      final client = SupabaseService.instance.client;

      // Check if another user already has this username
      final existing = await client
          .from('users')
          .select('id, username')
          .eq('username', newName)
          .maybeSingle();

      if (existing != null && existing['id'] != null &&
          existing['id'].toString() != currentId) {
        setState(() {
          _error = 'That username is already taken. Please choose another.';
          _isSaving = false;
        });
        return;
      }

      // Update current user's username
      await client
          .from('users')
          .update({'username': newName})
          .eq('id', currentId);

      await auth.setUser(currentId, newName);

      if (!mounted) return;
      Navigator.of(context).pop();
    } on PostgrestException catch (e) {
      setState(() {
        _error = e.message.isNotEmpty
            ? e.message
            : 'Unable to update username. Please try again.';
        _isSaving = false;
      });
    } catch (_) {
      setState(() {
        _error = 'Unexpected error. Please try again.';
        _isSaving = false;
      });
    }
  }

  Future<void> _logout() async {
    final auth = context.read<AuthProvider>();
    await auth.logout();
    if (!mounted) return;
    Navigator.of(context).pop(); // back to Home
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage account'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Signed in as ${auth.username ?? 'Guest'}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _usernameController,
              decoration: InputDecoration(
                labelText: 'Username',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                errorText: _error,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _saveUsername,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(_isSaving ? 'Saving...' : 'Save changes'),
              ),
            ),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _logout,
                icon: const Icon(Icons.logout),
                label: const Text('Log out'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  side: const BorderSide(color: Colors.redAccent),
                  foregroundColor: Colors.redAccent,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


