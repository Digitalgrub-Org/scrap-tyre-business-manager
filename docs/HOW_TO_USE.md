# Scrap Tyre Business Manager - How To Use

## What Works Now

The app is an offline-first working Flutter application for Android and iOS.
Data is stored locally on the device using SQLite.

Implemented functions:

- Dashboard totals and charts.
- First-launch onboarding instructions for new testers.
- Visible demo-data banner with an option to clear only sample entries.
- Business profile settings for shop name, contact and address details.
- Purchase entry, editing, deletion, and duplication.
- Sales entry, editing, deletion, duplication, and simple invoice sharing.
- Automatic stock increase from purchases and stock decrease from sales.
- Protection against selling more stock than available.
- Protection against changing a purchase in a way that makes existing sales
  exceed available stock.
- Expense entry, editing, and deletion.
- Daily, weekly, monthly, item-wise, customer-wise, supplier-wise, stock, and
  expense reports.
- PDF and Excel report generation and sharing through the device share sheet.
- Light/dark mode and an English/Tamil UI support structure.

Future-ready items that are not implemented yet:

- Cloud sync with Firebase or Supabase.
- Admin item-management screen for changing the master item list.
- User login, backup/restore, and multi-device access.
- Fully translated Tamil content on every form and report label.

## First Launch And Sample Data

When the app is installed for the first time, it creates its local database
with sample entries and shows a short welcome guide explaining the daily
workflow. After you tap `Start Testing`, the dashboard opens with sample
totals so the screen is not empty.

The sample data includes:

- Purchases of `Car Tyre`, `Nylon Tyre KG`, and `Tube KG`.
- Sales to `Ganesh Recyclers` and `Velan Rubber Works`.
- Expenses for labour and miscellaneous work.

This data can be edited or deleted from the relevant Purchase, Sales, and
Expenses screens. A `DEMO DATA ACTIVE` banner appears at the top of the
dashboard while included sample entries remain. Tap `Clear Demo Data` in that
banner to remove only sample transactions while keeping entries added by you.

## Main Navigation

The bottom navigation bar contains five areas:

| Tab | Purpose |
| --- | --- |
| Dashboard | View today's totals, current stock, charts, and quick-entry buttons. |
| Purchase | Record material bought from suppliers. |
| Sales | Record material sold to customers. |
| Stock | View available inventory and low-stock warnings. |
| Reports | Filter, review, export, and share business reports. |

The `Quick Add` button opens shortcuts for a new purchase, sale, or expense.

At the top right:

- Tap the language button to switch the available English/Tamil label set.
- Tap the moon button to switch light and dark mode.
- Tap the settings button to create or update your shop profile.

## Set Up Your Business Profile

Open the settings button in the top-right corner of the app. Enter:

- Shop or business name.
- Owner name.
- Mobile number.
- Business address.
- GSTIN or registration number, if applicable.

Tap `Save Business Profile`. The saved shop name is then shown in the app
header and used in exported reports and shared sales invoices. The settings
screen also provides a second place to clear remaining demo data.

## Daily Workflow

Use this order during normal business operations:

1. Record each incoming load in `Purchase`.
2. Record each outgoing sale in `Sales`.
3. Record loading, transport, labour, or miscellaneous costs in `Expenses`.
4. Check `Stock` before selling additional material.
5. Open `Reports` at the end of the day to check totals and share a report.

## Add A Purchase

Open the `Purchase` tab and fill in:

| Field | Details |
| --- | --- |
| Date | Defaults to today; tap to choose another date. |
| Supplier Name | Required. |
| Vehicle Number | Required. |
| Item Type | Required; select from the searchable bottom sheet. |
| Quantity | Required; kilogram category items may use `0` if managed by weight. |
| Weight | Required, entered in kilograms. |
| Purchase Rate | Required, entered as rate per kilogram. |
| Payment Type | Select `Cash`, `UPI`, or `Credit`. |
| Notes | Optional. |

The purchase amount is calculated automatically:

```text
Purchase Amount = Weight x Purchase Rate
```

Tap `Save Purchase`. A confirmation message appears and stock immediately
increases for that item.

### Repeat, Edit, Or Delete Purchases

At the bottom of the Purchase tab, open the menu on a recent purchase:

- `Edit` opens the entry for corrections.
- `Duplicate` copies the values into a new entry dated today.
- `Delete` removes the purchase after confirmation.

The app prevents an edit or deletion if it would cause existing sales to exceed
the remaining purchased stock.

## Add A Sale

Open the `Sales` tab and fill in:

| Field | Details |
| --- | --- |
| Date | Defaults to today; tap to choose another date. |
| Customer Name | Required. |
| Item Type | Required; select from the searchable bottom sheet. |
| Quantity | Required; kilogram category items may use `0`. |
| Weight | Required, entered in kilograms. |
| Sales Rate | Required, entered as rate per kilogram. |
| Transport Charges | Enter `0` when there is no charge. |
| Payment Status | Select `Paid`, `Pending`, or `Partial`. |
| Notes | Optional. |

After choosing an item, the form shows the available quantity and weight.

The sale amount is calculated automatically:

```text
Sales Amount = Weight x Sales Rate
```

An estimated margin is displayed before saving, based on the current average
purchase cost and transport charge.

Tap `Save Sale`. A confirmation message appears and stock decreases. If the
entered quantity or weight is greater than available stock, the save is stopped
and an error message explains what is available.

### Share An Invoice Or Repeat A Sale

At the bottom of the Sales tab, open the menu on a recent sale:

- `Share invoice` opens the phone share sheet with a simple invoice message.
- `Edit` opens the sale for corrections.
- `Duplicate` prepares a similar new sale.
- `Delete` removes it after confirmation and restores stock.

## Record Expenses

Open Expenses using either:

- `Quick Add` then `Add Expense`, or
- The receipt icon in the Reports screen.

Choose an expense type:

- `Loading`
- `Transport`
- `Labour`
- `Miscellaneous`

Enter the date, amount, and optional notes, then tap `Save Expense`.
Expense history on the same screen supports editing and deleting.

## Understand Stock

Open the `Stock` tab to see inventory automatically calculated from purchases
and sales.

Each stock card displays:

- Item name and category.
- Available quantity.
- Available weight.
- Average purchase rate.
- Total current stock value.
- Low-stock warning where the item is at or below its threshold.

Use the search box to find an item, the category dropdown to filter groups, and
the `Low stock` chip to focus on items needing attention.

## Dashboard

The Dashboard shows:

- Today's purchase amount.
- Today's sales amount.
- Today's net profit.
- Current stock weight.
- Total purchased and sold weight.
- Pending payment estimate.
- Seven-day daily purchase versus sales chart.
- Seven-day net profit trend.
- Highest available stock items.

The dashboard is populated from the stored entries, so saving or editing
transactions changes the numbers automatically.

## Profit Calculation

Amounts use Indian rupee formatting throughout the app.

The report calculations use:

```text
Gross Profit = Total Sales - Total Purchase
Expenses = Entered Expenses + Sales Transport Charges
Net Profit = Total Sales - Total Purchase - Expenses
```

For payment status:

- `Pending` sales are counted fully in pending payments.
- `Partial` sales are represented as half pending in the dashboard estimate.
- `Paid` sales do not add to pending payments.

## Reports And Exports

Open the `Reports` tab and select:

- Daily Report
- Weekly Report
- Monthly Report
- Item-wise Profit
- Customer-wise Sales
- Supplier-wise Purchases
- Stock Report
- Expense Report

You can also:

- Tap the date range field to choose custom start and end dates.
- Search by item, customer, or supplier.
- Review total purchases, sales, expenses, and net profit for the period.

Export actions:

| Button | Result |
| --- | --- |
| PDF | Creates a PDF report and opens the share sheet. |
| Excel | Creates an `.xlsx` report and opens the share sheet. |
| Share | Creates a PDF report and opens the share sheet for WhatsApp, email, or other installed apps. |

## Data And Offline Use

- Entries are stored only on the current phone or emulator.
- The app works without an internet connection after installation.
- Uninstalling the app clears its locally stored database on that device.
- Cloud synchronization is intentionally reserved for a later release.

## Run The App During Development

From the project folder:

```powershell
flutter devices
flutter run
```

To launch an Android emulator first:

```powershell
flutter emulators
flutter emulators --launch <emulator_id>
flutter run
```

## Troubleshooting

| Problem | What To Check |
| --- | --- |
| Sale cannot be saved | Check the available stock shown after selecting the item. Add a purchase first or reduce the sale quantity/weight. |
| Purchase edit/delete is blocked | Existing sales already depend on that purchased stock. Adjust those sales before reducing or deleting the purchase. |
| Dashboard has old totals | Complete the save operation; totals refresh after each successful edit, add, or delete. |
| Share destination is missing | Install or configure WhatsApp/email on the emulator or physical phone. |
| Need to remove sample totals | Tap `Clear Demo Data` in the dashboard banner or in Business Settings. |
| Need a fully reset test database | Uninstall and reinstall the development app; the welcome guide and sample data return. |
