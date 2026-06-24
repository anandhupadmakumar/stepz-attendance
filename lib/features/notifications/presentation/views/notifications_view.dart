import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:stepz_attendance/core/theme/premium_background.dart';

class NotificationsView extends StatelessWidget {
  const NotificationsView({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      return PremiumBackground(
        child: const Scaffold(
          backgroundColor: Colors.transparent,
          body: Center(
            child: Text(
              'User not logged in',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ),
      );
    }

    return DefaultTabController(
      length: 2,
      child: PremiumBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Get.back(),
            ),
            title: Text(
              'Notifications',
              style: GoogleFonts.inter(
                fontSize: 20.sp,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            centerTitle: true,
            bottom: TabBar(
              indicatorColor: const Color(0xFF3B82F6),
              labelColor: const Color(0xFF3B82F6),
              unselectedLabelColor: Colors.white60,
              labelStyle: GoogleFonts.inter(fontSize: 13.sp, fontWeight: FontWeight.bold),
              tabs: const [
                Tab(text: 'Unread'),
                Tab(text: 'Opened'),
              ],
            ),
          ),
          body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance.collection('users').doc(currentUser.uid).snapshots(),
            builder: (context, userSnapshot) {
              if (userSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: Color(0xFF9061FF)));
              }
              final userData = userSnapshot.data?.data();
              final String userRole = userData?['role'] ?? 'employee';

              return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: FirebaseFirestore.instance
                    .collection('notifications')
                    .orderBy('createdAt', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(color: Color(0xFF9061FF)));
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return TabBarView(
                      children: [
                        _buildEmptyState('No new notifications'),
                        _buildEmptyState('No opened notifications'),
                      ],
                    );
                  }

                  // Filter documents matching current user uid or role (or role == all)
                  final filteredDocs = snapshot.data!.docs.where((doc) {
                    final data = doc.data();
                    final targetUid = data['targetUid'] as String?;
                    final targetRole = data['targetRole'] as String?;
                    
                    if (targetUid == currentUser.uid) return true;
                    if (targetRole == 'all') return true;
                    if (targetRole == userRole) return true;
                    return false;
                  }).toList();

                  if (filteredDocs.isEmpty) {
                    return TabBarView(
                      children: [
                        _buildEmptyState('No new notifications'),
                        _buildEmptyState('No opened notifications'),
                      ],
                    );
                  }

                  // Split into unread and opened
                  final unreadDocs = filteredDocs.where((doc) {
                    final data = doc.data();
                    final List<dynamic> readBy = data['readBy'] as List<dynamic>? ?? [];
                    final bool isRead = data['read'] == true || readBy.contains(currentUser.uid);
                    return !isRead;
                  }).toList();

                  final openedDocs = filteredDocs.where((doc) {
                    final data = doc.data();
                    final List<dynamic> readBy = data['readBy'] as List<dynamic>? ?? [];
                    final bool isRead = data['read'] == true || readBy.contains(currentUser.uid);
                    return isRead;
                  }).toList();

                  return TabBarView(
                    children: [
                      _buildNotificationList(unreadDocs, currentUser.uid),
                      _buildNotificationList(openedDocs, currentUser.uid),
                    ],
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationList(List<QueryDocumentSnapshot<Map<String, dynamic>>> docs, String userId) {
    if (docs.isEmpty) {
      return _buildEmptyState('No notifications here');
    }

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      itemCount: docs.length,
      itemBuilder: (context, index) {
        final doc = docs[index];
        final data = doc.data();
        return _buildNotificationCard(doc.id, data, userId);
      },
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(24.w),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.05),
            ),
            child: Icon(
              Icons.notifications_none_outlined,
              size: 64.sp,
              color: Colors.white24,
            ),
          ),
          SizedBox(height: 16.h),
          Text(
            'All Caught Up!',
            style: GoogleFonts.inter(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: Colors.white70,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            message,
            style: GoogleFonts.inter(
              fontSize: 13.sp,
              color: Colors.white38,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationCard(String docId, Map<String, dynamic> data, String userId) {
    final title = data['title'] as String? ?? 'Alert';
    final body = data['body'] as String? ?? '';
    final type = data['type'] as String? ?? 'general';
    final Timestamp? createdAt = data['createdAt'] as Timestamp?;
    final List<dynamic> readBy = data['readBy'] as List<dynamic>? ?? [];
    final bool isRead = data['read'] == true || readBy.contains(userId);
    
    String timeAgo = '';
    if (createdAt != null) {
      final difference = DateTime.now().difference(createdAt.toDate());
      if (difference.inMinutes < 1) {
        timeAgo = 'Just now';
      } else if (difference.inMinutes < 60) {
        timeAgo = '${difference.inMinutes}m ago';
      } else if (difference.inHours < 24) {
        timeAgo = '${difference.inHours}h ago';
      } else {
        timeAgo = DateFormat('MMM dd, yyyy').format(createdAt.toDate());
      }
    }

    IconData iconData = Icons.notifications;
    Color iconColor = const Color(0xFF9061FF);
    Color cardBgColor = Colors.white.withOpacity(0.08);
    Color borderColor = Colors.white.withOpacity(0.12);

    if (type == 'leave_request') {
      iconData = Icons.time_to_leave_rounded;
      iconColor = const Color(0xFF60A5FA);
    } else if (type == 'leave_approved') {
      iconData = Icons.check_circle_rounded;
      iconColor = const Color(0xFF34D399);
    } else if (type == 'leave_rejected') {
      iconData = Icons.cancel_rounded;
      iconColor = const Color(0xFFF87171);
    } else if (type == 'broadcast') {
      iconData = Icons.campaign_rounded;
      iconColor = const Color(0xFFF59E0B);
    } else if (type == 'birthday') {
      iconData = Icons.cake_rounded;
      iconColor = const Color(0xFFEC4899);
    }

    return GestureDetector(
      onTap: () {
        if (!isRead) {
          FirebaseFirestore.instance.collection('notifications').doc(docId).update({
            'readBy': FieldValue.arrayUnion([userId]),
            if (data['targetUid'] == userId) 'read': true,
          });
        }
      },
      child: Container(
        margin: EdgeInsets.only(bottom: 12.h),
        decoration: BoxDecoration(
          color: cardBgColor,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: borderColor, width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16.r),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
            child: Padding(
              padding: EdgeInsets.all(16.w),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Icon Background
                  Container(
                    padding: EdgeInsets.all(10.w),
                    decoration: BoxDecoration(
                      color: iconColor.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      iconData,
                      color: iconColor,
                      size: 22.sp,
                    ),
                  ),
                  SizedBox(width: 14.w),
                  // Text details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Flexible(
                                    child: Text(
                                      title,
                                      style: GoogleFonts.inter(
                                        fontSize: 14.sp,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (!isRead) ...[
                                    SizedBox(width: 6.w),
                                    Container(
                                      width: 8.w,
                                      height: 8.w,
                                      decoration: const BoxDecoration(
                                        color: Color(0xFFEF4444),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            Text(
                              timeAgo,
                              style: GoogleFonts.inter(
                                fontSize: 11.sp,
                                color: Colors.white38,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 6.h),
                        Text(
                          body,
                          style: GoogleFonts.inter(
                            fontSize: 13.sp,
                            color: Colors.white.withOpacity(0.8),
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

