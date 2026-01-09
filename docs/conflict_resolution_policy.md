# Offline Sync Conflict Resolution Policy

## Overview
This document defines how the Prevention app handles conflicts when syncing offline data with the server.

---

## 🎯 Conflict Scenarios

### 1. Duplicate Date Conflict

**Scenario**: User creates offline check-in for a date that already exists on server.

**Server Behavior** (in `validate_offline_sync`):
- ❌ **Reject** offline event
- ✅ **Keep** server data
- 📝 **Log** rejection reason: `"Duplicate date"`

**Rationale**: Server data is source of truth. Prevents manipulation by syncing fabricated historical check-ins.

**User Experience**:
```
Sync completed: 4 events accepted, 1 rejected
Reason: Check-in for 2025-01-05 already exists
```

---

### 2. Future Timestamp Conflict

**Scenario**: Offline event has timestamp > current server time (beyond 5-second tolerance).

**Server Behavior**:
- ❌ **Reject** offline event
- 📝 **Log** rejection reason: `"Future timestamp"`
- 🔒 **Flag** as suspicious (potential tampering)

**Tolerance**: 5 seconds (to account for minor clock drift)

**Rationale**: Prevents backdating or clock manipulation to fake check-ins.

---

### 3. Device Fingerprint Mismatch

**Scenario**: Events synced from unknown or blocked device.

**Server Behavior**:
- ❌ **Reject** all events if device is blocked
- ✅ **Register** new device if first-time
- 📝 **Update** last_seen for known device

**User Experience**:
```
Device verification required
Your device is blocked. Contact support.
```

---

### 4. Chronological Order Violation

**Scenario**: Events are out of chronological order (e.g., Jan 10 before Jan 5).

**Server Behavior**:
- ⚠️ **Accept** but log as warning
- 📝 **Log** suspicious pattern for review
- ✅ **No rejection** (user may have been offline for extended period)

**Rationale**: Offline events may arrive out of order legitimately.

---

### 5. Missing Required Fields

**Scenario**: Event missing `date`, `timestamp`, or `mood`.

**Server Behavior**:
- ❌ **Reject** event
- 📝 **Log** reason: `"Missing required fields"`

**Required Fields**:
- `date` (DATE)
- `timestamp` (TIMESTAMPTZ)
- `mood` (`great`, `good`, `okay`, `struggling`)

**Optional Fields**:
- `notes` (TEXT, max 500 chars)

---

### 6. Invalid Mood Value

**Scenario**: Mood value not in allowed enum.

**Server Behavior**:
- ❌ **Reject** event
- 📝 **Log** reason: `"Invalid mood value"`

**Allowed Values**: `great`, `good`, `okay`, `struggling`

---

## 📊 Conflict Priority Matrix

| Conflict Type | Server Wins | Client Wins | Merge | Reject |
|---------------|-------------|-------------|-------|--------|
| Duplicate Date | ✅ | ❌ | ❌ | ✅ |
| Future Timestamp | ✅ | ❌ | ❌ | ✅ |
| Blocked Device | ✅ | ❌ | ❌ | ✅ |
| Out of Order | ✅ | ❌ | ⚠️ | ❌ |
| Missing Fields | - | - | ❌ | ✅ |
| Invalid Mood | - | - | ❌ | ✅ |

**Legend**:
- ✅ = Applied
- ❌ = Not applied
- ⚠️ = Warning logged

---

## 🔄 Sync Flow

```
CLIENT                          SERVER
  |                               |
  |----[Offline Events Queue]---->|
  |                               |
  |                          [validate_offline_sync]
  |                               |
  |                          [Check Device]
  |                               |
  |                          [Validate Each Event]
  |                               |
  |                          - Check duplicates
  |                          - Check timestamps
  |                          - Check fields
  |                          - Check mood values
  |                               |
  |<---[Accepted/Rejected]--------|
  |                               |
  |----[Update Local DB]--------->|
  |                               |
  |<---[Recalculated Streak]------|
```

---

## 🛡️ Security Considerations

### Anti-Tampering

1. **Server Always Wins**: Client cannot override server data
2. **Validation First**: All events validated before touching database
3. **Immutable Logs**: Accepted events cannot be modified
4. **Streak Recalculation**: Always server-side after sync

### Rate Limiting

- **Max Sync Attempts**: 3 per 30 minutes
- **Max Events Per Sync**: 100
- **Cooldown Period**: 30 minutes after limit hit

---

## 📱 User Communication

### Successful Sync
```
✅ Sync completed
3 check-ins synced successfully
Your streak is now 15 days
```

### Partial Success
```
⚠️ Sync completed with warnings
2 check-ins synced, 1 rejected
Rejected: Jan 5 (already exists)
```

### Complete Failure
```
❌ Sync failed
Rate limit exceeded
Try again in 25 minutes
```

### Blocked Device
```
🚫 Device blocked
Your account has been flagged for suspicious activity
Contact support for assistance
```

---

## 🔧 Manual Intervention

### When User Reports Conflict

**Support Steps**:
1. Query `security_events` for user
2. Check `device_fingerprints` for blocked status
3. Review `rate_limits` for abuse patterns
4. If legitimate: Unblock device or manually insert event

**SQL for Support**:
```sql
-- Check security events
SELECT * FROM security_events WHERE user_id = '<user_id>' ORDER BY created_at DESC;

-- Check device status
SELECT * FROM device_fingerprints WHERE user_id = '<user_id>';

-- Unblock device
UPDATE device_fingerprints SET is_blocked = FALSE WHERE user_id = '<user_id>' AND device_id = '<device_id>';

-- Manual event insertion (if legitimate)
INSERT INTO daily_log (user_id, date, mood, notes, completed_checkin)
VALUES ('<user_id>', '2025-01-05', 'good', 'Manually added by support', TRUE);
```

---

## 📝 Logging & Audit

All conflicts are logged to `security_events`:

```json
{
  "event_type": "offline_sync_conflict",
  "data": {
    "rejected_events": 1,
    "reason": "duplicate_date",
    "event_date": "2025-01-05"
  }
}
```

---

## ✅ Policy Summary

1. **Server is source of truth** - Client cannot override
2. **Duplicates rejected** - One check-in per date
3. **Strict timestamp validation** - No future dates, 5s tolerance
4. **Device fingerprinting** - Unknown devices registered, blocked devices rejected
5. **Rate limiting enforced** - 3 syncs per 30 minutes
6. **Comprehensive validation** - All fields checked before insertion
7. **Automatic streak recalculation** - Always server-side post-sync

---

**Status**: This policy ensures data integrity while providing clear feedback to users about sync conflicts.  

---

**Version**: 2.5.0 beta release  
**Last Updated**: January 9, 2026
