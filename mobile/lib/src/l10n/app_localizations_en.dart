// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'CareSync';

  @override
  String get hospitalFirst => 'Hospital First';

  @override
  String get nav_home => 'Home';

  @override
  String get nav_staff => 'Staff';

  @override
  String get nav_account => 'Account';

  @override
  String get nav_orders => 'Orders';

  @override
  String get nav_tasks => 'My Tasks';

  @override
  String get login_title => 'Sign in';

  @override
  String get login_tenant => 'Facility Code';

  @override
  String get login_tenant_hint => 'Paste the facility code or identifier';

  @override
  String get login_email => 'Email';

  @override
  String get login_phone => 'Phone';

  @override
  String get login_password => 'Password';

  @override
  String get login_button => 'Login';

  @override
  String get login_failed => 'Login failed. Please check your details.';

  @override
  String get settings_title => 'Settings';

  @override
  String get settings_header_title => 'Full Control';

  @override
  String get settings_header_subtitle_normal =>
      'Choose theme, language, and accessibility options';

  @override
  String get settings_header_subtitle_rgb =>
      'RGB Pulse is active — vivid dynamic experience';

  @override
  String get settings_appearance => 'Appearance';

  @override
  String get settings_language => 'Language';

  @override
  String get settings_accessibility => 'Accessibility & Performance';

  @override
  String get settings_experience => 'Experience';

  @override
  String get settings_about => 'About';

  @override
  String get settings_themeMode => 'Theme mode';

  @override
  String get settings_themeMode_system => 'System';

  @override
  String get settings_themeMode_light => 'Light';

  @override
  String get settings_themeMode_dark => 'Dark';

  @override
  String get settings_themeStyle => 'Theme style';

  @override
  String get settings_themeStyle_classic => 'Classic';

  @override
  String get settings_themeStyle_neon => 'Neon';

  @override
  String get settings_themeStyle_rgbPulse => 'RGB Pulse';

  @override
  String get settings_themeStyle_classic_desc =>
      'Classic — calm and professional';

  @override
  String get settings_themeStyle_neon_desc => 'Neon — outlined and punchy';

  @override
  String get settings_themeStyle_rgb_desc => 'RGB Pulse — dynamic style';

  @override
  String get settings_themeStyle_rgb_hint =>
      'Disables animation when Reduce Motion is enabled';

  @override
  String get settings_accentSeed => 'Primary accent';

  @override
  String get settings_accentSeed_subtitle =>
      'Affects buttons and UI highlights';

  @override
  String get settings_accentSeed_disabled_rgb =>
      'Not available during RGB Pulse';

  @override
  String get settings_appLanguage => 'App language';

  @override
  String get settings_lang_system => 'Device language';

  @override
  String get settings_lang_ar => 'Arabic';

  @override
  String get settings_lang_en => 'English';

  @override
  String get settings_reduceMotion => 'Reduce motion (better performance)';

  @override
  String get settings_reduceMotion_sub =>
      'Reduces animations; RGB Pulse becomes static';

  @override
  String get settings_compactUi => 'Compact UI';

  @override
  String get settings_compactUi_sub => 'Less padding for smaller screens';

  @override
  String get settings_textSize => 'Text size';

  @override
  String get settings_haptics => 'Light haptics';

  @override
  String get settings_haptics_sub => 'Enable subtle vibration on key actions';

  @override
  String get settings_note_locale =>
      'Note: Language changes require UI strings to use AppLocalizations keys (avoid hardcoded texts).';

  @override
  String get account_title => 'Account';

  @override
  String get account_subtitle => 'Your profile and permissions';

  @override
  String get account_noData => 'No user data';

  @override
  String get account_info => 'Info';

  @override
  String get account_roles => 'Roles';

  @override
  String get account_logout => 'Logout';

  @override
  String get staff_title => 'Staff & Permissions';

  @override
  String get staff_add => 'Add';

  @override
  String get staff_search_hint => 'Search (name/email/phone)';

  @override
  String get staff_status => 'Status';

  @override
  String get staff_status_all => 'All';

  @override
  String get staff_status_active => 'Active';

  @override
  String get staff_status_inactive => 'Inactive';

  @override
  String get staff_apply => 'Apply';

  @override
  String get staff_noResults => 'No results';

  @override
  String get staff_unauthorized => 'Unauthorized';

  @override
  String get staff_retry => 'Retry';

  @override
  String get user_active => 'Active';

  @override
  String get user_inactive => 'Inactive';

  @override
  String get user_enable => 'Enable';

  @override
  String get user_disable => 'Disable';

  @override
  String get resetPassword_title => 'Reset password';

  @override
  String resetPassword_user(String fullName) {
    return 'User: $fullName';
  }

  @override
  String get resetPassword_newPassword => 'New password';

  @override
  String get resetPassword_hint => 'At least 6 characters';

  @override
  String get resetPassword_cancel => 'Cancel';

  @override
  String get resetPassword_confirm => 'Confirm';

  @override
  String get resetPassword_short => 'Password must be at least 6 characters';

  @override
  String get resetPassword_success => 'Password updated successfully';

  @override
  String get staff_manage_title => 'Staff & Permissions';

  @override
  String get staff_add_user => 'Add user';

  @override
  String get staff_disable_user_q => 'Disable user?';

  @override
  String get staff_enable_user_q => 'Enable user?';

  @override
  String get staff_disable_user_desc => 'User will be blocked from login.';

  @override
  String get staff_enable_user_desc => 'User will be allowed to login.';

  @override
  String get common_cancel => 'Cancel';

  @override
  String get common_confirm => 'Copied';

  @override
  String get common_apply => 'Apply';

  @override
  String get common_all => 'All';

  @override
  String get common_active => 'Active';

  @override
  String get common_inactive => 'Inactive';

  @override
  String get common_retry => 'Retry';

  @override
  String get common_search => 'Search';

  @override
  String get facility_code => 'Facility Code';

  @override
  String get staff_id => 'Staff ID';

  @override
  String get create_user_title => 'Create user';

  @override
  String get create_user_section => 'User details';

  @override
  String get create_user_full_name => 'Full name';

  @override
  String get create_user_email => 'Email';

  @override
  String get create_user_phone => 'Phone';

  @override
  String get create_user_password => 'Password';

  @override
  String get create_user_roles => 'Roles';

  @override
  String get create_user_submit => 'Create';

  @override
  String get create_user_success => 'User created successfully';

  @override
  String get home_quick_new_patient => 'New patient';

  @override
  String get home_quick_new_patient_sub => 'Register patient';

  @override
  String get home_quick_visit_admit => 'Visit / Admit';

  @override
  String get home_quick_visit_admit_sub => 'Open file';

  @override
  String get home_quick_lab_order => 'Lab order';

  @override
  String get home_quick_lab_order_sub => 'Tests';

  @override
  String get home_quick_prescription => 'Prescription';

  @override
  String get home_quick_prescription_sub => 'Dispense';

  @override
  String get home_modules_title => 'Modules';

  @override
  String get home_module_staff_sub => 'Users, roles, permissions';

  @override
  String get home_module_lab_sub => 'Orders & results';

  @override
  String get home_module_pharmacy_sub => 'Prescriptions & dispensing';

  @override
  String get home_module_inventory_sub => 'Items, stock, expiry';

  @override
  String get common_soon => 'Soon';

  @override
  String get orders_title => 'Orders Dashboard';

  @override
  String get orders_create => 'Create order';

  @override
  String get orders_details_title => 'Order details';

  @override
  String get orders_search_hint => 'Search (code/patient/room)';

  @override
  String get orders_patient => 'Patient';

  @override
  String get orders_room_bed => 'Room/Bed';

  @override
  String get orders_from_doctor => 'From';

  @override
  String get orders_to => 'To';

  @override
  String get orders_priority => 'Priority';

  @override
  String get orders_notes => 'Notes';

  @override
  String get orders_target => 'Target';

  @override
  String get orders_assignee => 'Assign to';

  @override
  String get orders_pick => 'Pick';

  @override
  String get orders_pick_patient => 'Pick patient';

  @override
  String get orders_pick_patient_hint => 'Select patient';

  @override
  String get orders_search_patient_hint => 'Search patient (name/phone)';

  @override
  String get orders_pick_assignee => 'Pick staff';

  @override
  String get orders_pick_assignee_hint => 'Select staff';

  @override
  String get orders_patient_required => 'Patient is required';

  @override
  String get orders_assignee_required => 'Assignee is required';

  @override
  String get orders_no_results => 'No results';

  @override
  String get orders_submit => 'Submit order';

  @override
  String get orders_sending => 'Sending...';

  @override
  String get orders_create_done => 'Order created successfully';

  @override
  String get orders_ping => 'Request update';

  @override
  String get orders_ping_done => 'Status update request sent';

  @override
  String get orders_escalate => 'Escalate';

  @override
  String get orders_escalate_done => 'Escalated successfully';

  @override
  String get orders_reason_optional => 'Reason (optional)';

  @override
  String get order_kind_medication => 'Medication';

  @override
  String get order_kind_lab => 'Lab';

  @override
  String get order_kind_procedure => 'Procedure';

  @override
  String get tasks_title => 'My Tasks';

  @override
  String get tasks_filter_status => 'Status filter';

  @override
  String get tasks_refresh => 'Refresh';

  @override
  String get tasks_empty => 'No tasks';

  @override
  String get tasks_start => 'Start';

  @override
  String get tasks_complete => 'Complete';

  @override
  String get tasks_note_title => 'Note (optional)';

  @override
  String get tasks_note_hint => 'Write a note...';
}
