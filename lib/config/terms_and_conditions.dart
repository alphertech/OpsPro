import '../config/app_info.dart';

class TermsAndConditions {
  TermsAndConditions._();

  static const String title = 'Terms and Conditions of Usage';

  static const String licenseTitle = 'END USER LICENSE AGREEMENT (EULA)';

  static const String licenseText = '''
END USER LICENSE AGREEMENT (EULA)
Plexus — Version 3.2
Developed by AlpherTech (alphertech.com/plexus)

IMPORTANT: PLEASE READ THIS LICENSE AGREEMENT CAREFULLY BEFORE INSTALLING,
ACCESSING, OR USING THE PLEXUS SOFTWARE (THE "SOFTWARE").

BY INSTALLING, COPYING, OR OTHERWISE USING THE SOFTWARE, YOU (THE "LICENSEE"
OR "YOU") AGREE TO BE BOUND BY THE TERMS OF THIS AGREEMENT. IF YOU DO NOT
AGREE TO THE TERMS OF THIS AGREEMENT, DO NOT INSTALL OR USE THE SOFTWARE.

1. GRANT OF LICENSE
    AlpherTech grants you a personal, non-exclusive, non-transferable,
    limited license to install and use this Software on a single computer or
    device for the purpose of managing your business operations. This license
    is for internal business use only.

2. LICENSE RESTRICTIONS
    You may NOT:
    a) Copy, modify, adapt, translate, reverse engineer, decompile, disassemble,
       or create derivative works of the Software, in whole or in part.
    b) Distribute, rent, lease, sublicense, transfer, or lend the Software.
    c) Remove, alter, or obscure any proprietary notices from the Software.
    d) Use the Software for any illegal or unauthorized purpose.
    e) Circumvent any security features or access controls of the Software.
    f) Use the Software in any way not expressly authorized by AlpherTech.

3. TERM
    This license is effective from the date of first installation of the Software
    and shall continue indefinitely unless terminated. AlpherTech may
    terminate this license at any time if you fail to comply with its terms.
    You may terminate it at any time by uninstalling and destroying all copies
    of the Software.

4. INTELLECTUAL PROPERTY
    The Software is the property of AlpherTech and is protected by
    copyright, trademark, and other intellectual property laws. Nothing in this
    Agreement grants you any rights to the trademarks, service marks, or logos
    of AlpherTech or Plexus.

5. DATA STORAGE AND PRIVACY
    a) The Software operates entirely offline (100% local storage). No data is
       transmitted to the internet unless explicitly exported by the user.
    b) All business data (products, sales, customers, financials) is stored
       locally in a SQLite database on your device.
    c) You are solely responsible for the accuracy, retention, and security of
       your data. AlpherTech recommends regular backups.
    d) AlpherTech does not collect, store, or access any of your
       business data during normal operation.

6. SUPPORT AND MAINTENANCE
    a) Technical support is provided via AlpherTech:
       Email: ${AppInfo.supportEmail}
       Website: ${AppInfo.websiteDisplay}
       Hotline: ${AppInfo.helpdeskPhoneDisplay}
    b) Support is provided on a best-effort basis. There is no guaranteed
       response time unless covered by a paid support agreement.
    c) Updates, upgrades, and new releases may be provided at the sole
       discretion of AlpherTech.

7. DEVELOPER CREDITS
    This Software (Plexus v3.2) is developed and maintained by:
    - Twale James Massete (Lead Engineer & System Architect)
    - Mugenyi Allan (Lead Developer & Backend Engineer)
    For licensing, support, and developer inquiries, contact:
    ${AppInfo.supportEmail}

8. WARRANTY DISCLAIMER
    THE SOFTWARE IS PROVIDED "AS IS," WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
    IMPLIED, INCLUDING BUT NOT LIMITED TO THE IMPLIED WARRANTIES OF MERCHANTABILITY,
    FITNESS FOR A PARTICULAR PURPOSE, AND NONINFRINGEMENT. ALPHERTECH
    DOES NOT WARRANT THAT THE SOFTWARE WILL BE UNINTERRUPTED, SECURE, ERROR-FREE,
    OR THAT DEFECTS WILL BE CORRECTED.

9. LIMITATION OF LIABILITY
    TO THE MAXIMUM EXTENT PERMITTED BY APPLICABLE LAW, IN NO EVENT SHALL ALPHERTECH
    OR ITS AFFILIATES BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
    SPECIAL, CONSEQUENTIAL, OR PUNITIVE DAMAGES, OR ANY LOSS OF PROFITS, DATA,
    BUSINESS, OR OTHER INTANGIBLE LOSSES ARISING OUT OF THE USE OF OR INABILITY TO
    USE THE SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGES.

10. INDEMNIFICATION
     You agree to indemnify, defend, and hold harmless AlpherTech, its
     officers, directors, employees, and agents from and against any and all
     claims, liabilities, damages, losses, or expenses (including reasonable
     attorneys' fees) arising out of or in connection with your use of the Software
     or violation of this Agreement.

11. GOVERNING LAW
     This Agreement shall be governed by and construed in accordance with the
     laws of Uganda, without regard to its conflict of law principles. Any
     disputes arising under this Agreement shall be subject to the exclusive
     jurisdiction of the courts of Uganda.

12. MISCELLANEOUS
     a) This Agreement constitutes the entire agreement between the parties
        regarding the Software and supersedes all prior agreements.
     b) If any provision is found to be unenforceable, the remaining provisions
        remain in full force and effect.
     c) No waiver of any term shall be deemed a further continuing waiver.
     d) Plexus is a product of AlpherTech, Uganda.

For support and licensing inquiries:
  AlpherTech
  Website: alphertech.com/plexus
  Email: alphertech@gmail.com
  Hotline: +256 708 885 123
  Lead Engineers: TWALE JAMES MASSETE & MUGENYI ALLAN

© 2026 AlpherTech. All rights reserved.
''';
}
