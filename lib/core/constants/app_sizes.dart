import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class AppSizes {
  // Spacing & Padding
  static double get p4 => 4.w;
  static double get p8 => 8.w;
  static double get p12 => 12.w;
  static double get p16 => 16.w;
  static double get p20 => 20.w;
  static double get p24 => 24.w;
  static double get p32 => 32.w;
  static double get p40 => 40.w;
  static double get p48 => 48.w;

  // Border Radius
  static double get r8 => 8.r;
  static double get r12 => 12.r;
  static double get r16 => 16.r;
  static double get r24 => 24.r;

  // Global Edge Insets Helpers
  static EdgeInsets get paddingAll8 => EdgeInsets.all(8.w);
  static EdgeInsets get paddingAll12 => EdgeInsets.all(12.w);
  static EdgeInsets get paddingAll16 => EdgeInsets.all(16.w);
  static EdgeInsets get paddingAll20 => EdgeInsets.all(20.w);
  static EdgeInsets get paddingAll24 => EdgeInsets.all(24.w);

  static EdgeInsets get paddingH16V8 => EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h);
  static EdgeInsets get paddingH24V12 => EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h);

  // SizedBox vertical spacing
  static SizedBox get h4 => SizedBox(height: 4.h);
  static SizedBox get h8 => SizedBox(height: 8.h);
  static SizedBox get h12 => SizedBox(height: 12.h);
  static SizedBox get h16 => SizedBox(height: 16.h);
  static SizedBox get h20 => SizedBox(height: 20.h);
  static SizedBox get h24 => SizedBox(height: 24.h);
  static SizedBox get h32 => SizedBox(height: 32.h);
  static SizedBox get h40 => SizedBox(height: 40.h);
  static SizedBox get h48 => SizedBox(height: 48.h);

  // SizedBox horizontal spacing
  static SizedBox get w4 => SizedBox(width: 4.w);
  static SizedBox get w8 => SizedBox(width: 8.w);
  static SizedBox get w12 => SizedBox(width: 12.w);
  static SizedBox get w16 => SizedBox(width: 16.w);
  static SizedBox get w20 => SizedBox(width: 20.w);
  static SizedBox get w24 => SizedBox(width: 24.w);
  static SizedBox get w32 => SizedBox(width: 32.w);
}
