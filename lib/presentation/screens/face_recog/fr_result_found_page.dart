import 'package:cogni_anchor/data/core/config/api_config.dart';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class FRResultFoundPage extends StatelessWidget {
  final Map<String, dynamic> person;

  const FRResultFoundPage({super.key, required this.person});

  @override
  Widget build(BuildContext context) {
    final name = person['name'] ?? 'Unknown';
    final relationship = person['relationship'] ?? '';
    final occupation = person['occupation'] ?? '';
    final age = person['age']?.toString() ?? '';
    final notes = person['notes'] ?? '';

    final String? rawUrl = person['image_url'];
    final String fullUrl = (rawUrl != null && rawUrl.startsWith('/')) ? "${ApiConfig.baseUrl}$rawUrl" : (rawUrl ?? '');

    return Scaffold(
      body: Stack(
        children: [
          Container(
            width: double.infinity,
            height: double.infinity,
            color: Colors.grey.shade300,
          ),
          Positioned(
            top: 60.h,
            left: 20.w,
            right: 20.w,
            child: Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [Colors.orange.withValues(alpha: 0.9), Colors.orange.withValues(alpha: 0.6)]),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Column(
                children: [
                  Text("Person Recognized!", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16.sp)),
                  Text("We found them in your database", style: TextStyle(color: Colors.white70, fontSize: 12.sp)),
                ],
              ),
            ),
          ),
          Align(
            alignment: Alignment.center,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              child: Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
                child: Padding(
                  padding: EdgeInsets.all(16.w),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (fullUrl.isNotEmpty)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12.r),
                          child: Image.network(
                            fullUrl,
                            width: 220.w,
                            height: 220.w,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                width: 220.w,
                                height: 220.w,
                                color: Colors.grey[200],
                                child: const Icon(Icons.person, size: 50, color: Colors.grey),
                              );
                            },
                          ),
                        ),
                      SizedBox(height: 12.h),
                      Text(name, style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold)),
                      SizedBox(height: 6.h),
                      Text(relationship, style: TextStyle(fontSize: 16.sp)),
                      SizedBox(height: 6.h),
                      Text("$occupation, Age $age", style: TextStyle(fontSize: 14.sp, color: Colors.grey[700])),
                      SizedBox(height: 10.h),
                      if (notes.isNotEmpty) Text(notes, style: TextStyle(fontSize: 12.sp)),
                      SizedBox(height: 14.h),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text("Close"),
                      )
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
