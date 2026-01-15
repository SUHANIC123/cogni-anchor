import 'package:cogni_anchor/data/core/api_service.dart';
import 'package:cogni_anchor/data/core/config/api_config.dart';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cogni_anchor/presentation/constants/theme_constants.dart';
import 'fr_edit_person_full.dart';
import 'package:cached_network_image/cached_network_image.dart';

class FRPeopleListPage extends StatefulWidget {
  final bool forEditing;

  const FRPeopleListPage({super.key, required this.forEditing});

  @override
  State<FRPeopleListPage> createState() => _FRPeopleListPageState();
}

class _FRPeopleListPageState extends State<FRPeopleListPage> {
  List<dynamic> people = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadPeople();
  }

  Future<void> _loadPeople() async {
    setState(() => loading = true);
    try {
      final data = await ApiService.getPeople();
      setState(() => people = data);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Failed to load people")));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _onPersonTap(Map<String, dynamic> person) async {
    if (widget.forEditing) {
      final changed = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (_) => FREditPersonFullPage(person: person),
          fullscreenDialog: true,
        ),
      );
      if (changed == true) await _loadPeople();
    } else {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (_) => _buildDeleteDialog(person),
      );
      if (confirmed == true) {
        try {
          final ok = await ApiService.deletePerson(person['id'].toString());
          if (ok) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Person deleted")));
            await _loadPeople();
          } else {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Delete failed")));
          }
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Delete error")));
        }
      }
    }
  }

  Widget _buildDeleteDialog(Map<String, dynamic> person) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
      child: Padding(
        padding: EdgeInsets.all(18.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72.w,
              height: 72.w,
              decoration: BoxDecoration(color: Colors.red.shade50, shape: BoxShape.circle),
              child: Icon(Icons.delete_forever, color: Colors.red, size: 36.sp),
            ),
            SizedBox(height: 12.h),
            Text("Delete ${person['name']}?", style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
            SizedBox(height: 8.h),
            Text("This action cannot be undone.", style: TextStyle(fontSize: 13.sp, color: Colors.grey[700]), textAlign: TextAlign.center),
            SizedBox(height: 16.h),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context, false),
                    style: OutlinedButton.styleFrom(foregroundColor: AppColors.primary),
                    child: const Text("Cancel"),
                  ),
                ),
                SizedBox(width: 14.w),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                    child: const Text(
                      "Yes, Delete",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _iosListTile(Map<String, dynamic> p) {
    final String? rawUrl = p['image_url'];
    final String fullUrl = (rawUrl != null && rawUrl.startsWith('/')) ? "${ApiConfig.baseUrl}$rawUrl" : (rawUrl ?? '');

    return InkWell(
      onTap: () => _onPersonTap(p),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
          color: Colors.white,
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10.r),
              child: CachedNetworkImage(
                imageUrl: fullUrl,
                width: 56.w,
                height: 56.w,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(color: Colors.grey[200]),
                errorWidget: (_, __, ___) => Container(color: Colors.grey[200], child: Icon(Icons.person, color: Colors.grey[400])),
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(p['name'] ?? 'Unknown', style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600)),
                  SizedBox(height: 4.h),
                  Text("${p['relationship'] ?? ''} • ${p['occupation'] ?? ''}", style: TextStyle(fontSize: 13.sp, color: Colors.grey[600]), overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.grey, size: 28.sp),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 75,
        backgroundColor: AppColors.primary,
        elevation: 0,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(bottom: Radius.circular(22))),
        title: Text(widget.forEditing ? "Edit Person" : "Remove Person", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: () => Navigator.pop(context)),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : people.isEmpty
              ? Center(child: Text("No persons found", style: TextStyle(color: Colors.grey[600])))
              : ListView.builder(itemCount: people.length, itemBuilder: (_, i) => _iosListTile(people[i])),
    );
  }
}
