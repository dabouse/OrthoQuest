class Setting {
  final String key;
  final String value;

  Setting({required this.key, required this.value});

  Map<String, dynamic> toMap() {
    return {'key': key, 'value': value};
  }

  factory Setting.fromMap(Map<String, dynamic> map) {
    return Setting(key: map['key'], value: map['value']);
  }
}
