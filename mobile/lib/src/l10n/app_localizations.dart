import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'CareSync'**
  String get appName;

  /// No description provided for @hospitalFirst.
  ///
  /// In en, this message translates to:
  /// **'Hospital First'**
  String get hospitalFirst;

  /// No description provided for @nav_home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get nav_home;

  /// No description provided for @nav_staff.
  ///
  /// In en, this message translates to:
  /// **'Staff'**
  String get nav_staff;

  /// No description provided for @nav_account.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get nav_account;

  /// No description provided for @nav_orders.
  ///
  /// In en, this message translates to:
  /// **'Orders'**
  String get nav_orders;

  /// No description provided for @nav_tasks.
  ///
  /// In en, this message translates to:
  /// **'My Tasks'**
  String get nav_tasks;

  /// No description provided for @login_title.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get login_title;

  /// No description provided for @login_tenant.
  ///
  /// In en, this message translates to:
  /// **'Facility Code'**
  String get login_tenant;

  /// No description provided for @login_tenant_hint.
  ///
  /// In en, this message translates to:
  /// **'Paste the facility code or identifier'**
  String get login_tenant_hint;

  /// No description provided for @login_email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get login_email;

  /// No description provided for @login_phone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get login_phone;

  /// No description provided for @login_password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get login_password;

  /// No description provided for @login_button.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login_button;

  /// No description provided for @login_failed.
  ///
  /// In en, this message translates to:
  /// **'Login failed. Please check your details.'**
  String get login_failed;

  /// No description provided for @settings_title.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings_title;

  /// No description provided for @settings_header_title.
  ///
  /// In en, this message translates to:
  /// **'Full Control'**
  String get settings_header_title;

  /// No description provided for @settings_header_subtitle_normal.
  ///
  /// In en, this message translates to:
  /// **'Choose theme, language, and accessibility options'**
  String get settings_header_subtitle_normal;

  /// No description provided for @settings_header_subtitle_rgb.
  ///
  /// In en, this message translates to:
  /// **'RGB Pulse is active — vivid dynamic experience'**
  String get settings_header_subtitle_rgb;

  /// No description provided for @settings_appearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get settings_appearance;

  /// No description provided for @settings_language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settings_language;

  /// No description provided for @settings_accessibility.
  ///
  /// In en, this message translates to:
  /// **'Accessibility & Performance'**
  String get settings_accessibility;

  /// No description provided for @settings_experience.
  ///
  /// In en, this message translates to:
  /// **'Experience'**
  String get settings_experience;

  /// No description provided for @settings_about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get settings_about;

  /// No description provided for @settings_themeMode.
  ///
  /// In en, this message translates to:
  /// **'Theme mode'**
  String get settings_themeMode;

  /// No description provided for @settings_themeMode_system.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get settings_themeMode_system;

  /// No description provided for @settings_themeMode_light.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get settings_themeMode_light;

  /// No description provided for @settings_themeMode_dark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get settings_themeMode_dark;

  /// No description provided for @settings_themeStyle.
  ///
  /// In en, this message translates to:
  /// **'Theme style'**
  String get settings_themeStyle;

  /// No description provided for @settings_themeStyle_classic.
  ///
  /// In en, this message translates to:
  /// **'Classic'**
  String get settings_themeStyle_classic;

  /// No description provided for @settings_themeStyle_neon.
  ///
  /// In en, this message translates to:
  /// **'Neon'**
  String get settings_themeStyle_neon;

  /// No description provided for @settings_themeStyle_rgbPulse.
  ///
  /// In en, this message translates to:
  /// **'RGB Pulse'**
  String get settings_themeStyle_rgbPulse;

  /// No description provided for @settings_themeStyle_classic_desc.
  ///
  /// In en, this message translates to:
  /// **'Classic — calm and professional'**
  String get settings_themeStyle_classic_desc;

  /// No description provided for @settings_themeStyle_neon_desc.
  ///
  /// In en, this message translates to:
  /// **'Neon — outlined and punchy'**
  String get settings_themeStyle_neon_desc;

  /// No description provided for @settings_themeStyle_rgb_desc.
  ///
  /// In en, this message translates to:
  /// **'RGB Pulse — dynamic style'**
  String get settings_themeStyle_rgb_desc;

  /// No description provided for @settings_themeStyle_rgb_hint.
  ///
  /// In en, this message translates to:
  /// **'Disables animation when Reduce Motion is enabled'**
  String get settings_themeStyle_rgb_hint;

  /// No description provided for @settings_accentSeed.
  ///
  /// In en, this message translates to:
  /// **'Primary accent'**
  String get settings_accentSeed;

  /// No description provided for @settings_accentSeed_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Affects buttons and UI highlights'**
  String get settings_accentSeed_subtitle;

  /// No description provided for @settings_accentSeed_disabled_rgb.
  ///
  /// In en, this message translates to:
  /// **'Not available during RGB Pulse'**
  String get settings_accentSeed_disabled_rgb;

  /// No description provided for @settings_appLanguage.
  ///
  /// In en, this message translates to:
  /// **'App language'**
  String get settings_appLanguage;

  /// No description provided for @settings_lang_system.
  ///
  /// In en, this message translates to:
  /// **'Device language'**
  String get settings_lang_system;

  /// No description provided for @settings_lang_ar.
  ///
  /// In en, this message translates to:
  /// **'Arabic'**
  String get settings_lang_ar;

  /// No description provided for @settings_lang_en.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get settings_lang_en;

  /// No description provided for @settings_reduceMotion.
  ///
  /// In en, this message translates to:
  /// **'Reduce motion (better performance)'**
  String get settings_reduceMotion;

  /// No description provided for @settings_reduceMotion_sub.
  ///
  /// In en, this message translates to:
  /// **'Reduces animations; RGB Pulse becomes static'**
  String get settings_reduceMotion_sub;

  /// No description provided for @settings_compactUi.
  ///
  /// In en, this message translates to:
  /// **'Compact UI'**
  String get settings_compactUi;

  /// No description provided for @settings_compactUi_sub.
  ///
  /// In en, this message translates to:
  /// **'Less padding for smaller screens'**
  String get settings_compactUi_sub;

  /// No description provided for @settings_textSize.
  ///
  /// In en, this message translates to:
  /// **'Text size'**
  String get settings_textSize;

  /// No description provided for @settings_haptics.
  ///
  /// In en, this message translates to:
  /// **'Light haptics'**
  String get settings_haptics;

  /// No description provided for @settings_haptics_sub.
  ///
  /// In en, this message translates to:
  /// **'Enable subtle vibration on key actions'**
  String get settings_haptics_sub;

  /// No description provided for @settings_note_locale.
  ///
  /// In en, this message translates to:
  /// **'Note: Language changes require UI strings to use AppLocalizations keys (avoid hardcoded texts).'**
  String get settings_note_locale;

  /// No description provided for @account_title.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get account_title;

  /// No description provided for @account_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Your profile and permissions'**
  String get account_subtitle;

  /// No description provided for @account_noData.
  ///
  /// In en, this message translates to:
  /// **'No user data'**
  String get account_noData;

  /// No description provided for @account_info.
  ///
  /// In en, this message translates to:
  /// **'Info'**
  String get account_info;

  /// No description provided for @account_roles.
  ///
  /// In en, this message translates to:
  /// **'Roles'**
  String get account_roles;

  /// No description provided for @account_logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get account_logout;

  /// No description provided for @staff_title.
  ///
  /// In en, this message translates to:
  /// **'Staff & Permissions'**
  String get staff_title;

  /// No description provided for @staff_add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get staff_add;

  /// No description provided for @staff_search_hint.
  ///
  /// In en, this message translates to:
  /// **'Search (name/email/phone)'**
  String get staff_search_hint;

  /// No description provided for @staff_status.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get staff_status;

  /// No description provided for @staff_status_all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get staff_status_all;

  /// No description provided for @staff_status_active.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get staff_status_active;

  /// No description provided for @staff_status_inactive.
  ///
  /// In en, this message translates to:
  /// **'Inactive'**
  String get staff_status_inactive;

  /// No description provided for @staff_apply.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get staff_apply;

  /// No description provided for @staff_noResults.
  ///
  /// In en, this message translates to:
  /// **'No results'**
  String get staff_noResults;

  /// No description provided for @staff_unauthorized.
  ///
  /// In en, this message translates to:
  /// **'Unauthorized'**
  String get staff_unauthorized;

  /// No description provided for @staff_retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get staff_retry;

  /// No description provided for @user_active.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get user_active;

  /// No description provided for @user_inactive.
  ///
  /// In en, this message translates to:
  /// **'Inactive'**
  String get user_inactive;

  /// No description provided for @user_enable.
  ///
  /// In en, this message translates to:
  /// **'Enable'**
  String get user_enable;

  /// No description provided for @user_disable.
  ///
  /// In en, this message translates to:
  /// **'Disable'**
  String get user_disable;

  /// No description provided for @resetPassword_title.
  ///
  /// In en, this message translates to:
  /// **'Reset password'**
  String get resetPassword_title;

  /// Shows user name in reset password dialog
  ///
  /// In en, this message translates to:
  /// **'User: {fullName}'**
  String resetPassword_user(String fullName);

  /// No description provided for @resetPassword_newPassword.
  ///
  /// In en, this message translates to:
  /// **'New password'**
  String get resetPassword_newPassword;

  /// No description provided for @resetPassword_hint.
  ///
  /// In en, this message translates to:
  /// **'At least 6 characters'**
  String get resetPassword_hint;

  /// No description provided for @resetPassword_cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get resetPassword_cancel;

  /// No description provided for @resetPassword_confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get resetPassword_confirm;

  /// No description provided for @resetPassword_short.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 6 characters'**
  String get resetPassword_short;

  /// No description provided for @resetPassword_success.
  ///
  /// In en, this message translates to:
  /// **'Password updated successfully'**
  String get resetPassword_success;

  /// No description provided for @staff_manage_title.
  ///
  /// In en, this message translates to:
  /// **'Staff & Permissions'**
  String get staff_manage_title;

  /// No description provided for @staff_add_user.
  ///
  /// In en, this message translates to:
  /// **'Add user'**
  String get staff_add_user;

  /// No description provided for @staff_disable_user_q.
  ///
  /// In en, this message translates to:
  /// **'Disable user?'**
  String get staff_disable_user_q;

  /// No description provided for @staff_enable_user_q.
  ///
  /// In en, this message translates to:
  /// **'Enable user?'**
  String get staff_enable_user_q;

  /// No description provided for @staff_disable_user_desc.
  ///
  /// In en, this message translates to:
  /// **'User will be blocked from login.'**
  String get staff_disable_user_desc;

  /// No description provided for @staff_enable_user_desc.
  ///
  /// In en, this message translates to:
  /// **'User will be allowed to login.'**
  String get staff_enable_user_desc;

  /// No description provided for @common_cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get common_cancel;

  /// No description provided for @common_confirm.
  ///
  /// In en, this message translates to:
  /// **'Copied'**
  String get common_confirm;

  /// No description provided for @common_apply.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get common_apply;

  /// No description provided for @common_all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get common_all;

  /// No description provided for @common_active.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get common_active;

  /// No description provided for @common_inactive.
  ///
  /// In en, this message translates to:
  /// **'Inactive'**
  String get common_inactive;

  /// No description provided for @common_retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get common_retry;

  /// No description provided for @common_search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get common_search;

  /// No description provided for @facility_code.
  ///
  /// In en, this message translates to:
  /// **'Facility Code'**
  String get facility_code;

  /// No description provided for @staff_id.
  ///
  /// In en, this message translates to:
  /// **'Staff ID'**
  String get staff_id;

  /// No description provided for @create_user_title.
  ///
  /// In en, this message translates to:
  /// **'Create user'**
  String get create_user_title;

  /// No description provided for @create_user_section.
  ///
  /// In en, this message translates to:
  /// **'User details'**
  String get create_user_section;

  /// No description provided for @create_user_full_name.
  ///
  /// In en, this message translates to:
  /// **'Full name'**
  String get create_user_full_name;

  /// No description provided for @create_user_email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get create_user_email;

  /// No description provided for @create_user_phone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get create_user_phone;

  /// No description provided for @create_user_password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get create_user_password;

  /// No description provided for @create_user_roles.
  ///
  /// In en, this message translates to:
  /// **'Roles'**
  String get create_user_roles;

  /// No description provided for @create_user_submit.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get create_user_submit;

  /// No description provided for @create_user_success.
  ///
  /// In en, this message translates to:
  /// **'User created successfully'**
  String get create_user_success;

  /// No description provided for @home_quick_new_patient.
  ///
  /// In en, this message translates to:
  /// **'New patient'**
  String get home_quick_new_patient;

  /// No description provided for @home_quick_new_patient_sub.
  ///
  /// In en, this message translates to:
  /// **'Register patient'**
  String get home_quick_new_patient_sub;

  /// No description provided for @home_quick_visit_admit.
  ///
  /// In en, this message translates to:
  /// **'Visit / Admit'**
  String get home_quick_visit_admit;

  /// No description provided for @home_quick_visit_admit_sub.
  ///
  /// In en, this message translates to:
  /// **'Open file'**
  String get home_quick_visit_admit_sub;

  /// No description provided for @home_quick_lab_order.
  ///
  /// In en, this message translates to:
  /// **'Lab order'**
  String get home_quick_lab_order;

  /// No description provided for @home_quick_lab_order_sub.
  ///
  /// In en, this message translates to:
  /// **'Tests'**
  String get home_quick_lab_order_sub;

  /// No description provided for @home_quick_prescription.
  ///
  /// In en, this message translates to:
  /// **'Prescription'**
  String get home_quick_prescription;

  /// No description provided for @home_quick_prescription_sub.
  ///
  /// In en, this message translates to:
  /// **'Dispense'**
  String get home_quick_prescription_sub;

  /// No description provided for @home_modules_title.
  ///
  /// In en, this message translates to:
  /// **'Modules'**
  String get home_modules_title;

  /// No description provided for @home_module_staff_sub.
  ///
  /// In en, this message translates to:
  /// **'Users, roles, permissions'**
  String get home_module_staff_sub;

  /// No description provided for @home_module_lab_sub.
  ///
  /// In en, this message translates to:
  /// **'Orders & results'**
  String get home_module_lab_sub;

  /// No description provided for @home_module_pharmacy_sub.
  ///
  /// In en, this message translates to:
  /// **'Prescriptions & dispensing'**
  String get home_module_pharmacy_sub;

  /// No description provided for @home_module_inventory_sub.
  ///
  /// In en, this message translates to:
  /// **'Items, stock, expiry'**
  String get home_module_inventory_sub;

  /// No description provided for @common_soon.
  ///
  /// In en, this message translates to:
  /// **'Soon'**
  String get common_soon;

  /// No description provided for @orders_title.
  ///
  /// In en, this message translates to:
  /// **'Orders Dashboard'**
  String get orders_title;

  /// No description provided for @orders_create.
  ///
  /// In en, this message translates to:
  /// **'Create order'**
  String get orders_create;

  /// No description provided for @orders_details_title.
  ///
  /// In en, this message translates to:
  /// **'Order details'**
  String get orders_details_title;

  /// No description provided for @orders_search_hint.
  ///
  /// In en, this message translates to:
  /// **'Search (code/patient/room)'**
  String get orders_search_hint;

  /// No description provided for @orders_patient.
  ///
  /// In en, this message translates to:
  /// **'Patient'**
  String get orders_patient;

  /// No description provided for @orders_room_bed.
  ///
  /// In en, this message translates to:
  /// **'Room/Bed'**
  String get orders_room_bed;

  /// No description provided for @orders_from_doctor.
  ///
  /// In en, this message translates to:
  /// **'From'**
  String get orders_from_doctor;

  /// No description provided for @orders_to.
  ///
  /// In en, this message translates to:
  /// **'To'**
  String get orders_to;

  /// No description provided for @orders_priority.
  ///
  /// In en, this message translates to:
  /// **'Priority'**
  String get orders_priority;

  /// No description provided for @orders_notes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get orders_notes;

  /// No description provided for @orders_target.
  ///
  /// In en, this message translates to:
  /// **'Target'**
  String get orders_target;

  /// No description provided for @orders_assignee.
  ///
  /// In en, this message translates to:
  /// **'Assign to'**
  String get orders_assignee;

  /// No description provided for @orders_pick.
  ///
  /// In en, this message translates to:
  /// **'Pick'**
  String get orders_pick;

  /// No description provided for @orders_pick_patient.
  ///
  /// In en, this message translates to:
  /// **'Pick patient'**
  String get orders_pick_patient;

  /// No description provided for @orders_pick_patient_hint.
  ///
  /// In en, this message translates to:
  /// **'Select patient'**
  String get orders_pick_patient_hint;

  /// No description provided for @orders_search_patient_hint.
  ///
  /// In en, this message translates to:
  /// **'Search patient (name/phone)'**
  String get orders_search_patient_hint;

  /// No description provided for @orders_pick_assignee.
  ///
  /// In en, this message translates to:
  /// **'Pick staff'**
  String get orders_pick_assignee;

  /// No description provided for @orders_pick_assignee_hint.
  ///
  /// In en, this message translates to:
  /// **'Select staff'**
  String get orders_pick_assignee_hint;

  /// No description provided for @orders_patient_required.
  ///
  /// In en, this message translates to:
  /// **'Patient is required'**
  String get orders_patient_required;

  /// No description provided for @orders_assignee_required.
  ///
  /// In en, this message translates to:
  /// **'Assignee is required'**
  String get orders_assignee_required;

  /// No description provided for @orders_no_results.
  ///
  /// In en, this message translates to:
  /// **'No results'**
  String get orders_no_results;

  /// No description provided for @orders_submit.
  ///
  /// In en, this message translates to:
  /// **'Submit order'**
  String get orders_submit;

  /// No description provided for @orders_sending.
  ///
  /// In en, this message translates to:
  /// **'Sending...'**
  String get orders_sending;

  /// No description provided for @orders_create_done.
  ///
  /// In en, this message translates to:
  /// **'Order created successfully'**
  String get orders_create_done;

  /// No description provided for @orders_ping.
  ///
  /// In en, this message translates to:
  /// **'Request update'**
  String get orders_ping;

  /// No description provided for @orders_ping_done.
  ///
  /// In en, this message translates to:
  /// **'Status update request sent'**
  String get orders_ping_done;

  /// No description provided for @orders_escalate.
  ///
  /// In en, this message translates to:
  /// **'Escalate'**
  String get orders_escalate;

  /// No description provided for @orders_escalate_done.
  ///
  /// In en, this message translates to:
  /// **'Escalated successfully'**
  String get orders_escalate_done;

  /// No description provided for @orders_reason_optional.
  ///
  /// In en, this message translates to:
  /// **'Reason (optional)'**
  String get orders_reason_optional;

  /// No description provided for @order_kind_medication.
  ///
  /// In en, this message translates to:
  /// **'Medication'**
  String get order_kind_medication;

  /// No description provided for @order_kind_lab.
  ///
  /// In en, this message translates to:
  /// **'Lab'**
  String get order_kind_lab;

  /// No description provided for @order_kind_procedure.
  ///
  /// In en, this message translates to:
  /// **'Procedure'**
  String get order_kind_procedure;

  /// No description provided for @tasks_title.
  ///
  /// In en, this message translates to:
  /// **'My Tasks'**
  String get tasks_title;

  /// No description provided for @tasks_filter_status.
  ///
  /// In en, this message translates to:
  /// **'Status filter'**
  String get tasks_filter_status;

  /// No description provided for @tasks_refresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get tasks_refresh;

  /// No description provided for @tasks_empty.
  ///
  /// In en, this message translates to:
  /// **'No tasks'**
  String get tasks_empty;

  /// No description provided for @tasks_start.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get tasks_start;

  /// No description provided for @tasks_complete.
  ///
  /// In en, this message translates to:
  /// **'Complete'**
  String get tasks_complete;

  /// No description provided for @tasks_note_title.
  ///
  /// In en, this message translates to:
  /// **'Note (optional)'**
  String get tasks_note_title;

  /// No description provided for @tasks_note_hint.
  ///
  /// In en, this message translates to:
  /// **'Write a note...'**
  String get tasks_note_hint;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
