# Session Security Verification Guide

## Overview
This guide provides step-by-step instructions to verify and configure session security settings in Supabase.

---

## ✅ Verification Checklist

### 1. Access Supabase Auth Settings

1. Go to [Supabase Dashboard](https://app.supabase.com)
2. Select your **Prevention** project
3. Navigate to **Authentication** → **Settings**

---

### 2. Session Timeout Settings

**Location**: Authentication → Settings → **Session Management**

**Recommended Configuration**:
- **JWT Expiry**: `3600` seconds (1 hour)
- **Refresh Token Lifetime**: `2592000` seconds (30 days)
- **Enable Automatic Refresh**: ✅ Enabled

**Why**: Short JWT expiry limits exposure if token is compromised. Refresh tokens allow seamless re-authentication.

**Verification**:
```sql
-- Check current JWT expiry (run in Supabase SQL Editor)
SELECT 
    raw_app_meta_data->>'jwt_exp' as jwt_expiry_seconds
FROM auth.users 
LIMIT 1;
```

---

### 3. Refresh Token Rotation

**Location**: Authentication → Settings → **Security and Protection**

**Recommended Configuration**:
- **Enable Refresh Token Rotation**: ✅ **ENABLED**

**Why**: Each token refresh issues a new refresh token and invalidates the old one, preventing token replay attacks.

**Expected Behavior**:
- Every token refresh generates a new refresh token
- Old refresh token becomes invalid
- Prevents stolen tokens from being reused indefinitely

**Verification**:
- Look for setting: **"Reuse Interval"** or **"Refresh Token Rotation"**
- Should be **enabled** with 0-second reuse interval (strict mode)

---

### 4. Refresh Token Reuse Detection

**Location**: Authentication → Settings → **Security and Protection**

**Recommended Configuration**:
- **Detect Refresh Token Reuse**: ✅ **ENABLED**
- **Action on Detection**: Revoke all sessions

**Why**: If an old (already-rotated) refresh token is used, it indicates potential token theft. All sessions should be revoked immediately.

**Expected Behavior**:
- Attempted reuse of invalidated refresh token → All user sessions terminated
- User must re-authenticate

---

### 5. RLS on Auth Tables

**Location**: Database → Tables → `auth.users` (system table)

**Status**: ✅ **Automatically Secured by Supabase**

RLS on public schema tables is already implemented via our migration.

**Verification**:
```sql
SELECT tablename, rowsecurity 
FROM pg_tables 
WHERE schemaname = 'public' 
  AND tablename IN ('users', 'daily_log', 'relapses', 'security_events');
```

All should return `rowsecurity = TRUE`.

---

### 6. Rate Limiting (Application Level)

**Status**: ✅ **Implemented in SQL Functions**

Our `check_rate_limit()` function handles:
- Check-ins: 5/hour
- Offline sync: 3/30min

**Supabase Built-in Rate Limiting** (optional additional layer):
- Go to **Settings** → **API Settings**
- Check **Rate Limiting** section
- Default: 100 requests/second (usually sufficient)

---

### 7. Email Confirmation

**Location**: Authentication → Settings → **Email Auth**

**Recommended Configuration**:
- **Enable Email Confirmations**: ✅ Enabled (already set)

**Why**: Prevents bots from creating accounts with fake emails.

---

## 📋 Final Verification

Run this SQL to confirm all security measures:

```sql
-- 1. Check RLS enabled
SELECT tablename, rowsecurity 
FROM pg_tables 
WHERE schemaname = 'public';

-- 2. Check security functions exist
SELECT proname 
FROM pg_proc 
WHERE proname IN (
  'log_daily_checkin',
  'recalculate_streak',
  'validate_offline_sync',
  'log_security_event',
  'check_rate_limit'
);

-- 3. Check security events table
SELECT COUNT(*) as total_security_events
FROM security_events;

-- 4. Check rate limits table exists
SELECT COUNT(*) as rate_limit_records
FROM rate_limits;
```

---

## ⚠️ Common Issues

### Issue: JWT Expiry Too Long
**Problem**: JWT valid for > 1 hour  
**Fix**: Set to 3600 seconds in Auth Settings

### Issue: Refresh Token Rotation Disabled
**Problem**: Old tokens still valid after refresh  
**Fix**: Enable "Refresh Token Rotation" in Security settings

### Issue: No Reuse Detection
**Problem**: Stolen tokens can be reused  
**Fix**: Enable "Detect Refresh Token Reuse" → Revoke all sessions

---

## ✅ Security Checklist Summary

- [ ] JWT expiry ≤ 1 hour
- [ ] Refresh token rotation enabled
- [ ] Refresh token reuse detection enabled
- [ ] RLS enabled on all public tables
- [ ] Rate limiting implemented
- [ ] Email confirmation enabled
- [ ] All SQL functions deployed

---

**Status**: Use this checklist to verify Supabase configuration. Items marked with ✅ in "Recommended Configuration" should be enabled.  

---

**Version**: 2.5.0 beta release  
**Last Updated**: January 9, 2026
