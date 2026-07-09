# Flutter Data Handling & Serialization Rules

## JSON Serialization
* Use `json_serializable` and `json_annotation`.
* **Naming:** Use `fieldRename: FieldRename.snake` for consistency.

```dart
@JsonSerializable(fieldRename: FieldRename.snake)
class User {
  final String firstName;
  final String lastName;
  User({required this.firstName, required this.lastName});
  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
}
```

## Async Patterns
* Use `Future`, `async`, `await` for asynchronous operations.
* Use `Stream` for sequences of events over time.
* Write sound null-safe code — avoid the `!` operator unless value is guaranteed non-null.
* Use switch expressions and pattern matching where applicable (Dart 3+).
* Use records for returning multiple values from a function.
