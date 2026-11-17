import 'package:flutter/material.dart';

class AppInfo {
  AppInfo._();

  static const String appName = 'Plexus';
  static const String appNameShort = 'Plexus';
  static const String appExeName = 'plexus.exe';
  static const String appVersion = '3.2.0';
  static const String appVersionDisplay = '3.2';
  static const int appBuildNumber = 1;

  static const String company = 'AlpherTech';
  static const String companyShort = 'AlpherTech';
  static const String companyDomain = 'alphertech.com';
  static const String website = 'https://alphertech.com/plexus';
  static const String websiteDisplay = 'alphertech.com/plexus';

  static const String helplineEmail = 'alphertech@gmail.com';
  static const String supportEmail = 'alphertech@gmail.com';
  static const String helpdeskPhone = '+256708885123';
  static const String helpdeskPhoneDisplay = '+256 708 885 123';

  static const List<DeveloperInfo> developers = [
    DeveloperInfo(
      name: 'Twale James Massete',
      role: 'Lead Engineer & System Architect',
      email: 'alphertech@gmail.com',
    ),
    DeveloperInfo(
      name: 'Mugenyi Allan',
      role: 'Lead Developer & Backend Engineer',
      email: 'alphertech@gmail.com',
    ),
  ];

  static const String license = 'Proprietary';

  static const String appDescription =
      'Plexus is an all-in-one Point of Sale and Business Management System '
      'designed for modern retail and agricultural operations. Streamline sales, '
      'manage inventory, track finances, and grow your business with powerful '
      'tools built for efficiency and scalability.';

  static const String appLongDescription =
      'Plexus is a comprehensive business management and Point of Sale (POS) '
      'solution developed by AlpherTech. It empowers businesses to manage sales, '
      'inventory, customers, suppliers, accounting, and human resources from a '
      'unified platform. Built with reliability and ease of use in mind, Plexus '
      'serves retail shops, farm supply stores, wholesalers, and multi-branch '
      'operations across East Africa.';

  static const Color primaryColor = Color(0xFF1B5E20);
  static const Color secondaryColor = Color(0xFFE65100);

  static String versionString() => appVersion;

  static String copyrightLine() =>
      '© ${DateTime.now().year} $company. All rights reserved.';
}

class DeveloperInfo {
  final String name;
  final String role;
  final String email;

  const DeveloperInfo({
    required this.name,
    required this.role,
    required this.email,
  });
}
