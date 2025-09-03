// lib/providers/user_provider.dart
import 'package:flutter/material.dart';
import '../models/user_model.dart';


class UserProvider extends ChangeNotifier {
  UserModel? _user;
  UserProfile? _profile;
  bool _isLoading = false;

  UserModel? get user => _user;
  UserProfile? get profile => _profile;
  bool get isLoading => _isLoading;

  void setUser(UserModel? user) {
    _user = user;
    notifyListeners();
  }

  void setProfile(UserProfile? profile) {
    _profile = profile;
    notifyListeners();
  }

  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void updateProfile(UserProfile profile) {
    _profile = profile;
    notifyListeners();
  }

  void clear() {
    _user = null;
    _profile = null;
    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadUserFromFirebase() async {}
}