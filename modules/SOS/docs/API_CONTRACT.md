# API Contract — SOS Emergency Safety Equipment Platform

> **Single source of truth for all API endpoints.**
> Update this file every time an endpoint is added, changed, or removed.
> Reference: [PROJECT_LOG.md](./PROJECT_LOG.md)

---

## Document Info

| Item | Detail |
| :--- | :--- |
| **Project** | SOS — Emergency Safety Equipment Monitoring Platform |
| **Version** | v3.2 |
| **Last Updated** | 2026-05-19 |
| **Base URL (production)** | `https://ehs.garrev.com/app1/v1` |
| **Base URL (LAN)** | `http://192.168.1.199/app1/v1` |
| **Auth** | Bearer token — DB-backed JWT sessions (90-day rolling refresh) |
| **Data Format** | JSON (`application/json`) |
| **Date Format** | ISO 8601 — `YYYY-MM-DD` for dates, `YYYY-MM-DDTHH:mm:ss.sssZ` for timestamps |

> **Important:** The `/api/*` prefix has been permanently removed. Only `/app1/v1/*` is active.

---

## Environments

| Environment | Base URL |
| :--- | :--- |
| **Production (HTTPS)** | `https://ehs.garrev.com/app1/v1` |
| **LAN direct** | `http://192.168.1.199/app1/v1` |
| **Dashboard (React)** | `https://pro.garrev.com` |
| **SafeHydra** | `https://sh.garrev.com` |

---

## Global Response Codes

| HTTP Code | Meaning |
| :--- | :--- |
| **200** | Success / OK |
| **201** | Created |
| **400** | Bad Request / Parameter Mismatch |
| **401** | Unauthorized / Expired Session |
| **403** | Forbidden / Role Insufficient |
| **404** | Not Found |
| **500** | Internal Server Error |

---

## Change Log

### v3.2 (2026-05-19)
- **Status Counts Alignment**: Aligned all `total` calculations in all 27 module dashboard and plant health views (including the custom main/secondary Fire Extinguisher dashboards) to dynamically sum the status categories (Active + Needs Service + Expired + Upcoming + Due Inspection), matching database totals.
- **Combined Inspection Metric**: Combined `upcoming` and `due_inspection` counts into the single `INSPECT` metric on `planthealth.dart` to sync with the database and solve the device count mismatches.
- **Admin Role Sync Support**: Added the `admin` role to the background `SyncRegistry` sync permissions, enabling seamless data population for both `admin` and `superadmin` accounts.
- **Direct Health Navigation**: Added a premium, green "HEALTH" navigation shortcut directly to the top-right `AppBar` of all module-wide `GenericAnalyticsPage`s as well as the custom root `AnalyticsPage` for the Fire Extinguisher dashboard, routing users straight to the respective plant health metric dashboard.
- **Rebranding Integration**: Completed integration of the circular ELTRIVE company logo and transparent 3D SCBA units asset.

### v3.1 (2026-05-09)
- **Base URL Migration**: Permanently removed `/api/*` prefix; transitioned all client network requests to `/app1/v1/*`.
