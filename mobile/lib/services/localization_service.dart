import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

const _kLanguageStorageKey = 'tiyrasense_selected_language';

/// Reactive Localization Service for TiyraSense Mobile.
///
/// Supports 5 regional languages across the North Eastern Region:
/// - English (en)
/// - অসমীয়া / Assamese (as)
/// - বাংলা / Bengali (bn)
/// - हिन्दी / Hindi (hi)
/// - মৈতৈলোন্ / Manipuri (mni)  [Replaced Bodo per user specification]
///
/// Constraint: "TiyraSense" app name is strictly preserved in English everywhere.
class LocalizationService extends ChangeNotifier {
  static final LocalizationService _instance = LocalizationService._internal();
  factory LocalizationService() => _instance;

  final FlutterSecureStorage _storage;
  String _localeCode = 'en';

  LocalizationService._internal({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  String get localeCode => _localeCode;

  static const List<Map<String, String>> supportedLanguages = [
    {'code': 'en', 'name': 'English', 'native': 'English'},
    {'code': 'as', 'name': 'Assamese', 'native': 'অসমীয়া (Assamese)'},
    {'code': 'bn', 'name': 'Bengali', 'native': 'বাংলা (Bengali)'},
    {'code': 'hi', 'name': 'Hindi', 'native': 'हिन्दी (Hindi)'},
    {'code': 'mni', 'name': 'Manipuri', 'native': 'মৈতৈলোন্ (Manipuri)'},
  ];

  String get currentLanguageName {
    final match = supportedLanguages.firstWhere(
      (l) => l['code'] == _localeCode,
      orElse: () => supportedLanguages.first,
    );
    return match['name']!;
  }

  String get currentLanguageNativeName {
    final match = supportedLanguages.firstWhere(
      (l) => l['code'] == _localeCode,
      orElse: () => supportedLanguages.first,
    );
    return match['native']!;
  }

  Future<void> initialize() async {
    try {
      final savedCode = await _storage.read(key: _kLanguageStorageKey);
      if (savedCode != null && supportedLanguages.any((l) => l['code'] == savedCode)) {
        _localeCode = savedCode;
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<void> setLanguageCode(String code) async {
    if (_localeCode == code) return;
    if (!supportedLanguages.any((l) => l['code'] == code)) return;
    _localeCode = code;
    try {
      await _storage.write(key: _kLanguageStorageKey, value: code);
    } catch (_) {}
    notifyListeners();
  }

  Future<void> setLanguageByNativeOrName(String nativeOrName) async {
    final match = supportedLanguages.firstWhere(
      (l) => l['native'] == nativeOrName || l['name'] == nativeOrName || nativeOrName.contains(l['name']!),
      orElse: () => supportedLanguages.first,
    );
    await setLanguageCode(match['code']!);
  }

  /// Translates a key according to the currently active locale.
  /// If the translation is missing, it falls back to English.
  String tr(String key) {
    // App name invariant: TiyraSense is always English across all languages
    if (key == 'app_name') return 'TiyraSense';

    final localizedMap = _translations[_localeCode] ?? _translations['en']!;
    if (localizedMap.containsKey(key)) {
      return localizedMap[key]!;
    }
    return _translations['en']?[key] ?? key;
  }

  static const Map<String, Map<String, String>> _translations = {
    'en': {
      'app_name': 'TiyraSense',
      // Profile Screen
      'account': 'ACCOUNT',
      'edit_profile': 'Edit Profile',
      'change_password': 'Change Password',
      'app_settings': 'APP',
      'offline_data': 'Offline Data',
      'notifications': 'Notifications',
      'language': 'Language',
      'select_language': 'Select Language',
      'app_version': 'App Version',
      'sync_now': 'Sync Now',
      'clear_cache': 'Clear Cache',
      'log_out': 'Sign Out',
      'journeys': 'JOURNEYS',
      'reports': 'REPORTS',
      'safety_score': 'SAFETY SCORE',
      'save_changes': 'Save Changes',
      'driver_profile': 'Driver Profile',
      'field_worker_profile': 'Field Worker Profile',
      'active_duty': 'ACTIVE DUTY',
      'full_name': 'Full Name',
      'phone_number': 'Phone Number',
      'email_address': 'Email Address',
      'role': 'Role',
      'assigned_region': 'Assigned Region',
      'current_password': 'Current Password',
      'new_password': 'New Password',
      'confirm_password': 'Confirm New Password',
      'update_password': 'Update Password',
      'sync_complete': 'Sync Complete',
      'syncing_telemetry': 'Syncing Telemetry',
      'cache_cleared': 'Cache cleared successfully',

      // Navigation & Tabs
      'home': 'Home',
      'map': 'Map',
      'plan': 'Plan',
      'alerts': 'Alerts',
      'profile': 'Profile',

      // Dashboard
      'active_corridor': 'Active Corridor',
      'corridor_status': 'Corridor Status',
      'plan_journey': 'Plan Journey',
      'report_hazard': 'Report Hazard',
      'quick_actions': 'Quick Actions',
      'recent_alerts': 'Recent Alerts',
      'view_all': 'View All',
      'speed': 'Speed',
      'remaining': 'Remaining',
      'open': 'Open',
      'caution': 'Caution',
      'risk': 'Risk',
      'offline_ready': 'Offline Ready',
      'truck_axle_specs': 'Truck & Axle Specs',
      'emergency_sos': 'Emergency SOS & Towing',
      'emergency_helplines': 'Emergency Highway Helplines',
      'report_history': 'Report History',
      'monsoon_watch': 'Monsoon Watch',

      // Map & Navigation
      'navigate': 'Navigate',
      'stop_navigation': 'Stop Navigation',
      'change_route': 'Change Route',
      'hazard_ahead': 'Hazard Ahead',
      'safest_viable': 'Safest Viable',
      'faster_available': 'Faster Available',

      // Alerts & Reports
      'all_alerts': 'All Alerts',
      'mark_all_read': 'Mark all read',
      'broadcast_report': 'Broadcast Incident Report',
      'attach_photo': 'Attach Evidence Photo',

      // Common & Telemetry
      'on_duty_escort': 'On Duty · Primary Escort Unit',
      'field_recon_active': 'Field Reconnaissance Unit · Active Sector',
      'gps_locked': 'GPS / NavIC Locked',
      'updated_ago': 'Updated 2m ago',
      'operational_telemetry': 'OPERATIONAL TELEMETRY',
      'traffic': 'TRAFFIC',
      'traffic_regulated': 'Regulated',
      'slip_risk': 'SLIP RISK',
      'slip_risk_low': '18% Low',
      'confidence': 'CONFIDENCE',
      'confidence_val': '98%',
      'plan_safer_journey': 'Plan Safer Journey',
      'ai_checks_risk': 'AI checks risk, detours, timing',
      'corridor_alerts': 'Corridor Alerts',
      'active_count': 'Active',
      'weather_radar': 'Weather Radar',
      'doppler_feed': 'Doppler Feed',
      'sos_police': 'SOS / Police',
      'bro_police_post': 'BRO / Police Post',
      'priority': 'Priority',
      'incident_reports_history': 'Incident Reports & History',
      'view_field_submissions': 'View your field submissions & verification status',
      'passable': 'PASSABLE',
      'normal_flow': 'Normal flow · Clear weather · Landslide probability < 15%',

      // Navigation Maneuver & Google Maps Bar
      'now': 'Now',
      'then': 'Then',
      'steps': 'Steps',
      'clauses': 'Clauses',
      'recenter': 'Re-center',
      'exit': 'Exit',
      'live_telemetry_streaming': 'LIVE TELEMETRY STREAMING',
      'guidance_active': 'Guidance Active',
      'speed_limit': 'LIMIT',
      'in_distance': 'In',

      // Journey Planning
      'swap': 'Swap',
      'available_candidate_routes': 'AVAILABLE CANDIDATE ROUTES',
      'recommended': 'Recommended',
      'recommended_fastest': 'Recommended · Fastest',
      'recommended_safest': 'Recommended (Safest)',
      'faster': 'Faster',
      'faster_option': 'Faster Option',
      'alternative_bypass': 'Alternative Bypass',
      'clauses_applied': 'Clauses Applied',
      'disruption': 'Disruption',
      'risk_low': 'Risk: LOW',
      'risk_moderate': 'Risk: MODERATE',
      'risk_high': 'Risk: HIGH',
      'confirm_route': 'Confirm Route',
      'confirm_safe_route': 'Confirm Route',
      'low_risk': 'Low Risk',
      'moderate': 'Moderate',
      'high_risk': 'High Risk',
      'select_origin': 'Select Origin / Start Location',
      'select_dest': 'Select Destination',
      'use_current_gps': 'Use Current GPS Location',

      // Alerts
      'filter_all': 'ALL',
      'filter_unread': 'UNREAD',
      'filter_emergency': 'EMERGENCY',
      'filter_weather': 'WEATHER',
      'view_details': 'View Details',
      'dismiss': 'Dismiss',

      // Report History
      'total_submissions': 'TOTAL SUBMISSIONS',
      'my_reports': 'MY REPORTS',
      'pending_review': 'PENDING REVIEW',
      'filter_pending': 'PENDING',
      'filter_verified': 'VERIFIED',
      'report_hazard_btn': 'Report Hazard',
      'incident_report_history': 'Incident Report History',
      'quick_dispatch': 'QUICK DISPATCH',
      'connectivity_sync': 'Connectivity & Sync',
      'report_road_hazard': 'Report Road Hazard',
      'hazard_landslide': 'Landslide',
      'hazard_flood': 'Flash Flood',
      'hazard_subsidence': 'Subsidence',
      'hazard_fallen_tree': 'Fallen Tree',
    },

    'as': {
      'app_name': 'TiyraSense',
      // Profile Screen
      'account': 'একাউণ্ট',
      'edit_profile': 'প্ৰফাইল সম্পাদনা',
      'change_password': 'পাছৱৰ্ড সলনি কৰক',
      'app_settings': 'এপ ছেটিংছ',
      'offline_data': 'অফলাইন ডাটা',
      'notifications': 'জাননীসমূহ',
      'language': 'ভাষা',
      'select_language': 'ভাষা নিৰ্বাচন কৰক',
      'app_version': 'এপ সংস্কৰণ',
      'sync_now': 'এতিয়াই সংমিশ্ৰণ কৰক',
      'clear_cache': 'কেশ্ব খালী কৰক',
      'log_out': 'লগ আউট',
      'journeys': 'যাত্ৰাসমূহ',
      'reports': 'প্ৰতিবেদনসমূহ',
      'safety_score': 'সুৰক্ষা স্কোৰ',
      'save_changes': 'পৰিৱৰ্তন সংৰক্ষণ কৰক',
      'driver_profile': 'চালকৰ প্ৰফাইল',
      'field_worker_profile': 'ক্ষেত্ৰ কৰ্মীৰ প্ৰফাইল',
      'active_duty': 'সক্ৰিয় কৰ্তব্য',
      'full_name': 'সম্পূৰ্ণ নাম',
      'phone_number': 'ফোন নম্বৰ',
      'email_address': 'ইমেইল ঠিকনা',
      'role': 'ভূমিকা',
      'assigned_region': 'নিৰ্ধাৰিত অঞ্চল',
      'current_password': 'বৰ্তমানৰ পাছৱৰ্ড',
      'new_password': 'নতুন পাছৱৰ্ড',
      'confirm_password': 'নতুন পাছৱৰ্ড নিশ্চিত কৰক',
      'update_password': 'পাছৱৰ্ড আপডেট কৰক',
      'sync_complete': 'সংমিশ্ৰণ সম্পূৰ্ণ হ’ল',
      'syncing_telemetry': 'টেলিমেট্ৰি সংমিশ্ৰণ হৈ আছে',
      'cache_cleared': 'কেশ্ব সফলতাৰে খালী কৰা হ’ল',

      // Navigation & Tabs
      'home': 'গৃহ',
      'map': 'মানচিত্ৰ',
      'plan': 'পৰিকল্পনা',
      'alerts': 'সতৰ্কবাৰ্তা',
      'profile': 'প্ৰফাইল',

      // Dashboard
      'active_corridor': 'সক্ৰিয় কৰিডৰ',
      'corridor_status': 'কৰিডৰৰ অৱস্থা',
      'plan_journey': 'যাত্ৰা পৰিকল্পনা কৰক',
      'report_hazard': 'বিপদৰ প্ৰতিবেদন দিয়ক',
      'quick_actions': 'দ্ৰুত কাৰ্যকলাপ',
      'recent_alerts': 'শেহতীয়া সতৰ্কবাৰ্তা',
      'view_all': 'সকলো চাওক',
      'speed': 'গতি',
      'remaining': 'বাকী থকা',
      'open': 'মুক্ত',
      'caution': 'সতৰ্কতা',
      'risk': 'বিপদজনক',
      'offline_ready': 'অফলাইন প্ৰস্তুত',
      'truck_axle_specs': 'ট্ৰাক আৰু এক্সেল নিৰ্দিষ্টকৰণ',
      'emergency_sos': 'জৰুৰীকালীন SOS আৰু টোয়িং',
      'emergency_helplines': 'জৰুৰীকালীন ঘাইপথ হেল্পলাইনসমূহ',
      'report_history': 'প্ৰতিবেদনৰ ইতিহাস',
      'monsoon_watch': 'বৰ্ষাকালীন নিৰীক্ষণ',

      // Map & Navigation
      'navigate': 'নেভিগেট কৰক',
      'stop_navigation': 'নেভিগেচন বন্ধ কৰক',
      'change_route': 'পথ সলনি কৰক',
      'hazard_ahead': 'আগত বিপদ আছে',
      'safest_viable': 'আটাইতকৈ সুৰক্ষিত পথ',
      'faster_available': 'দ্ৰুততম উপলব্ধ পথ',

      // Alerts & Reports
      'all_alerts': 'সকলো সতৰ্কবাৰ্তা',
      'mark_all_read': 'সকলো পঢ়া বুলি চিহ্নিত কৰক',
      'broadcast_report': 'ঘটনাৰ প্ৰতিবেদন প্ৰচাৰ কৰক',
      'attach_photo': 'প্ৰমাণ ফটো সংলগ্ন কৰক',

      // Common & Telemetry
      'on_duty_escort': 'সক্ৰিয় কৰ্তব্য · মুখ্য এস্কৰ্ট গোট',
      'field_recon_active': 'ক্ষেত্ৰ অনুসন্ধান গোট · সক্ৰিয় খণ্ড',
      'gps_locked': 'GPS / NavIC লক',
      'updated_ago': '২ মিনিট পূৰ্বে আপডেট কৰা হৈছে',
      'operational_telemetry': 'কাৰ্যকৰী টেলিমেট্ৰি',
      'traffic': 'ট্ৰাফিক',
      'traffic_regulated': 'নিয়ন্ত্ৰিত',
      'slip_risk': 'পিছল খোৱাৰ আশংকা',
      'slip_risk_low': '১৮% কম',
      'confidence': 'বিশ্বাসযোগ্যতা',
      'confidence_val': '৯৮%',
      'plan_safer_journey': 'সুৰক্ষিত যাত্ৰা পৰিকল্পনা কৰক',
      'ai_checks_risk': 'AI-য়ে বিপদ, পথ আৰু সময় নিৰীক্ষণ কৰে',
      'corridor_alerts': 'কৰিডৰ সতৰ্কতা',
      'active_count': 'সক্ৰিয়',
      'weather_radar': 'বতৰৰ ৰাডাৰ',
      'doppler_feed': 'ডপলাৰ ফিড',
      'sos_police': 'SOS / আৰক্ষী',
      'bro_police_post': 'BRO / আৰক্ষী চকী',
      'priority': 'প্ৰাথমিকতা',
      'incident_reports_history': 'ঘটনাৰ প্ৰতিবেদন আৰু ইতিহাস',
      'view_field_submissions': 'আপোনাৰ দাখিল কৰা প্ৰতিবেদন আৰু অৱস্থা চাওক',
      'passable': 'চলনশীল',
      'normal_flow': 'স্বাভাৱিক চলাচল · পৰিষ্কাৰ বতৰ · ভূমিস্খলনৰ সম্ভাৱনা < ১৫%',

      // Navigation Maneuver & Google Maps Bar
      'now': 'এতিয়া',
      'then': 'তাৰ পিছত',
      'steps': 'পদক্ষেপ',
      'clauses': 'ধাৰা',
      'recenter': 'পুনৰ কেন্দ্ৰীভূত কৰক',
      'exit': 'বাহিৰ হওক',
      'live_telemetry_streaming': 'লাইভ টেলিমেট্ৰি সম্প্ৰচাৰ',
      'guidance_active': 'পথপ্ৰদৰ্শন সক্ৰিয়',
      'speed_limit': 'সীমা',
      'in_distance': 'আগত',

      // Journey Planning
      'swap': 'বিনিময়',
      'available_candidate_routes': 'উপলব্ধ সম্ভাৱ্য পথসমূহ',
      'recommended': 'পৰামৰ্শিত',
      'recommended_fastest': 'পৰামৰ্শ প্ৰাপ্ত · দ্ৰুততম',
      'recommended_safest': 'পৰামৰ্শ প্ৰাপ্ত (নিৰাপদতম)',
      'faster': 'দ্ৰুততম',
      'faster_option': 'দ্ৰুততম বিকল্প',
      'alternative_bypass': 'বিকল্প বাইপাছ',
      'clauses_applied': 'ধাৰা প্ৰযোজ্য',
      'disruption': 'বিঘিনি',
      'risk_low': 'বিপদ: কম',
      'risk_moderate': 'বিপদ: মধ্যম',
      'risk_high': 'বিপদ: অধিক',
      'confirm_route': 'পথ নিশ্চিত কৰক',
      'confirm_safe_route': 'পথ নিশ্চিত কৰক',
      'low_risk': 'কম বিপদ',
      'moderate': 'মধ্যম',
      'high_risk': 'উচ্চ বিপদ',
      'select_origin': 'যাত্ৰাৰম্ভ স্থান বাছক',
      'select_dest': 'গন্তব্যস্থান বাছক',
      'use_current_gps': 'বৰ্তমানৰ GPS স্থান ব্যৱহাৰ কৰক',

      // Alerts
      'filter_all': 'সকলো',
      'filter_unread': 'নপঢ়া',
      'filter_emergency': 'জৰুৰীকালীন',
      'filter_weather': 'বতৰ',
      'view_details': 'বিৱৰণ চাওক',
      'dismiss': 'বাতিল কৰক',

      // Report History
      'total_submissions': 'মুঠ দাখিল',
      'my_reports': 'মোৰ প্ৰতিবেদন',
      'pending_review': 'পৰ্যালোচনা বাকী',
      'filter_pending': 'অমীমাংসিত',
      'filter_verified': 'সত্যতা প্ৰতিপন্ন',
      'report_hazard_btn': 'বিপদ প্ৰতিবেদন কৰক',
      'incident_report_history': 'ঘটনাৰ প্ৰতিবেদনৰ ইতিহাস',
      'quick_dispatch': 'ক্ষিপ্ৰ প্ৰেৰণ',
      'connectivity_sync': 'সংযোগ আৰু সমন্বয়',
      'report_road_hazard': 'পথৰ বিপদ প্ৰতিবেদন কৰক',
      'hazard_landslide': 'ভূমিস্খলন',
      'hazard_flood': 'হঠাতে বান',
      'hazard_subsidence': 'পথ অৱনমন',
      'hazard_fallen_tree': 'পৰি থকা গছ',
    },

    'bn': {
      'app_name': 'TiyraSense',
      // Profile Screen
      'account': 'অ্যাকাউন্ট',
      'edit_profile': 'প্রোফাইল সম্পাদনা',
      'change_password': 'পাসওয়ার্ড পরিবর্তন',
      'app_settings': 'অ্যাপ সেটিংস',
      'offline_data': 'অফলাইন ডেটা',
      'notifications': 'বিজ্ঞপ্তি',
      'language': 'ভাষা',
      'select_language': 'ভাষা নির্বাচন করুন',
      'app_version': 'অ্যাপ সংস্করণ',
      'sync_now': 'এখনই সিঙ্ক করুন',
      'clear_cache': 'ক্যাশে পরিষ্কার করুন',
      'log_out': 'লগ আউট',
      'journeys': 'যাত্রা',
      'reports': 'প্রতিবেদন',
      'safety_score': 'নিরাপত্তা স্কোর',
      'save_changes': 'পরিবর্তন সংরক্ষণ করুন',
      'driver_profile': 'চালক প্রোফাইল',
      'field_worker_profile': 'ফিল্ড কর্মী প্রোফাইল',
      'active_duty': 'সক্রিয় ডিউটি',
      'full_name': 'পুরো নাম',
      'phone_number': 'ফোন নম্বর',
      'email_address': 'ইমেল ঠিকানা',
      'role': 'ভূমিকা',
      'assigned_region': 'নির্ধারিত অঞ্চল',
      'current_password': 'বর্তমান পাসওয়ার্ড',
      'new_password': 'নতুন পাসওয়ার্ড',
      'confirm_password': 'নতুন পাসওয়ার্ড নিশ্চিত করুন',
      'update_password': 'পাসওয়ার্ড আপডেট করুন',
      'sync_complete': 'সিঙ্ক সম্পন্ন হয়েছে',
      'syncing_telemetry': 'টেলিমেট্রি সিঙ্ক হচ্ছে',
      'cache_cleared': 'ক্যাশে সফলভাবে পরিষ্কার করা হয়েছে',

      // Navigation & Tabs
      'home': 'হোম',
      'map': 'মানচিত্র',
      'plan': 'পরিকল্পনা',
      'alerts': 'সতর্কতা',
      'profile': 'প্রোফাইল',

      // Dashboard
      'active_corridor': 'সক্রিয় করিডোর',
      'corridor_status': 'করিডোরের অবস্থা',
      'plan_journey': 'যাত্রা পরিকল্পনা করুন',
      'report_hazard': 'বিপদ রিপোর্ট করুন',
      'quick_actions': 'দ্রুত পদক্ষেপ',
      'recent_alerts': 'সাম্প্রতিক সতর্কতা',
      'view_all': 'সব দেখুন',
      'speed': 'গতিবেগ',
      'remaining': 'অবশিষ্ট',
      'open': 'উন্মুক্ত',
      'caution': 'সতর্কতা',
      'risk': 'ঝুঁকিপূর্ণ',
      'offline_ready': 'অফলাইন প্রস্তুত',
      'truck_axle_specs': 'ট্রাক ও এক্সেল স্পেসিফিকেশন',
      'emergency_sos': 'জরুরি এসওএস ও টোয়িং',
      'emergency_helplines': 'জরুরি হাইওয়ে হেল্পলাইন',
      'report_history': 'রিপোর্টের ইতিহাস',
      'monsoon_watch': 'বর্ষাকালীন পর্যবেক্ষণ',

      // Map & Navigation
      'navigate': 'নেভিগেট করুন',
      'stop_navigation': 'নেভিগেশন বন্ধ করুন',
      'change_route': 'রুট পরিবর্তন',
      'hazard_ahead': 'সামনে বিপদ আছে',
      'safest_viable': 'সবচেয়ে নিরাপদ পথ',
      'faster_available': 'দ্রুততম উপলব্ধ পথ',

      // Alerts & Reports
      'all_alerts': 'সব সতর্কতা',
      'mark_all_read': 'সব পঠিত হিসেবে চিহ্নিত করুন',
      'broadcast_report': 'ঘটনার রিপোর্ট সম্প্রচার করুন',
      'attach_photo': 'প্রমাণ ছবি যুক্ত করুন',

      // Common & Telemetry
      'on_duty_escort': 'সক্রিয় ডিউটি · প্রাথমিক এস্কর্ট ইউনিট',
      'field_recon_active': 'ফিল্ড রিকনাইসেন্স ইউনিট · সক্রিয় সেক্টর',
      'gps_locked': 'GPS / NavIC লক করা',
      'updated_ago': '২ মিনিট আগে আপডেট হয়েছে',
      'operational_telemetry': 'অপারেশনাল টেলিমেট্রি',
      'traffic': 'ট্রাফিক',
      'traffic_regulated': 'নিয়ন্ত্রিত',
      'slip_risk': 'পিচ্ছিলতার ঝুঁকি',
      'slip_risk_low': '১৮% কম',
      'confidence': 'বিশ্বাসযোগ্যতা',
      'confidence_val': '৯৮%',
      'plan_safer_journey': 'নিরাপদ যাত্রা পরিকল্পনা করুন',
      'ai_checks_risk': 'AI ঝুঁকি, ডাইভারশন ও সময় যাচাই করে',
      'corridor_alerts': 'করিডোর সতর্কতা',
      'active_count': 'সক্রিয়',
      'weather_radar': 'আবহাওয়া রাডার',
      'doppler_feed': 'ডপলার ফিড',
      'sos_police': 'এসওএস / পুলিশ',
      'bro_police_post': 'BRO / পুলিশ পোস্ট',
      'priority': 'অগ্রাধিকার',
      'incident_reports_history': 'ঘটনার রিপোর্ট ও ইতিহাস',
      'view_field_submissions': 'আপনার ফিল্ড রিপোর্ট ও যাচাই অবস্থা দেখুন',
      'passable': 'চলাচলযোগ্য',
      'normal_flow': 'স্বাভাবিক চলাচল · পরিষ্কার আবহাওয়া · ভূমিধসের সম্ভাবনা < ১৫%',

      // Navigation Maneuver & Google Maps Bar
      'now': 'এখন',
      'then': 'তারপর',
      'steps': 'ধাপ',
      'clauses': 'ধারা',
      'recenter': 'পুনরায় কেন্দ্রস্থ',
      'exit': 'প্রস্থান',
      'live_telemetry_streaming': 'লাইভ টেলিমেট্রি স্ট্রিমিং',
      'guidance_active': 'নির্দেশনা সক্রিয়',
      'speed_limit': 'সীমা',
      'in_distance': 'সামনে',

      // Journey Planning
      'swap': 'অদলবদল',
      'available_candidate_routes': 'উপলব্ধ বিকল্প রুটসমূহ',
      'recommended': 'সুপারিশকৃত',
      'recommended_fastest': 'সুপারিশকৃত · দ্রুততম',
      'recommended_safest': 'সুপারিশকৃত (নিরাপদতম)',
      'faster': 'দ্রুততর',
      'faster_option': 'দ্রুততর বিকল্প',
      'alternative_bypass': 'বিকল্প বাইপাস',
      'clauses_applied': 'ধারা প্রযোজ্য',
      'disruption': 'বিঘ্নতা',
      'risk_low': 'ঝুঁকি: কম',
      'risk_moderate': 'ঝুঁকি: মাঝারি',
      'risk_high': 'ঝুঁকি: উচ্চ',
      'confirm_route': 'পথ নিশ্চিত করুন',
      'confirm_safe_route': 'পথ নিশ্চিত করুন',
      'low_risk': 'কম ঝুঁকি',
      'moderate': 'মাঝারি',
      'high_risk': 'উচ্চ ঝুঁকি',
      'select_origin': 'যাত্রা শুরুর স্থান নির্বাচন করুন',
      'select_dest': 'গন্তব্য নির্বাচন করুন',
      'use_current_gps': 'বর্তমান GPS অবস্থান ব্যবহার করুন',

      // Alerts
      'filter_all': 'সব',
      'filter_unread': 'অপঠিত',
      'filter_emergency': 'জরুরি',
      'filter_weather': 'আবহাওয়া',
      'view_details': 'বিস্তারিত দেখুন',
      'dismiss': 'বাতিল করুন',

      // Report History
      'total_submissions': 'মোট দাখিলকৃত',
      'my_reports': 'আমার রিপোর্ট',
      'pending_review': 'পর্যালোচনাধীন',
      'filter_pending': 'অপেক্ষমান',
      'filter_verified': 'যাচাইকৃত',
      'report_hazard_btn': 'বিপদ রিপোর্ট করুন',
      'incident_report_history': 'ঘটনার রিপোর্টের ইতিহাস',
      'quick_dispatch': 'দ্রুত প্রেরণ',
      'connectivity_sync': 'সংযোগ ও সিঙ্ক',
      'report_road_hazard': 'রাস্তার বিপদ রিপোর্ট করুন',
      'hazard_landslide': 'ভূমিধস',
      'hazard_flood': 'আকস্মিক বন্যা',
      'hazard_subsidence': 'রাস্তা দেবে যাওয়া',
      'hazard_fallen_tree': 'গাছ ভেঙে পড়া',
    },

    'hi': {
      'app_name': 'TiyraSense',
      // Profile Screen
      'account': 'खाता',
      'edit_profile': 'प्रोफ़ाइल संपादित करें',
      'change_password': 'पासवर्ड बदलें',
      'app_settings': 'ऐप सेटिंग्स',
      'offline_data': 'ऑफ़लाइन डेटा',
      'notifications': 'सूचनाएं',
      'language': 'भाषा',
      'select_language': 'भाषा चुनें',
      'app_version': 'ऐप संस्करण',
      'sync_now': 'अभी सिंक करें',
      'clear_cache': 'कैश साफ़ करें',
      'log_out': 'लॉग आउट',
      'journeys': 'यात्राएं',
      'reports': 'रिपोर्ट्स',
      'safety_score': 'सुरक्षा स्कोर',
      'save_changes': 'बदलाव सहेजें',
      'driver_profile': 'ड्राइवर प्रोफ़ाइल',
      'field_worker_profile': 'फ़ील्ड कार्यकर्ता प्रोफ़ाइल',
      'active_duty': 'सक्रिय ड्यूटी',
      'full_name': 'पूरा नाम',
      'phone_number': 'फ़ोन नंबर',
      'email_address': 'ईमेल पता',
      'role': 'भूमिका',
      'assigned_region': 'सौंपा गया क्षेत्र',
      'current_password': 'वर्तमान पासवर्ड',
      'new_password': 'नया पासवर्ड',
      'confirm_password': 'नए पासवर्ड की पुष्टि करें',
      'update_password': 'पासवर्ड अपडेट करें',
      'sync_complete': 'सिंक पूरा हुआ',
      'syncing_telemetry': 'टेलीमेट्री सिंक हो रही है',
      'cache_cleared': 'कैश सफलतापूर्वक साफ़ कर दिया गया',

      // Navigation & Tabs
      'home': 'होम',
      'map': 'मानचित्र',
      'plan': 'योजना',
      'alerts': 'अलर्ट',
      'profile': 'प्रोफ़ाइल',

      // Dashboard
      'active_corridor': 'सक्रिय कॉरिडोर',
      'corridor_status': 'कॉरिडोर की स्थिति',
      'plan_journey': 'यात्रा योजना बनाएं',
      'report_hazard': 'खतरे की रिपोर्ट करें',
      'quick_actions': 'त्वरित कार्रवाई',
      'recent_alerts': 'हालिया अलर्ट',
      'view_all': 'सभी देखें',
      'speed': 'गति',
      'remaining': 'शेष',
      'open': 'खुला',
      'caution': 'सावधानी',
      'risk': 'खतरा',
      'offline_ready': 'ऑफ़लाइन तैयार',
      'truck_axle_specs': 'ट्रक और एक्सल विवरण',
      'emergency_sos': 'आपातकालीन एसओएस और टोइंग',
      'emergency_helplines': 'आपातकालीन राजमार्ग हेल्पलाइन',
      'report_history': 'रिपोर्ट इतिहास',
      'monsoon_watch': 'मानसून निगरानी',

      // Map & Navigation
      'navigate': 'नेविगेट करें',
      'stop_navigation': 'नेविगेशन रोकें',
      'change_route': 'मार्ग बदलें',
      'hazard_ahead': 'आगे खतरा है',
      'safest_viable': 'सबसे सुरक्षित मार्ग',
      'faster_available': 'तेज़ उपलब्ध मार्ग',

      // Alerts & Reports
      'all_alerts': 'सभी अलर्ट',
      'mark_all_read': 'सभी को पढ़ा हुआ चिह्नित करें',
      'broadcast_report': 'घटना रिपोर्ट प्रसारित करें',
      'attach_photo': 'सबूत फोटो जोड़ें',

      // Common & Telemetry
      'on_duty_escort': 'सक्रिय ड्यूटी · प्राथमिक एस्कॉर्ट यूनिट',
      'field_recon_active': 'फ़ील्ड टोही इकाई · सक्रिय क्षेत्र',
      'gps_locked': 'GPS / NavIC लॉक किया गया',
      'updated_ago': '2 मिनट पहले अपडेट',
      'operational_telemetry': 'परिचालन टेलीमेट्री',
      'traffic': 'यातायात',
      'traffic_regulated': 'नियंत्रित',
      'slip_risk': 'फिसलन जोखिम',
      'slip_risk_low': '18% कम',
      'confidence': 'सटीकता',
      'confidence_val': '98%',
      'plan_safer_journey': 'सुरक्षित यात्रा की योजना बनाएं',
      'ai_checks_risk': 'AI जोखिम, मोड़ और समय की जांच करता है',
      'corridor_alerts': 'कॉरिडोर अलर्ट',
      'active_count': 'सक्रिय',
      'weather_radar': 'मौसम रडार',
      'doppler_feed': 'डॉप्लर फ़ीड',
      'sos_police': 'एसओएस / पुलिस',
      'bro_police_post': 'BRO / पुलिस चौकी',
      'priority': 'प्राथमिकता',
      'incident_reports_history': 'घटना रिपोर्ट और इतिहास',
      'view_field_submissions': 'अपनी फ़ील्ड रिपोर्ट और स्थिति देखें',
      'passable': 'सुगम',
      'normal_flow': 'सामान्य आवागमन · साफ़ मौसम · भूस्खलन की संभावना < 15%',

      // Navigation Maneuver & Google Maps Bar
      'now': 'अब',
      'then': 'फिर',
      'steps': 'कदम',
      'clauses': 'शर्तें',
      'recenter': 'पुनः केंद्रित करें',
      'exit': 'बाहर निकलें',
      'live_telemetry_streaming': 'लाइव टेलीमेट्री स्ट्रीमिंग',
      'guidance_active': 'मार्गदर्शन सक्रिय',
      'speed_limit': 'सीमा',
      'in_distance': 'आगे',

      // Journey Planning
      'swap': 'स्थान बदलें',
      'available_candidate_routes': 'उपलब्ध संभावित मार्ग',
      'recommended': 'अनुशंसित',
      'recommended_fastest': 'अनुशंसित · सबसे तेज़',
      'recommended_safest': 'अनुशंसित (सबसे सुरक्षित)',
      'faster': 'तेज़',
      'faster_option': 'तेज़ विकल्प',
      'alternative_bypass': 'वैकल्पिक बाईपास',
      'clauses_applied': 'शर्तें लागू',
      'disruption': 'बाधा',
      'risk_low': 'जोखिम: कम',
      'risk_moderate': 'जोखिम: मध्यम',
      'risk_high': 'जोखिम: उच्च',
      'confirm_route': 'मार्ग की पुष्टि करें',
      'confirm_safe_route': 'मार्ग की पुष्टि करें',
      'low_risk': 'कम जोखिम',
      'moderate': 'मध्यम',
      'high_risk': 'उच्च जोखिम',
      'select_origin': 'प्रारंभिक स्थान चुनें',
      'select_dest': 'गंतव्य स्थान चुनें',
      'use_current_gps': 'वर्तमान GPS स्थान का उपयोग करें',

      // Alerts
      'filter_all': 'सभी',
      'filter_unread': 'अपठित',
      'filter_emergency': 'आपातकालीन',
      'filter_weather': 'मौसम',
      'view_details': 'विवरण देखें',
      'dismiss': 'खारिज करें',

      // Report History
      'total_submissions': 'कुल सबमिशन',
      'my_reports': 'मेरी रिपोर्ट्स',
      'pending_review': 'समीक्षा लंबित',
      'filter_pending': 'लंबित',
      'filter_verified': 'सत्यापित',
      'report_hazard_btn': 'खतरे की रिपोर्ट करें',
      'incident_report_history': 'घटना रिपोर्ट इतिहास',
      'quick_dispatch': 'त्वरित प्रेषण',
      'connectivity_sync': 'कनेक्टिविटी और सिंक',
      'report_road_hazard': 'सड़क के खतरे की रिपोर्ट करें',
      'hazard_landslide': 'भूस्खलन',
      'hazard_flood': 'अचानक बाढ़',
      'hazard_subsidence': 'सड़क धंसाव',
      'hazard_fallen_tree': 'गिरा हुआ पेड़',
    },

    'mni': {
      'app_name': 'TiyraSense',
      // Profile Screen
      'account': 'একাউণ্ট',
      'edit_profile': 'প্রোফাইল শেমদোকপা',
      'change_password': 'পাসৱার্দ হোংদোকপা',
      'app_settings': 'এপ সেটিং',
      'offline_data': 'ওফলাইন দেতা',
      'notifications': 'পাউচে শিং',
      'language': 'লোন',
      'select_language': 'লোন খল্লু',
      'app_version': 'এপ ভর্জন',
      'sync_now': 'হৌজিক সিংহক তৌরো',
      'clear_cache': 'কেস শেংদোকউ',
      'log_out': 'লোগ আউত',
      'journeys': 'চৎথোক-চৎশিন',
      'reports': 'রিপোর্তশিং',
      'safety_score': 'ঙাকথোকপা স্কোর',
      'save_changes': 'শেমদোকপা থমজিনবা',
      'driver_profile': 'দ্রাইভর প্রোফাইল',
      'field_worker_profile': 'ফিল্দ ৱার্কর প্রোফাইল',
      'active_duty': 'থবক চত্থরিবা',
      'full_name': 'মপুং ফাবা মিং',
      'phone_number': 'ফোন নম্বর',
      'email_address': 'ইমেইল এদ্রেস',
      'role': 'থৌদাং',
      'assigned_region': 'পীখিবা লমদম',
      'current_password': 'হৌজিক্কী পাসৱার্দ',
      'new_password': 'অনোউবা পাসৱার্দ',
      'confirm_password': 'অনোউবা পাসৱার্দ চেৎশিলহনবা',
      'update_password': 'পাসৱার্দ অপদেত তৌবা',
      'sync_complete': 'সিংহক তৌবা লোইরে',
      'syncing_telemetry': 'তেলিমিত্রি সিংহক তৌরি',
      'cache_cleared': 'কেস শেংদোকপা লোইরে',

      // Navigation & Tabs
      'home': 'য়ুম',
      'map': 'মেপ',
      'plan': 'থৌরাং',
      'alerts': 'চেকশিনৱা',
      'profile': 'প্রোফাইল',

      // Dashboard
      'active_corridor': 'চৎলিবা লম্বী',
      'corridor_status': 'লম্বীগী ফিভম',
      'plan_journey': 'চৎনবা থৌরাং তৌবা',
      'report_hazard': 'খুদোংথিবা রিপোর্ত তৌবা',
      'quick_actions': 'অথুবা থবকশিং',
      'recent_alerts': 'হন্দক্কী চেকশিনৱা',
      'view_all': 'পুম্নমক য়েংবা',
      'speed': 'খোঙজেল',
      'remaining': 'ৱাৎলিবা',
      'open': 'হাংলি',
      'caution': 'চেকশিনবা',
      'risk': 'খুদোংথিবা',
      'offline_ready': 'ওফলাইন শেম-শাবা',
      'truck_axle_specs': 'গারী অমসুং এক্সেল স্পেক',
      'emergency_sos': 'অথুবা এসওএস অমসুং টোয়িং',
      'emergency_helplines': 'অথুবা হাইৱে হেল্পলাইন',
      'report_history': 'রিপোর্তকী পুৱারী',
      'monsoon_watch': 'নোংগী ফিভম য়েংশিনবা',

      // Map & Navigation
      'navigate': 'লম্বী চৎপা',
      'stop_navigation': 'নেভিগেশন লেপকনু',
      'change_route': 'লম্বী হোংদোকপা',
      'hazard_ahead': 'মাঙদা খুদোংথিবা লৈ',
      'safest_viable': 'খ্বাইদগী ঙাকথোকপা লম্বী',
      'faster_available': 'য়াংনা য়ৌবা লম্বী',

      // Alerts & Reports
      'all_alerts': 'পুম্নমক চেকশিনৱা',
      'mark_all_read': 'পুম্নমক পারবনি খনবা',
      'broadcast_report': 'খুদোংথিবা পাউ থাদোকপা',
      'attach_photo': 'ফোটো য়াওহনবা',

      // Common & Telemetry
      'on_duty_escort': 'থবক চত্থরি · মরুওইবা এস্কোর্ত য়ুনিৎ',
      'field_recon_active': 'ফিল্দ রিকোন্নেসান্স য়ুনিৎ · এক্তিব সেক্তর',
      'gps_locked': 'GPS / NavIC লোক তৌরে',
      'updated_ago': 'মিনিত ২গী মমাংদা অপদেৎ তৌরে',
      'operational_telemetry': 'ওপরেস্নেল তেলিমেত্রী',
      'traffic': 'ত্রাফিক',
      'traffic_regulated': 'নিয়ম চত্থবা',
      'slip_risk': 'খোংদ্রোইথিবা রিস্ক',
      'slip_risk_low': '১৮% নেমবা',
      'confidence': 'থাগৎপা',
      'confidence_val': '৯৮%',
      'plan_safer_journey': 'হেন্না নুংঙাইবা খোঙচৎ য়ারোইবা থৌরাং',
      'ai_checks_risk': 'AIনা রিস্ক, ৱাংমথোই অমসুং মতম য়েংশিল্লি',
      'corridor_alerts': 'কোরিদোর এলর্তশিং',
      'active_count': 'এক্তিব',
      'weather_radar': 'নোংশিৎ রাদার',
      'doppler_feed': 'দোপ্লর ফীদ',
      'sos_police': 'এসওএস / পুলিস',
      'bro_police_post': 'BRO / পুলিস পোস্ত',
      'priority': 'অহানবা',
      'incident_reports_history': 'থৌদোকশিংগী রিপোর্ত অমসুং পুৱারি',
      'view_field_submissions': 'নহাক্কী ফিল্দ সবমিসনশিং অমসুং পরিং য়েংবিয়ু',
      'passable': 'চৎপা য়াবা',
      'normal_flow': 'চত্থোক-চৎশিন মায় পাক্না · নুংঙাইবা নোংশিৎ · ইচেল খোংলোই < ১৫%',

      // Navigation Maneuver & Google Maps Bar
      'now': 'হৌজিক',
      'then': 'মদুগী মতুংদা',
      'steps': 'খোঙথাংশিং',
      'clauses': 'ক্লোজশিং',
      'recenter': 'অমুক হন্না ময়ায় ওনবিয়ু',
      'exit': 'থোকপা',
      'live_telemetry_streaming': 'লাইভ তেলিমেত্রী স্ত্রীমিং',
      'guidance_active': 'লমজিংবা হৌরে',
      'speed_limit': 'লিমিত',
      'in_distance': 'মাঙদা',

      // Journey Planning
      'swap': 'হোনবা',
      'available_candidate_routes': 'ফংলিবা লম্বীশিং',
      'recommended': 'রেকোমেন্দ তৌবা',
      'recommended_fastest': 'রেকোমেন্দ · খ্বাইদগী য়াংবা',
      'recommended_safest': 'রেকোমেন্দ (খ্বাইদগী নিংথিনা লৈবা)',
      'faster': 'য়াংবা',
      'faster_option': 'য়াংবা বিকল্প',
      'alternative_bypass': 'অতোপ্পা লম্বী',
      'clauses_applied': 'ক্লোজশিং শিজিন্নরে',
      'disruption': 'অকাইবা',
      'risk_low': 'রিস্ক: নেমবা',
      'risk_moderate': 'রিস্ক: ময়ায়',
      'risk_high': 'রিস্ক: ৱাংবা',
      'confirm_route': 'লম্বী য়ানবিয়ু',
      'confirm_safe_route': 'লম্বী য়ানবিয়ু',
      'low_risk': 'নেম্বা রিস্ক',
      'moderate': 'ময়ায় ওম্বা',
      'high_risk': 'ৱাংবা রিস্ক',
      'select_origin': 'হৌরকফম মফম খনবিয়ু',
      'select_dest': 'য়ৌগদবা মফম খনবিয়ু',
      'use_current_gps': 'হৌজিক্কী GPS মফম শিজিন্নবিয়ু',

      // Alerts
      'filter_all': 'ময়াম',
      'filter_unread': 'পারিদ্রবা',
      'filter_emergency': 'অকন্না',
      'filter_weather': 'নোংশিৎ',
      'view_details': 'অকুপ্পা য়েংবিয়ু',
      'dismiss': 'লৌথোকপিয়ু',

      // Report History
      'total_submissions': 'পুল্লপ সবমিসন',
      'my_reports': 'ঐগী রিপোর্তশিং',
      'pending_review': 'য়েংশিন্নবা লৈরিবা',
      'filter_pending': 'লৈরিবা',
      'filter_verified': 'য়েংশিল্লবা',
      'report_hazard_btn': 'খুদোংথিবা রিপোর্ত তৌবিয়ু',
      'incident_report_history': 'থৌদোক রিপোর্তকী পুৱারি',
      'quick_dispatch': 'থুনা থাবা',
      'connectivity_sync': 'শম্নবা অমসুং সিঙ্ক',
      'report_road_hazard': 'লম্বীগী খুদোংথিবা রিপোর্ত তৌবিয়ু',
      'hazard_landslide': 'চীং কায়বা',
      'hazard_flood': 'খংহৌদনা ঈচাউ থোকপা',
      'hazard_subsidence': 'লম্বী কায়বা',
      'hazard_fallen_tree': 'উপাল তুবা',
    },
  };
}

final localizationService = LocalizationService();
