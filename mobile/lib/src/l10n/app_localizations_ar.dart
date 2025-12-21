// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appName => 'CareSync';

  @override
  String get hospitalFirst => 'Hospital First';

  @override
  String get nav_home => 'الرئيسية';

  @override
  String get nav_staff => 'الكادر';

  @override
  String get nav_account => 'الحساب';

  @override
  String get login_title => 'تسجيل الدخول';

  @override
  String get login_tenant => 'كود المنشأة';

  @override
  String get login_tenant_hint => 'الصق كود المنشأة أو المعرّف';

  @override
  String get login_email => 'الإيميل';

  @override
  String get login_phone => 'الهاتف';

  @override
  String get login_password => 'كلمة المرور';

  @override
  String get login_button => 'دخول';

  @override
  String get login_failed => 'فشل تسجيل الدخول. تأكد من البيانات.';

  @override
  String get settings_title => 'الإعدادات';

  @override
  String get settings_header_title => 'تحكم كامل بالتجربة';

  @override
  String get settings_header_subtitle_normal =>
      'اختر المظهر واللغة وسهولة الوصول';

  @override
  String get settings_header_subtitle_rgb =>
      'RGB Pulse فعّال — واجهة نابضة وحيوية';

  @override
  String get settings_appearance => 'المظهر';

  @override
  String get settings_language => 'اللغة';

  @override
  String get settings_accessibility => 'سهولة الوصول والأداء';

  @override
  String get settings_experience => 'تجربة المستخدم';

  @override
  String get settings_about => 'عن التطبيق';

  @override
  String get settings_themeMode => 'الوضع';

  @override
  String get settings_themeMode_system => 'نظام الجهاز';

  @override
  String get settings_themeMode_light => 'لايت';

  @override
  String get settings_themeMode_dark => 'دارك';

  @override
  String get settings_themeStyle => 'ستايل الثيم';

  @override
  String get settings_themeStyle_classic => 'Classic';

  @override
  String get settings_themeStyle_neon => 'Neon';

  @override
  String get settings_themeStyle_rgbPulse => 'RGB Pulse';

  @override
  String get settings_themeStyle_classic_desc => 'Classic — رسمي وهادئ';

  @override
  String get settings_themeStyle_neon_desc => 'Neon — حواف وإبرازات جذابة';

  @override
  String get settings_themeStyle_rgb_desc => 'RGB Pulse — ثيم نابض ديناميكي';

  @override
  String get settings_themeStyle_rgb_hint => 'يتوقف عند تفعيل تقليل الحركة';

  @override
  String get settings_accentSeed => 'لون التطبيق الأساسي';

  @override
  String get settings_accentSeed_subtitle => 'يؤثر على الأزرار والواجهات';

  @override
  String get settings_accentSeed_disabled_rgb => 'غير متاح أثناء RGB Pulse';

  @override
  String get settings_appLanguage => 'لغة التطبيق';

  @override
  String get settings_lang_system => 'نظام الجهاز';

  @override
  String get settings_lang_ar => 'العربية';

  @override
  String get settings_lang_en => 'English';

  @override
  String get settings_reduceMotion => 'تقليل الحركة (أفضل للأداء)';

  @override
  String get settings_reduceMotion_sub =>
      'يقلل المؤثرات وRGB Pulse يصبح ثابتاً';

  @override
  String get settings_compactUi => 'واجهة مدمجة';

  @override
  String get settings_compactUi_sub => 'Padding أقل — مناسب للشاشات الصغيرة';

  @override
  String get settings_textSize => 'حجم النص';

  @override
  String get settings_haptics => 'اهتزاز خفيف للأزرار';

  @override
  String get settings_haptics_sub => 'سنفعّله لاحقاً على الأزرار الحساسة';

  @override
  String get settings_note_locale =>
      'ملاحظة: تغيير اللغة يتطلب أن تكون النصوص مربوطة بمفاتيح AppLocalizations (تجنّب النصوص الثابتة).';

  @override
  String get account_title => 'الحساب';

  @override
  String get account_subtitle => 'بياناتك وصلاحياتك';

  @override
  String get account_noData => 'لا توجد بيانات';

  @override
  String get account_info => 'معلومات';

  @override
  String get account_roles => 'الصلاحيات';

  @override
  String get account_logout => 'تسجيل خروج';

  @override
  String get staff_title => 'الكادر والصلاحيات';

  @override
  String get staff_add => 'إضافة';

  @override
  String get staff_search_hint => 'بحث (اسم/إيميل/هاتف)';

  @override
  String get staff_status => 'الحالة';

  @override
  String get staff_status_all => 'الكل';

  @override
  String get staff_status_active => 'نشط';

  @override
  String get staff_status_inactive => 'غير نشط';

  @override
  String get staff_apply => 'تطبيق';

  @override
  String get staff_noResults => 'لا توجد نتائج';

  @override
  String get staff_unauthorized => 'غير مصرح';

  @override
  String get staff_retry => 'إعادة المحاولة';

  @override
  String get user_active => 'نشط';

  @override
  String get user_inactive => 'غير نشط';

  @override
  String get user_enable => 'تفعيل';

  @override
  String get user_disable => 'تعطيل';

  @override
  String get resetPassword_title => 'إعادة تعيين كلمة المرور';

  @override
  String resetPassword_user(String fullName) {
    return 'المستخدم: $fullName';
  }

  @override
  String get resetPassword_newPassword => 'كلمة مرور جديدة';

  @override
  String get resetPassword_hint => 'على الأقل 6 أحرف';

  @override
  String get resetPassword_cancel => 'إلغاء';

  @override
  String get resetPassword_confirm => 'تأكيد';

  @override
  String get resetPassword_short => 'كلمة المرور يجب أن تكون 6 أحرف على الأقل';

  @override
  String get resetPassword_success => 'تم تحديث كلمة المرور بنجاح';

  @override
  String get staff_manage_title => 'الكادر والصلاحيات';

  @override
  String get staff_add_user => 'إضافة مستخدم';

  @override
  String get staff_disable_user_q => 'تعطيل المستخدم؟';

  @override
  String get staff_enable_user_q => 'تفعيل المستخدم؟';

  @override
  String get staff_disable_user_desc => 'سيتم منع المستخدم من تسجيل الدخول.';

  @override
  String get staff_enable_user_desc => 'سيتم السماح للمستخدم بتسجيل الدخول.';

  @override
  String get common_cancel => 'إلغاء';

  @override
  String get common_confirm => 'تم النسخ';

  @override
  String get common_apply => 'تطبيق';

  @override
  String get common_all => 'الكل';

  @override
  String get common_active => 'نشط';

  @override
  String get common_inactive => 'غير نشط';

  @override
  String get common_retry => 'إعادة المحاولة';

  @override
  String get common_search => 'بحث';

  @override
  String get facility_code => 'كود المنشأة';

  @override
  String get staff_id => 'معرّف الموظف';

  @override
  String get create_user_title => 'إنشاء مستخدم';

  @override
  String get create_user_section => 'بيانات المستخدم';

  @override
  String get create_user_full_name => 'الاسم الكامل';

  @override
  String get create_user_email => 'البريد الإلكتروني';

  @override
  String get create_user_phone => 'رقم الهاتف';

  @override
  String get create_user_password => 'كلمة المرور';

  @override
  String get create_user_roles => 'الأدوار';

  @override
  String get create_user_submit => 'إنشاء';

  @override
  String get create_user_success => 'تم إنشاء المستخدم بنجاح';
}
