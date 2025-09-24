import 'dart:developer' as developer;
import 'package:get_storage/get_storage.dart';
import '../models/campaign.dart';
import '../models/user.dart' as app_user;

class CacheService {
  static final GetStorage _storage = GetStorage();

  // Cache keys
  static const String _campaignsKey = 'cached_campaigns';
  static const String _userProfileKey = 'cached_user_profile';
  static const String _campaignsCacheTimeKey = 'campaigns_cache_time';
  static const String _userProfileCacheTimeKey = 'user_profile_cache_time';

  // Cache duration (5 minutes)
  static const Duration cacheDuration = Duration(minutes: 5);

  // Campaign caching
  static Future<void> cacheCampaigns(List<Campaign> campaigns) async {
    try {
      final campaignsJson = campaigns.map((c) => c.toJson()).toList();
      await _storage.write(_campaignsKey, campaignsJson);
      await _storage.write(
        _campaignsCacheTimeKey,
        DateTime.now().millisecondsSinceEpoch,
      );
      developer.log(
        'Cached ${campaigns.length} campaigns',
        name: 'CacheService',
      );
    } catch (e) {
      developer.log('Error caching campaigns: $e', name: 'CacheService');
    }
  }

  static List<Campaign>? getCachedCampaigns() {
    try {
      final cacheTime = _storage.read(_campaignsCacheTimeKey);
      if (cacheTime == null) return null;

      final lastCached = DateTime.fromMillisecondsSinceEpoch(cacheTime);
      if (DateTime.now().difference(lastCached) > cacheDuration) {
        // Cache expired
        clearCampaignsCache();
        return null;
      }

      final campaignsJson = _storage.read(_campaignsKey);
      if (campaignsJson == null) return null;

      final campaigns = (campaignsJson as List)
          .map((json) => Campaign.fromJson(json))
          .toList();

      developer.log(
        'Retrieved ${campaigns.length} campaigns from cache',
        name: 'CacheService',
      );
      return campaigns;
    } catch (e) {
      developer.log(
        'Error retrieving cached campaigns: $e',
        name: 'CacheService',
      );
      return null;
    }
  }

  static Future<void> clearCampaignsCache() async {
    await _storage.remove(_campaignsKey);
    await _storage.remove(_campaignsCacheTimeKey);
  }

  // User profile caching
  static Future<void> cacheUserProfile(app_user.User user) async {
    try {
      await _storage.write(_userProfileKey, user.toJson());
      await _storage.write(
        _userProfileCacheTimeKey,
        DateTime.now().millisecondsSinceEpoch,
      );
    } catch (e) {
      // Handle caching error silently
    }
  }

  static app_user.User? getCachedUserProfile() {
    try {
      final cacheTime = _storage.read(_userProfileCacheTimeKey);
      if (cacheTime == null) return null;

      final lastCached = DateTime.fromMillisecondsSinceEpoch(cacheTime);
      if (DateTime.now().difference(lastCached) > cacheDuration) {
        // Cache expired
        clearUserProfileCache();
        return null;
      }

      final userJson = _storage.read(_userProfileKey);
      if (userJson == null) return null;

      final user = app_user.User.fromJson(userJson);
      return user;
    } catch (e) {
      return null;
    }
  }

  static Future<void> clearUserProfileCache() async {
    await _storage.remove(_userProfileKey);
    await _storage.remove(_userProfileCacheTimeKey);
  }

  // Clear all cache
  static Future<void> clearAllCache() async {
    await clearCampaignsCache();
    await clearUserProfileCache();
    developer.log('Cleared all cache', name: 'CacheService');
  }

  // Cache health check
  static Map<String, dynamic> getCacheStatus() {
    final campaignsCacheTime = _storage.read(_campaignsCacheTimeKey);
    final userProfileCacheTime = _storage.read(_userProfileCacheTimeKey);

    return {
      'campaigns_cached': campaignsCacheTime != null,
      'campaigns_cache_age': campaignsCacheTime != null
          ? DateTime.now()
                .difference(
                  DateTime.fromMillisecondsSinceEpoch(campaignsCacheTime),
                )
                .inMinutes
          : null,
      'user_profile_cached': userProfileCacheTime != null,
      'user_profile_cache_age': userProfileCacheTime != null
          ? DateTime.now()
                .difference(
                  DateTime.fromMillisecondsSinceEpoch(userProfileCacheTime),
                )
                .inMinutes
          : null,
    };
  }
}
