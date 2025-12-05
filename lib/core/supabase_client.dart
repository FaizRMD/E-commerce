// lib/core/supabase_client.dart

import 'package:supabase_flutter/supabase_flutter.dart';

/// Global Supabase client yang digunakan di seluruh aplikasi.
///
/// Cara pakai:
/// ```dart
/// import '../../core/supabase_client.dart';
///
/// final products = await supabase.from('products').select('*');
/// ```
///
/// Keamanan:
/// - Di Flutter, gunakan HANYA anon public key Supabase.
/// - Jangan pernah menaruh `service_role` key di aplikasi klien.
/// - Pastikan tabel sensitif (orders, carts, dsb) dilindungi Row Level Security (RLS).
final SupabaseClient supabase = Supabase.instance.client;
