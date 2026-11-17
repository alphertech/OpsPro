import 'package:flutter/material.dart';
import '../screens/dashboard/dashboard_screen.dart';
import '../screens/pos/pos_screen.dart';
import '../screens/products/product_list_screen.dart';
import '../screens/products/product_form_screen.dart';
import '../screens/sales/sale_list_screen.dart';
import '../screens/customers/customer_list_screen.dart';
import '../screens/customers/customer_payment_screen.dart';
import '../screens/suppliers/supplier_list_screen.dart';
import '../screens/finances/expense_screen.dart';
import '../screens/reports/report_dashboard_screen.dart';
import '../screens/reports/weekly_report_screen.dart';
import '../screens/z_report_screen.dart';
import '../screens/settings/settings_screen.dart';
import '../screens/settings/user_management_screen.dart';
import '../screens/settings/backup_screen.dart';
import '../screens/auth/security_setup_screen.dart';
import '../screens/auth/lock_type_selection_screen.dart';
import '../screens/auth/lock_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/accounting/accounting_screen.dart';
import '../screens/accounting/chart_of_accounts_screen.dart';
import '../screens/accounting/journal_entries_screen.dart';
import '../screens/hr/employee_list_screen.dart';
import '../screens/hr/employee_form_screen.dart';
import '../screens/purchasing/purchase_order_list_screen.dart';
import '../screens/purchasing/purchase_order_form_screen.dart';
import '../screens/projects/project_list_screen.dart';
import '../screens/projects/project_form_screen.dart';
import '../screens/inventory/warehouse_screen.dart';
import '../screens/inventory/stock_transfer_screen.dart';
import '../screens/communication/email_queue_screen.dart';
import '../screens/communication/memo_board_screen.dart';
import '../screens/settings/currency_tax_settings_screen.dart';
import '../screens/settings/system_health_screen.dart';
import '../screens/support/support_screen.dart';


class AppRoutes {
  static const String dashboard = '/';
  static const String pos = '/pos';
  static const String products = '/products';
  static const String productsAdd = '/products/add';
  static const String productsEdit = '/products/edit';
  static const String sales = '/sales';
  static const String customers = '/customers';
  static const String customerPayment = '/customers/payment';
  static const String suppliers = '/suppliers';
  static const String finances = '/finances';
  static const String expenses = '/finances/expense';
  static const String reports = '/reports';
  static const String weeklyReports = '/reports/weekly';
  static const String zReport = '/reports/z-report';
  static const String settings = '/settings';
  static const String users = '/settings/users';
  static const String backup = '/settings/backup';
  static const String securitySetup = '/security/setup';
  static const String lockTypeSelection = '/security/lock-type-selection';
  static const String lock = '/security/lock';
  static const String login = '/login';

  static const String accounting = '/accounting';
  static const String chartOfAccounts = '/accounting/chart-of-accounts';
  static const String journalEntries = '/accounting/journal-entries';
  static const String bankReconciliation = '/accounting/bank-reconciliation';
  static const String pettyCash = '/accounting/petty-cash';
  static const String trialBalance = '/accounting/trial-balance';
  static const String profitLoss = '/accounting/profit-loss';
  static const String balanceSheet = '/accounting/balance-sheet';

  static const String employees = '/hr/employees';
  static const String employeeAdd = '/hr/employees/add';
  static const String employeeEdit = '/hr/employees/edit';
  static const String leaveManagement = '/hr/leave';
  static const String shiftSchedule = '/hr/shifts';
  static const String expenseReimbursement = '/hr/reimbursements';

  static const String purchaseOrders = '/purchasing/orders';
  static const String purchaseOrderAdd = '/purchasing/orders/add';
  static const String purchaseOrderEdit = '/purchasing/orders/edit';

  static const String projects = '/projects';
  static const String projectAdd = '/projects/add';
  static const String projectEdit = '/projects/edit';
  static const String projectDetail = '/projects/detail';

  static const String warehouses = '/inventory/warehouses';
  static const String stockTransfers = '/inventory/stock-transfers';

  static const String emailQueue = '/communication/email-queue';
  static const String memoBoard = '/communication/memo-board';

  static const String currencyTaxSettings = '/settings/currency-tax';
  static const String systemHealth = '/settings/system-health';
  static const String support = '/support';


  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case dashboard:
        return MaterialPageRoute(builder: (_) => const DashboardScreen());
      case pos:
        return MaterialPageRoute(builder: (_) => const PosScreen());
      case products:
        return MaterialPageRoute(builder: (_) => const ProductListScreen());
      case productsAdd:
        return MaterialPageRoute(builder: (_) => const ProductFormScreen());
      case productsEdit:
        final args = settings.arguments as Map?;
        return MaterialPageRoute(
          builder: (_) => ProductFormScreen(product: args?['product']),
        );
      case sales:
        return MaterialPageRoute(builder: (_) => const SaleListScreen());
      case customers:
        return MaterialPageRoute(builder: (_) => const CustomerListScreen());
      case customerPayment:
        return MaterialPageRoute(builder: (_) => const CustomerPaymentScreen());
      case suppliers:
        return MaterialPageRoute(builder: (_) => const SupplierListScreen());
      case finances:
        return MaterialPageRoute(builder: (_) => const ExpenseScreen());
      case expenses:
        return MaterialPageRoute(builder: (_) => const ExpenseScreen());
      case reports:
        return MaterialPageRoute(builder: (_) => const ReportDashboardScreen());
      case weeklyReports:
        return MaterialPageRoute(builder: (_) => const WeeklyReportScreen());
      case AppRoutes.zReport:
        return MaterialPageRoute(builder: (_) => const ZReportScreen());
      case AppRoutes.settings:
        return MaterialPageRoute(builder: (_) => const SettingsScreen());
      case users:
        return MaterialPageRoute(builder: (_) => const UserManagementScreen());
      case backup:
        return MaterialPageRoute(builder: (_) => const BackupScreen());
      case securitySetup:
        return MaterialPageRoute(builder: (_) => const SecuritySetupScreen());
      case lockTypeSelection:
        return MaterialPageRoute(builder: (_) => const LockTypeSelectionScreen());
      case lock:
        return MaterialPageRoute(builder: (_) => const LockScreen(), fullscreenDialog: true);
      case login:
        return MaterialPageRoute(builder: (_) => const LoginScreen());

      case accounting:
        return MaterialPageRoute(builder: (_) => const AccountingScreen());
      case chartOfAccounts:
        return MaterialPageRoute(builder: (_) => const ChartOfAccountsScreen());
      case journalEntries:
        return MaterialPageRoute(builder: (_) => const JournalEntriesScreen());
      case bankReconciliation:
        return MaterialPageRoute(builder: (_) => const BankReconciliationScreen());
      case pettyCash:
        return MaterialPageRoute(builder: (_) => const PettyCashScreen());
      case trialBalance:
        return MaterialPageRoute(builder: (_) => const TrialBalanceScreen());
      case profitLoss:
        return MaterialPageRoute(builder: (_) => const ProfitLossScreen());
      case balanceSheet:
        return MaterialPageRoute(builder: (_) => const BalanceSheetScreen());

      case employees:
        return MaterialPageRoute(builder: (_) => const EmployeeListScreen());
      case employeeAdd:
        return MaterialPageRoute(builder: (_) => const EmployeeFormScreen());
      case employeeEdit:
        final args = settings.arguments as Map?;
        return MaterialPageRoute(
          builder: (_) => EmployeeFormScreen(employee: args?['employee']),
        );
      case leaveManagement:
        return MaterialPageRoute(builder: (_) => const LeaveManagementScreen());
      case shiftSchedule:
        return MaterialPageRoute(builder: (_) => const ShiftScheduleScreen());
      case expenseReimbursement:
        return MaterialPageRoute(builder: (_) => const ExpenseReimbursementScreen());

      case purchaseOrders:
        return MaterialPageRoute(builder: (_) => const PurchaseOrderListScreen());
      case purchaseOrderAdd:
        return MaterialPageRoute(builder: (_) => const PurchaseOrderFormScreen());
      case purchaseOrderEdit:
        final args = settings.arguments as Map?;
        return MaterialPageRoute(
          builder: (_) => PurchaseOrderFormScreen(purchaseOrder: args?['purchaseOrder']),
        );

      case projects:
        return MaterialPageRoute(builder: (_) => const ProjectListScreen());
      case projectAdd:
        return MaterialPageRoute(builder: (_) => const ProjectFormScreen());
      case projectEdit:
        final args = settings.arguments as Map?;
        return MaterialPageRoute(
          builder: (_) => ProjectFormScreen(project: args?['project']),
        );
      case projectDetail:
        final args = settings.arguments as Map?;
        return MaterialPageRoute(
          builder: (_) => ProjectDetailScreen(projectId: args?['projectId'] ?? 0),
        );

      case warehouses:
        return MaterialPageRoute(builder: (_) => const WarehouseScreen());
      case stockTransfers:
        return MaterialPageRoute(builder: (_) => const StockTransferScreen());

      case emailQueue:
        return MaterialPageRoute(builder: (_) => const EmailQueueScreen());
      case memoBoard:
        return MaterialPageRoute(builder: (_) => const MemoBoardScreen());

      case currencyTaxSettings:
        return MaterialPageRoute(builder: (_) => const CurrencyTaxSettingsScreen());
      case systemHealth:
        return MaterialPageRoute(builder: (_) => const SystemHealthScreen());
      case support:
        return MaterialPageRoute(builder: (_) => const SupportScreen());
      default:
        return MaterialPageRoute(
          builder: (_) =>
              const Scaffold(body: Center(child: Text('Page not found'))),
        );
    }
  }
}
