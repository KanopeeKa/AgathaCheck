# Agatha Track — Internal GDPR Compliance Document

## 1. Data Controller

| Field | Value |
|-------|-------|
| **Organisation Name** | [COMPANY_NAME — TO BE COMPLETED] |
| **Registered Address** | [ADDRESS — TO BE COMPLETED] |
| **Country** | [COUNTRY — TO BE COMPLETED] |
| **Registration Number** | [REG_NUMBER — TO BE COMPLETED] |
| **Contact Email** | [CONTACT_EMAIL — TO BE COMPLETED] |

## 2. Data Protection Officer (DPO)

| Field | Value |
|-------|-------|
| **DPO Name** | [DPO_NAME — TO BE COMPLETED] |
| **DPO Email** | [DPO_EMAIL — TO BE COMPLETED] |
| **DPO Phone** | [DPO_PHONE — TO BE COMPLETED] |
| **DPO Address** | [DPO_ADDRESS — TO BE COMPLETED] |

> **Note:** Under Art. 37 GDPR, a DPO appointment is mandatory if the organisation carries out large-scale processing of special categories of data. Pet health data is not classified as special category data (Art. 9), but appointing a DPO is recommended as a best practice.

---

## 3. Data Hosting Location

| Aspect | Detail |
|--------|--------|
| **Primary Database** | PostgreSQL (hosted via configured `DATABASE_URL`) |
| **Recommended Hosting Region** | EU (European Union) — to minimise cross-border transfer obligations |
| **Current Hosting** | Configurable — determined by deployment environment |
| **File Storage** | Server filesystem (`/uploads/` directory), co-located with application server |
| **Backup Location** | [TO BE CONFIGURED — should match primary hosting region] |

### 3.1 Hosting Recommendations
- Deploy database and application server within EU/EEA jurisdiction
- Use a hosting provider with ISO 27001 or SOC 2 certification
- Ensure the hosting provider offers a GDPR-compliant Data Processing Agreement (DPA)
- If using Neon.tech for PostgreSQL, select an EU region (e.g., `eu-central-1`)

---

## 4. Data Processing Purposes

### 4.1 Processing Activities Register (Art. 30 GDPR)

| # | Processing Activity | Purpose | Legal Basis | Data Categories | Data Subjects |
|---|---------------------|---------|-------------|-----------------|---------------|
| 1 | Account Registration | User authentication and service access | Art. 6(1)(b) — Contractual necessity | Email, name, password hash | App users |
| 2 | User Profile Management | Personalisation of user experience | Art. 6(1)(b) — Contractual necessity | First/last name, bio, photo, category, locale | App users |
| 3 | Pet Profile Management | Core service — pet record keeping | Art. 6(1)(b) — Contractual necessity | Pet name, species, breed, DOB, chip ID, insurance, photo | App users |
| 4 | Health Tracking | Core service — pet health management | Art. 6(1)(b) — Contractual necessity | Health entries, medications, vet visits, procedures, photos | App users |
| 5 | Weight Tracking | Core service — pet weight monitoring | Art. 6(1)(b) — Contractual necessity | Weight measurements, dates, notes | App users |
| 6 | Veterinarian Management | Core service — vet contact management | Art. 6(1)(b) — Contractual necessity | Vet name, clinic, phone, email, address | App users |
| 7 | In-App Notifications | Service delivery — reminders and alerts | Art. 6(1)(b) — Contractual necessity | Notification content, read status | App users |
| 8 | Pet Sharing | Collaborative pet management | Art. 6(1)(b) — Contractual necessity | Share codes, access roles, user associations | App users |
| 9 | Organisation Management | Multi-user pet management for professional/charity orgs | Art. 6(1)(b) — Contractual necessity | Org details, membership, roles, invitations | App users, org members |
| 10 | Subscription Management | Payment and entitlement processing | Art. 6(1)(b) — Contractual necessity | App user ID, purchase status (via RevenueCat) | Paying users |
| 11 | PDF Report Generation | User-requested data export | Art. 6(1)(b) — Contractual necessity | All pet-related data compiled into PDF | App users |
| 12 | Password Reset | Account recovery | Art. 6(1)(b) — Contractual necessity | Email, reset code | App users |
| 13 | Local Data Caching | Offline access and performance | Art. 6(1)(f) — Legitimate interest | Pet data cache, locale preference | App users |

---

## 5. Retention Rules

### 5.1 Retention Schedule by Data Category

| Data Category | Retention Period | Deletion Trigger | Notes |
|---------------|-----------------|------------------|-------|
| **Account Data** (email, name, password hash) | Duration of account + 30 days grace period | User-initiated account deletion | Password hash is bcrypt; irreversible |
| **User Profile** (bio, photo, names, category) | Duration of account | User-initiated account deletion or profile update | Photos deleted from filesystem on removal |
| **Pet Profiles** | Duration of account or until pet deletion | User deletes pet or account | Cascading deletion of all associated records |
| **Health Entries** | Duration of associated pet record | Pet deletion or individual entry deletion | Includes linked photos |
| **Health Issues** | Duration of associated pet record | Pet deletion or individual issue deletion | Linked events via junction table |
| **Health Event Photos** | Duration of associated health entry | Entry deletion or individual photo removal | Physical files deleted from `/uploads/` |
| **Weight Entries** | Duration of associated pet record | Pet deletion or individual entry deletion | — |
| **Veterinarian Contacts** | Duration of account | User deletes vet or account | Vet-pet associations cleared on vet deletion |
| **Notifications** | 90 days after creation or until read/dismissed | Automatic expiry or account deletion | Read notifications may be retained for audit |
| **Refresh Tokens** | 30 days from creation | Token expiry or user logout | Expired tokens should be periodically purged |
| **Password Reset Tokens** | 1 hour from creation | Token use or expiry | Marked as `used` after consumption |
| **Share Codes / Pet Access** | Duration of sharing relationship | Access revoked by owner or account deletion | — |
| **Organisation Data** | Duration of organisation existence | Organisation deleted by admin | Cascading deletion of memberships |
| **Organisation Memberships** | Duration of membership | Member leaves or is removed | Invite records removed on decline/expiry |
| **Archived Pets** | Indefinite (archive purpose) | Manual deletion by organisation admin | Contains snapshot data at time of transfer |
| **Family Events** | Duration of associated pet record | Pet deletion or individual event deletion | — |
| **Subscription Data** (RevenueCat) | Per RevenueCat retention policy | Account deletion triggers RevenueCat user deletion request | See RevenueCat DPA |
| **Local Preferences** (SharedPreferences) | Until app uninstall or manual clear | User clears app data | Device-local, not server-controlled |

### 5.2 Automated Retention Enforcement
- **Refresh tokens**: Expired tokens should be purged via scheduled task (recommended: daily)
- **Password reset tokens**: Expired/used tokens should be purged (recommended: daily)
- **Notifications**: Old read notifications should be purged after 90 days (recommended: weekly task)
- **Account deletion**: CASCADE constraints ensure all related data is deleted with the user record

---

## 6. Data Subject Rights (Art. 15–22 GDPR)

| Right | Implementation Status | Mechanism |
|-------|----------------------|-----------|
| **Right of Access** (Art. 15) | Planned | Data export endpoint (`GET /api/auth/me/export`) |
| **Right to Rectification** (Art. 16) | Implemented | Profile edit (`PUT /api/auth/me`), pet/health/vet edit endpoints |
| **Right to Erasure** (Art. 17) | Planned | Account deletion endpoint (`DELETE /api/auth/me`) with cascade |
| **Right to Restriction** (Art. 18) | Partial | Users can mute notifications per pet, hide shared pets |
| **Right to Data Portability** (Art. 20) | Planned | JSON export endpoint + PDF report generation |
| **Right to Object** (Art. 21) | Partial | Notification preferences, consent management |
| **Right to Withdraw Consent** (Art. 7(3)) | Planned | Consent banner with re-accessible preferences |

---

## 7. Sub-Processors

### 7.1 Current Sub-Processors

| Sub-Processor | Service | Data Processed | Location | DPA Status |
|---------------|---------|---------------|----------|------------|
| **RevenueCat, Inc.** | Subscription & entitlement management | Anonymous app user ID, purchase transactions | US (with EU data processing options) | DPA available on request |
| **Hosting Provider** | Application & database hosting | All server-side data | [TO BE COMPLETED — EU recommended] | [DPA TO BE OBTAINED] |
| **Domain/DNS Provider** | DNS resolution, TLS certificates | IP addresses (transient) | [TO BE COMPLETED] | [DPA TO BE OBTAINED] |

### 7.2 Sub-Processor Assessment Criteria
Before engaging any new sub-processor, the following must be verified:
1. GDPR-compliant Data Processing Agreement (Art. 28) is available and signed
2. Adequate security measures are in place (encryption at rest and in transit)
3. Data hosting location is within EU/EEA, or adequate safeguards exist (SCCs, adequacy decision)
4. Sub-processor has a published privacy policy
5. Sub-processor provides data deletion/export capabilities

### 7.3 Sub-Processor Change Notification
Data subjects will be informed of any new sub-processors via updated Privacy Policy. A 30-day notice period is recommended before engaging a new sub-processor.

---

## 8. Security Measures

### 8.1 Technical Measures

| Measure | Implementation |
|---------|---------------|
| **Password Hashing** | bcrypt via `dbcrypt` package (adaptive cost factor) |
| **Authentication** | JWT with short-lived access tokens (30 min) and refresh tokens (30 days) |
| **Transport Encryption** | HTTPS/TLS for all API communication |
| **Database Security** | SSL/TLS for database connections (enforced for cloud databases) |
| **SQL Injection Prevention** | Parameterised queries via `postgres` package |
| **CORS** | Configured Access-Control headers |
| **Input Validation** | Server-side validation of all user inputs |
| **File Upload Security** | Files stored outside web root with generated filenames |

### 8.2 Organisational Measures

| Measure | Status |
|---------|--------|
| **Access Control** | Role-based access within organisations (admin, super_user, member) |
| **Data Minimisation** | Only necessary data fields are collected |
| **Purpose Limitation** | Data used only for stated purposes |
| **Regular Security Reviews** | [TO BE SCHEDULED] |
| **Incident Response Plan** | [TO BE DOCUMENTED] |
| **Staff Training** | [TO BE COMPLETED] |

---

## 9. International Transfers

### 9.1 Current Transfer Assessment

| Transfer | Safeguard | Status |
|----------|-----------|--------|
| User data → RevenueCat (US) | Standard Contractual Clauses (SCCs) + DPA | Active |
| All other data | Stored within deployment region | No cross-border transfer if hosted in EU |

### 9.2 Recommendations
- Host all infrastructure within EU/EEA to avoid cross-border transfer obligations
- If US hosting is necessary, ensure SCCs or EU-US Data Privacy Framework certification is in place
- Maintain a transfer impact assessment (TIA) for each non-EU sub-processor

---

## 10. Data Protection Impact Assessment (DPIA)

### 10.1 DPIA Requirement Assessment

Under Art. 35 GDPR, a DPIA is required when processing is likely to result in high risk to data subjects. Assessment:

| Criterion | Applicable? | Notes |
|-----------|------------|-------|
| Systematic monitoring | No | No behavioural tracking or profiling |
| Large-scale processing of special categories | No | Pet health data is not special category data |
| Automated decision-making with legal effects | No | No automated decisions |
| Large-scale processing of personal data | Potential | Depends on user base size |
| Innovative technology | No | Standard web/mobile stack |

**Conclusion:** A DPIA is not currently mandatory but is recommended as best practice if the user base exceeds 10,000 users or if analytics/profiling features are added in the future.

---

## 11. Breach Notification (Art. 33–34 GDPR)

### 11.1 Notification Obligations

| Obligation | Timeframe | Contact |
|------------|-----------|---------|
| Supervisory Authority Notification | Within 72 hours of awareness | [SUPERVISORY_AUTHORITY — TO BE COMPLETED] |
| Data Subject Notification | Without undue delay (if high risk) | Via registered email addresses |

### 11.2 Breach Response Procedure
1. **Detect**: Identify the breach scope and affected data
2. **Contain**: Isolate affected systems, revoke compromised tokens
3. **Assess**: Determine risk level to data subjects
4. **Notify**: Supervisory authority (72h) and data subjects (if high risk)
5. **Remediate**: Fix vulnerability, restore data integrity
6. **Document**: Record breach details, impact, and response actions

---

## 12. Children's Data (Art. 8 GDPR)

The application does not specifically target children. However:
- No age verification is currently implemented at signup
- If users under 16 (or applicable national age) use the service, parental consent is required
- **Recommendation:** Add age confirmation at registration or implement parental consent flow if the user base includes minors

---

## 13. Cookies and Local Storage

| Technology | Type | Purpose | Consent Required |
|------------|------|---------|-----------------|
| SharedPreferences | Local storage | Functional (pet data cache, locale, auth state) | No (strictly necessary) |
| SharedPreferences | Local storage | Consent preferences | No (strictly necessary) |
| JWT Tokens | In-memory | Authentication | No (strictly necessary) |
| No cookies | — | The application does not use browser cookies | — |

---

## Document Control

| Field | Value |
|-------|-------|
| **Document Version** | 1.0 |
| **Created** | [DATE] |
| **Last Updated** | [DATE] |
| **Next Review** | [DATE + 12 months] |
| **Owner** | [DPO_NAME] |
| **Classification** | Internal — Confidential |
