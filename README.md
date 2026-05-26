# Scrap Tyre Business Manager

Offline-first Flutter app for day-to-day scrap tyre purchasing, sales,
inventory, expenses, and profit reporting on Android and iOS.

## Included Features

- Material 3 mobile UI with light/dark themes and an English/Tamil UI hook.
- Dashboard cards, sales-versus-purchase chart, profit trend, and stock summary.
- First-launch onboarding guide, demo-data warning/clear action, and saved shop
  profile settings for testers.
- Purchase and sales forms with item selection sheets, date pickers, validation,
  automatic totals, edit/delete, and quick duplicate actions.
- Stock updates from every purchase and sale, with low-stock warnings and
  protection against selling or editing purchases below recorded stock needs.
- Expense ledger for loading, transport, labour, and miscellaneous expenses.
- Daily, weekly, monthly, item, customer, supplier, stock, and expense reports.
- PDF/XLSX exports and platform sharing for reports; simple sales invoice share.
- SQLite persistence with seeded sample data for first launch.

## Calculation Rules

- Purchase total = `weight * purchase rate`.
- Sales total = `weight * sales rate`.
- Gross profit = `sales - purchases`.
- Expenses include entered expenses and transport charges on sales.
- Net profit = `sales - purchases - expenses`.

## Structure

```text
lib/
  constants/   Predefined catalog and static selections
  database/    SQLite schema, seeding, and stock rebuild
  models/      Business data entities
  providers/   UI state and stock validation rules
  screens/     Dashboard, entry, inventory, expenses, and reports
  services/    Repository, calculations, and export generation
  utils/       Theme, localization hook, and formatters
  widgets/     Reusable form and dashboard widgets
```

The database contains `items`, `purchases`, `sales`, `stock`, `expenses`,
`suppliers`, `customers`, and `payments`. This repository boundary can be
extended later with Firebase or Supabase synchronization.

## Run

```bash
flutter pub get
flutter run
```

## User Guide

For sample data details and step-by-step operation instructions, see
[docs/HOW_TO_USE.md](docs/HOW_TO_USE.md).

## Verify

```bash
flutter analyze
flutter test
flutter build apk --debug
```
