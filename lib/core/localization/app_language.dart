import 'package:flutter/material.dart';

class AppLanguageController extends ValueNotifier<Locale> {
  AppLanguageController() : super(const Locale('en'));

  void toggle() {
    value = value.languageCode == 'ar'
        ? const Locale('en')
        : const Locale('ar');
  }
}

class AppLanguageScope extends InheritedNotifier<AppLanguageController> {
  const AppLanguageScope({
    required AppLanguageController controller,
    required super.child,
    super.key,
  }) : super(notifier: controller);

  static AppLanguageController of(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<AppLanguageScope>()!
        .notifier!;
  }
}

extension AppLanguageContext on BuildContext {
  bool get isArabic => Localizations.localeOf(this).languageCode == 'ar';

  String localized(String english, String arabic) =>
      isArabic ? arabic : english;

  String tr(String key) => isArabic ? _arabic[key] ?? key : key;
}

const _arabic = <String, String>{
  'Dashboard': 'الرئيسية',
  'Reports': 'التقارير',
  'Refresh': 'تحديث',
  'All time': 'كل الوقت',
  'Today': 'اليوم',
  'Yesterday': 'أمس',
  'Date': 'تاريخ محدد',
  'Products': 'المنتجات',
  'Warehouse quantity': 'كمية المخزن',
  'Inventory value': 'قيمة المخزون',
  'Today sales': 'مبيعات اليوم',
  'Daily sales': 'المبيعات اليومية',
  'Monthly sales': 'المبيعات الشهرية',
  'Low stock': 'مخزون منخفض',
  'Customer debts': 'ديون العملاء',
  'Supplier debts': 'ديون الموردين',
  "Today's collections": 'تحصيلات اليوم',
  "Today's payments": 'مدفوعات اليوم',
  'Collections today': 'تحصيلات اليوم',
  'Customer debt report': 'تقرير ديون العملاء',
  'Supplier debt report': 'تقرير ديون الموردين',
  'Top medicines': 'الأصناف الأكثر مبيعًا',
  'Top representatives': 'أفضل المندوبين',
  'Low stock products': 'الأصناف منخفضة المخزون',
  'Medicine': 'المنتج',
  'Qty': 'الكمية',
  'Total': 'الإجمالي',
  'Representative': 'المندوب',
  'Category': 'التصنيف',
  'Sold': 'المباع',
  'Sales': 'المبيعات',
  'Customers': 'العملاء',
  'Suppliers': 'الموردون',
  'Purchases': 'المشتريات',
  'Reps': 'المندوبون',
  'Inventory': 'المخزون',
  'Name': 'الاسم',
  'Phone': 'الهاتف',
  'Actions': 'الإجراءات',
  'Search': 'بحث',
  'Add medicine': 'إضافة منتج',
  'Add customer': 'إضافة عميل',
  'Add supplier': 'إضافة مورد',
  'New sale': 'بيع جديد',
  'New purchase': 'شراء جديد',
  'Cancel': 'إلغاء',
  'Save': 'حفظ',
  'Delete': 'حذف',
  'Edit': 'تعديل',
  'View details': 'عرض التفاصيل',
  'Record payment': 'تسجيل دفعة',
  'Outstanding': 'المستحق',
  'Current debt': 'المديونية الحالية',
  'Unpaid invoices': 'فواتير غير مدفوعة',
  'Last payment': 'آخر دفعة',
  'Created': 'تاريخ الإضافة',
  'Selling': 'سعر البيع',
  'Purchase': 'سعر الشراء',
  'Barcode': 'الباركود',
  'Paid': 'المدفوع',
  'Remaining': 'المتبقي',
  'Invoice': 'الفاتورة',
  'Customer': 'العميل',
  'Type': 'النوع',
  'Unit': 'سعر الوحدة',
  'Invoice actions': 'إجراءات الفاتورة',
  'Representatives': 'المندوبون',
  'Add representative': 'إضافة مندوب',
  'Representative inventory': 'مخزون المندوبين',
  'Assign': 'توزيع',
  'Assigned': 'المسلّم',
};
