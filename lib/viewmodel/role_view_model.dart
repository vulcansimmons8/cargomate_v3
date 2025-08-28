import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RoleViewModel extends ChangeNotifier {
  final SupabaseClient _supa = Supabase.instance.client;

  bool _loading = true;
  bool get loading => _loading;

  String _role = 'customer';
  String get role => _role;
  String? _userId;

  void setRole(String newRole) {
    _role = newRole;
    notifyListeners();
  }

  Future<void> clearRole() async {
    if (_userId == null) return;

    try {
      await _supa
          .from('profiles')
          .update({'role': null})
          .eq('id', _userId as Object);
    } catch (e) {
      if (kDebugMode) {
        print('Error clearing role: $e');
      }
    }

    _role = 'customer';
    _loading = false;
    _userId = null;
    notifyListeners();
  }
}
