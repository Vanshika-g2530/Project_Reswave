import logging
from typing import Any, Dict, List, Optional

from ..core.memory_db import db, utc_now_iso

logger = logging.getLogger(__name__)


class FCMNotificationService:
    @staticmethod
    def _records_for_user(user_id: str) -> List[Dict[str, Any]]:
        stored = db.fcmTokens.get(user_id, {})
        if not isinstance(stored, dict):
            return []

        records = stored.get("tokens")
        if isinstance(records, list):
            return [
                record
                for record in records
                if isinstance(record, dict)
                and isinstance(record.get("token"), str)
                and record["token"]
            ]

        legacy_token = stored.get("token")
        if isinstance(legacy_token, str) and legacy_token:
            return [{
                "token": legacy_token,
                "deviceInfo": stored.get("deviceInfo"),
                "updatedAt": stored.get("updatedAt"),
            }]
        return []

    @staticmethod
    def register_device_token(
        user_id: str,
        token: str,
        device_info: Optional[str] = None,
    ) -> int:
        normalized_token = token.strip()
        if not normalized_token:
            raise ValueError("FCM_TOKEN_REQUIRED")

        now = utc_now_iso()
        with db._lock:
            for existing_user_id in list(db.fcmTokens):
                records = FCMNotificationService._records_for_user(existing_user_id)
                if existing_user_id != user_id:
                    records = [
                        record for record in records
                        if record["token"] != normalized_token
                    ]
                    if records:
                        db.fcmTokens[existing_user_id] = {
                            "userId": existing_user_id,
                            "tokens": records,
                        }
                    else:
                        db.fcmTokens.pop(existing_user_id, None)
                    continue

                records = [
                    record for record in records
                    if record["token"] != normalized_token
                ]
                records.append({
                    "token": normalized_token,
                    "deviceInfo": device_info,
                    "updatedAt": now,
                })
                db.fcmTokens[user_id] = {
                    "userId": user_id,
                    "tokens": records,
                }

            if user_id not in db.fcmTokens:
                db.fcmTokens[user_id] = {
                    "userId": user_id,
                    "tokens": [{
                        "token": normalized_token,
                        "deviceInfo": device_info,
                        "updatedAt": now,
                    }],
                }

            db.save_to_disk()
            return len(FCMNotificationService._records_for_user(user_id))

    @staticmethod
    def remove_device_token(user_id: str, token: str) -> bool:
        normalized_token = token.strip()
        with db._lock:
            records = FCMNotificationService._records_for_user(user_id)
            remaining = [
                record for record in records
                if record["token"] != normalized_token
            ]
            if len(remaining) == len(records):
                return False

            if remaining:
                db.fcmTokens[user_id] = {
                    "userId": user_id,
                    "tokens": remaining,
                }
            else:
                db.fcmTokens.pop(user_id, None)
            db.save_to_disk()
            return True

    @staticmethod
    def send_to_user(user_id: str, notification: Dict[str, Any]) -> None:
        tokens = [
            record["token"]
            for record in FCMNotificationService._records_for_user(user_id)
        ]
        if not tokens:
            return

        try:
            from firebase_admin import messaging
            from firebase_admin.exceptions import FirebaseError
        except ImportError:
            logger.exception(
                "FCM delivery is unavailable because firebase-admin is not installed"
            )
            return

        from .security import get_firebase_admin_app

        try:
            app = get_firebase_admin_app()
        except RuntimeError as error:
            logger.warning("FCM delivery skipped: %s", error)
            return

        title = str(notification.get("title") or "ResWave")[:150]
        body = str(notification.get("body") or "")[:3000]
        if notification.get("type") == "Message":
            body = "You have a new message."

        data = {
            "notificationId": str(notification.get("id") or ""),
            "type": str(notification.get("type") or "General"),
        }
        for key in ("targetType", "targetId"):
            value = notification.get(key)
            if value is not None:
                data[key] = str(value)

        stale_tokens = []
        for start in range(0, len(tokens), 500):
            token_batch = tokens[start:start + 500]
            message = messaging.MulticastMessage(
                tokens=token_batch,
                notification=messaging.Notification(title=title, body=body),
                data=data,
                android=messaging.AndroidConfig(
                    priority="high",
                    notification=messaging.AndroidNotification(
                        channel_id="reswave_notifications",
                    ),
                ),
            )
            try:
                response = messaging.send_each_for_multicast(message, app=app)
            except FirebaseError:
                logger.exception("FCM send failed for user %s", user_id)
                continue

            for token, send_response in zip(token_batch, response.responses):
                if send_response.success:
                    continue

                error = send_response.exception
                error_code = str(getattr(error, "code", "")).lower()
                if error_code in {
                    "registration-token-not-registered",
                    "invalid-registration-token",
                }:
                    stale_tokens.append(token)
                logger.warning(
                    "FCM delivery failed for user %s (code=%s): %s",
                    user_id,
                    error_code or "unknown",
                    error,
                )

        for token in stale_tokens:
            FCMNotificationService.remove_device_token(user_id, token)
