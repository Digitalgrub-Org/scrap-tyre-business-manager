# App Privacy answers - v1.1 (Firebase)

Fill these into App Store Connect: your app → **App Privacy** → **Edit**. This
replaces the v1.0 "Data Not Collected" declaration, because v1.1 stores data in
the cloud with accounts.

> Do this **only when submitting v1.1**. While v1.0 (offline, no Firebase) is live
> or in review, keep its "Data Not Collected" answer, since that build genuinely
> collects nothing.

## First question
**"Do you or your third-party partners collect data from this app?"** → **Yes**

## Data types to declare
For every type below the answers are the same:
- Linked to the user's identity: **Yes** (data is tied to their account)
- Used for tracking: **No**
- Purpose: **App Functionality** only

| Category | Data type | Why |
|---|---|---|
| Contact Info | **Email Address** | Email and Google sign in accounts |
| Identifiers | **User ID** | Firebase account id (incl. anonymous guest id) |
| User Content | **Other User Content** | Business records: purchases, sales, expenses, stock |
| Contact Info | **Name** and **Phone Number** | Supplier/customer names and phones the user enters |

Everything else (location, financial info as card data, contacts import, browsing
history, search history, usage data, diagnostics, advertising data): **Not collected.**

## Tracking
**"Does this app track users?"** → **No.** (No advertising, no analytics SDK, no
cross-app/website tracking. The app only uses firebase_core, cloud_firestore,
firebase_auth, and google_sign_in.)

## Notes for the reviewer (optional, App Review Information)
- Data is stored per account in Cloud Firestore and is only readable/writable by
  that account (enforced by security rules).
- Guest (anonymous) sign in stores the same business data under an anonymous id.
- No third party receives the data except Google Firebase as the storage/auth
  provider.
