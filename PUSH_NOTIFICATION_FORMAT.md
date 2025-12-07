# Push Notification Image Display Fix

## Problem
Push notifications show images when **app is open**, but only show text when **app is closed/terminated**.

## Root Cause
When FCM sends a message with a `notification` object, Android displays it automatically without running Flutter's background handler. This prevents our custom image download logic from executing.

## Solution
Backend must send **DATA-ONLY messages** (no `notification` object). This ensures Flutter's background handler processes the notification and downloads the image in all app states.

### ✅ CORRECT FCM Message Format (Data-Only)

```json
{
  "data": {
    "title": "Your notification title",
    "body": "Your notification body",
    "image": "https://example.com/path/to/image.jpg",
    "type": "push_notification"
  }
}
```

### Why This Works

1. **No `notification` object**: Android doesn't auto-display, giving Flutter full control
2. **App Open/Foreground**: Flutter's foreground handler downloads image and shows notification ✅
3. **App Closed/Background/Terminated**: Flutter's background handler downloads image and shows notification ✅
4. **Custom display**: Flutter controls notification appearance with BigPictureStyle in all states ✅

### ❌ INCORRECT Format (Will Not Show Images When App Closed)

```json
{
  "notification": {
    "title": "Title",
    "body": "Body"
  },
  "data": {
    "image": "https://example.com/image.jpg"
  }
}
```

When `notification` object exists, Android bypasses Flutter's background handler.

### Django FCM Implementation (Correct)

```python
from firebase_admin import messaging

def send_push_notification_with_image(token, title, body, image_url):
    """
    Send data-only FCM message for custom notification handling.
    Flutter will download image and display notification in all app states.
    """
    message = messaging.Message(
        # NO notification object - this is key!
        data={
            'title': title,
            'body': body,
            'image': image_url,
            'type': 'push_notification',
        },
        # Android config for priority and TTL
        android=messaging.AndroidConfig(
            priority='high',  # Ensures delivery when app is closed
            ttl=3600,  # Time to live in seconds
        ),
        token=token,
    )
    
    response = messaging.send(message)
    return response
```

### Important Backend Configuration

1. **Remove `notification` object completely** - let Flutter handle display
2. **Set `priority: 'high'`** - ensures message wakes app when closed
3. **Include all data in `data` payload**: title, body, image, type
4. **Image URL must be publicly accessible** - no authentication required

### Image Requirements

- **Format**: JPG, PNG, WebP
- **Aspect Ratio**: 2:1 recommended (e.g., 1024x512)
- **File Size**: < 1MB for faster download
- **Accessibility**: Public URL, no auth headers needed
- **HTTPS**: Required for security

## Testing Checklist

Test all three app states with **data-only messages**:

- [ ] **Foreground (app open)**: Image displays with custom BigPicture style ✅
- [ ] **Background (app minimized)**: Image displays via background handler ✅
- [ ] **Terminated (app force-closed)**: Image displays via background handler ✅

### Testing Commands

```bash
# Test from Firebase Console: 
# 1. Go to Firebase Console > Cloud Messaging
# 2. Click "Send your first message"
# 3. In "Additional options" > "Custom data", add:
#    - title: "Test Title"
#    - body: "Test Body"
#    - image: "https://picsum.photos/1024/512"
#    - type: "push_notification"
# 4. Leave "Notification" fields EMPTY
# 5. Send to device token

# Test with curl (replace TOKEN and SERVER_KEY):
curl -X POST "https://fcm.googleapis.com/fcm/send" \
  -H "Authorization: key=YOUR_SERVER_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "to": "DEVICE_FCM_TOKEN",
    "priority": "high",
    "data": {
      "title": "Test Notification",
      "body": "This is a test with image",
      "image": "https://picsum.photos/1024/512",
      "type": "push_notification"
    }
  }'
```

## Flutter Implementation Details

The Flutter app now handles notifications in both states:

1. **Foreground Handler** (`lib/service/notification_service.dart`):
   - Downloads image from `data['image']`
   - Shows local notification with BigPictureStyle

2. **Background Handler** (`lib/main.dart` - `_firebaseMessagingBackgroundHandler`):
   - Runs when app is closed/background
   - Downloads image from `data['image']`
   - Shows local notification with BigPictureStyle
   - Same logic as foreground for consistency

Both handlers use the same image download and display logic, ensuring consistent behavior across all app states.

## Troubleshooting

### Images Still Not Showing When App Closed?

1. **Check message format**: Ensure NO `notification` object in FCM payload
2. **Check priority**: Must be `priority: 'high'` for background delivery
3. **Check image URL**: Must be publicly accessible, HTTPS, < 1MB
4. **Check logs**: Use `adb logcat | grep flutter` to see background handler logs
5. **Check permissions**: Ensure notification permission granted on Android 13+

### Common Mistakes

❌ Sending `notification` object - Android shows it automatically, bypassing Flutter  
❌ Low priority - message may not wake app when closed  
❌ Private image URLs - download will fail  
❌ Large images - download timeout after 10 seconds  

## References

- [FCM Data Messages](https://firebase.google.com/docs/cloud-messaging/concept-options#data_messages)
- [Flutter Local Notifications](https://pub.dev/packages/flutter_local_notifications)
- [Firebase Messaging Background Handler](https://firebase.flutter.dev/docs/messaging/usage/#background-messages)
