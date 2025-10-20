import 'package:flutter/material.dart';

class FilterViewModel extends ChangeNotifier{
  String? _selectGender;
  double _minHeight = 100;
  double _maxHeight = 200;
  Set<String> _selectPlaces = {};
  Set<String> _selectSeason = {};
  Set<String> _selectStyles = {};

  String? get selectGender => _selectGender;
  double get minHeight => _minHeight;
  double get maxHeight => _maxHeight;
  Set<String> get selectPlaces => _selectPlaces;
  Set<String> get selectSeason => _selectSeason;
  Set<String> get selectStyles => _selectStyles;

  void setInitialFilters({
    String? gender,
    List<String>? styles,
    List<String>? places,
    List<String>? season,
    double? minHeight,
    double? maxHeight,
  }){
    _selectGender=gender;
    _selectStyles=Set<String>.from(styles ?? []);
    _selectPlaces = Set<String>.from(places ?? []);
    _selectSeason = Set<String>.from(season ?? []);
    _minHeight = minHeight ?? 100;
    _maxHeight = maxHeight ?? 200;
    notifyListeners();
  }

  void toggleGender(String gender) {
    if (_selectGender == gender) {
      _selectGender = null;
    } else {
      _selectGender = gender;
    }
    notifyListeners();
  }

  void updateHeight(RangeValues newHeight) {
    _minHeight = newHeight.start;
    _maxHeight = newHeight.end;
    notifyListeners();
  }

  void togglePlace(String places) {
    if (_selectPlaces.contains(places)) {
      _selectPlaces.remove(places);
    } else {
      _selectPlaces.add(places);
    }
    notifyListeners();
  }

  void toggleSeason(String season) {
    if (_selectSeason.contains(season)) {
      _selectSeason.remove(season);
    } else {
      _selectSeason.add(season);
    }
    notifyListeners();
  }

  void toggleStyle(String styles) {
    if (_selectStyles.contains(styles)) {
      _selectStyles.remove(styles);
    } else {
      _selectStyles.add(styles);
    }
    notifyListeners();
  }


  void resetFilter(){
    _selectSeason.clear();
    _selectPlaces.clear();
    _selectStyles.clear();
    _selectGender = null;
    _minHeight=100;
    _maxHeight=200;
    notifyListeners();
  }
}