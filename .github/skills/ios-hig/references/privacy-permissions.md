# Privacy & Permissions Guidelines (Flutter on iOS)

## Permission Requests UX

iOS requires apps to explicitly request user permissions for sensitive capabilities. Apple enforces strict rules on timing, justification, and frequency.

### Pre-prompt screens (recommended)

iOS provides only one chance to show the system permission alert. If the user denies it, re-requesting shows a degraded alert with no explanation. Best practice: show an in-app rationale screen before triggering the system alert.

```dart
// ✅ Pre-prompt explaining WHY you need the permission
showCupertinoDialog(
  context: context,
  builder: (context) => CupertinoAlertDialog(
    title: Text('Why Do We Need Photo Access?'),
    content: Text(
      'We need access to your photo library to save images of your baby milestones. '
      'All photos stay on your device and are never uploaded anywhere.',
    ),
    actions: [
      CupertinoDialogAction(
        child: Text('Cancel'),
        onPressed: () => Navigator.pop(context),
      ),
      CupertinoDialogAction(
        isDefaultAction: true,
        child: Text('Continue'),
        onPressed: () {
          Navigator.pop(context);
          _requestPhotoPermission(); // Now trigger system alert
        },
      ),
    ],
  ),
);

// ❌ Triggering system permission without context — user doesn't know why
_imagePicker.pickImage(source: ImageSource.gallery);
```

### Permission-specific guidance

| Permission | When to Request | Handle Denial |
|---|---|---|
| **Camera** | When user taps "Take Photo" — never on app launch | Show dialog linking to Settings to change decision |
| **Photo Library** | When saving/loading photos — same rule | Redirect to Settings if previously denied |
| **Notifications** | After user sees value (e.g., logs first reminder) | Nudge gently; don't block core features |
| **Location** | mamadera does NOT need this — avoid entirely | N/A |

> **Privacy-first mandate for mamadera:** The app is offline-only and device-local. Do not add features requiring permissions not essential to core functionality (feedings, sleep, diapers, health routines). Never add location tracking "because it's convenient."

### Checking permission status

```dart
import 'package:permission_handler/permission_handler.dart';

Future<void> _requestPhotoPermission() async {
  final status = await Permission.photos.status;

  if (status.isDenied) {
    // First time — show rationale, then request
    showPermissionRationaleDialog(context);
  } else if (status.isPermanentlyDenied) {
    // Already denied — redirect to Settings
    openAppSettings();
  } else {
    // Already granted — proceed with feature
    _takePhoto();
  }
}
```

## Data Handling Transparency

### Privacy policy & consent

- mamadera bundles a privacy policy in-app (no separate website needed since there's no server).
- Show a brief consent screen on first launch explaining:
  - What data is collected (only what the user explicitly enters)
  - Where data is stored (on device only)
  - That data is encrypted at rest
  - How to export or delete all data

### In-app data controls

Provide clear, accessible data management options:

```dart
// Settings screen with privacy controls
ListTile(
  leading: Icon(CupertinoIcons.doc_on_clipboard),
  title: Text('Export Data'),
  subtitle: Text('Download your data as encrypted JSON or CSV'),
  onTap: _exportData,
),
ListTile(
  leading: Icon(CupertinoIcons.trash),
  title: Text('Delete All Data'),
  subtitle: Text('Permanently remove all tracking records'),
  onTap: _confirmDeleteAllData,
),
```

### Export formats

- **Encrypted JSON:** For users who want to preserve data securely on another device.
- **Plain CSV:** For users who want to import into spreadsheets or other tools.
- Export should be manual and explicit — never automatic or silent.

## Aligning with App Store Review

- Ensure `Info.plist` includes usage description strings for every permission:
  - `NSCameraUsageDescription`
  - `NSPhotoLibraryUsageDescription`
  - `NSUserNotificationsUsageDescription`
- These strings are shown in the system permission dialog — make them clear and specific to your app's purpose.
