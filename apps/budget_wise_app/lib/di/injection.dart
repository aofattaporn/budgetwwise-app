import 'dart:io';
import 'package:app_template/features/accounts/data/datasources/account_remote_datasource.dart';
import 'package:app_template/features/accounts/data/repositories/account_repository_impl.dart';
import 'package:app_template/features/accounts/domain/repositories/account_repository.dart';
import 'package:app_template/features/transactions/data/datasources/transaction_remote_datasource.dart';
import 'package:app_template/features/transactions/data/repositories/transaction_repository_impl.dart';
import 'package:app_template/features/transactions/domain/repositories/transaction_repository.dart';
import 'package:app_template/features/transactions/domain/services/transaction_balance_service.dart';
import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide LocalStorage;

import '../config/app_config.dart';
import '../core/core.dart';
import '../data/data.dart';
import '../domain/domain.dart';

final getIt = GetIt.instance;

/// Configure dependencies
Future<void> configureDependencies() async {
  // ─────────────────────────────────────────────────────────────
  // Core
  // ─────────────────────────────────────────────────────────────
  getIt.registerLazySingleton<LocalStorage>(() => SharedPrefsStorage());
  getIt.registerLazySingleton<NetworkInfo>(() => NetworkInfoImpl());
  getIt.registerLazySingleton<ApiClient>(() => DioApiClient(baseUrl: AppConfig.apiBaseUrl),);

  // ─────────────────────────────────────────────────────────────
  // Supabase (if using Supabase backend)
  // ─────────────────────────────────────────────────────────────
  if (BackendConfig.isSupabase) {
    print('🔵 Initializing Supabase...');
    print('URL: ${AppConfig.supabaseUrl}');

    try {
      // Allow self-signed certificates in local development only.
      // kDebugMode is a compile-time constant, so this can never run in a
      // release build (web/prod), where TLS verification stays enforced.
      if (kDebugMode) {
        HttpOverrides.global = _DevHttpOverrides();
      }

      await Supabase.initialize(
        url: AppConfig.supabaseUrl,
        anonKey: AppConfig.supabaseAnonKey,
      );
      print('✅ Supabase initialized successfully');
      getIt.registerLazySingleton<SupabaseClient>(() => Supabase.instance.client);
    } catch (e) {
      print('❌ Supabase initialization failed: $e');
      rethrow;
    }
  }

  // ─────────────────────────────────────────────────────────────
  // Data Sources
  // ─────────────────────────────────────────────────────────────
  if (BackendConfig.isSupabase) {
    getIt.registerLazySingleton<AuthDataSource>(() => AuthSupabaseDataSource(supabaseClient: getIt<SupabaseClient>()));
    getIt.registerLazySingleton<PlanDataSource>(() => PlanSupabaseDataSource(getIt<SupabaseClient>()));
    getIt.registerLazySingleton<AccountRemoteDataSource>(() => AccountRemoteDataSource(getIt<SupabaseClient>()));
    getIt.registerLazySingleton<TransactionRemoteDataSource>(() => TransactionRemoteDataSource(getIt<SupabaseClient>()));

  } else {
    getIt.registerLazySingleton<AuthDataSource>(() => AuthRestDataSource(apiClient: getIt<ApiClient>(), localStorage: getIt<LocalStorage>()));
  }

  // ─────────────────────────────────────────────────────────────
  // Repositories
  // ─────────────────────────────────────────────────────────────
  getIt.registerLazySingleton<AuthRepository>(() => AuthRepositoryImpl(dataSource: getIt<AuthDataSource>(),networkInfo: getIt<NetworkInfo>()));

  if (BackendConfig.isSupabase) {
    getIt.registerLazySingleton<PlanRepository>(() => PlanRepositoryImpl(getIt<PlanDataSource>()));
    getIt.registerLazySingleton<AccountRepository>(() => AccountRepositoryImpl(getIt<AccountRemoteDataSource>()));
    getIt.registerLazySingleton<TransactionRepository>(() => TransactionRepositoryImpl(getIt<TransactionRemoteDataSource>()));
    getIt.registerLazySingleton<TransactionBalanceService>(() => TransactionBalanceService(getIt<AccountRepository>()));
  }

  // ─────────────────────────────────────────────────────────────
  // Use Cases
  // ─────────────────────────────────────────────────────────────
  getIt.registerLazySingleton(() => LoginUseCase(getIt<AuthRepository>()));
  getIt.registerLazySingleton(() => RegisterUseCase(getIt<AuthRepository>()));
  getIt.registerLazySingleton(() => LogoutUseCase(getIt<AuthRepository>()));
  getIt.registerLazySingleton(() => GetCurrentUserUseCase(getIt<AuthRepository>()));

}

// ⚠️ DEVELOPMENT ONLY - Bypass SSL certificate verification
// Remove this in production!
class _DevHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback = (X509Certificate cert, String host, int port) {
        print('⚠️ Accepting certificate for $host');
        return true;
      };
  }
}
