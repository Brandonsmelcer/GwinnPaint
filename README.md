# paint_estimate_calculator

Premium, responsive Paint Estimate Calculator built with Flutter.

## Features

- Live invoice-style estimate summary
- Base metrics: wall area, labor rate, material cost per gallon, coat count
- Deductions for doors (−20 sq ft) and windows (−15 sq ft)
- Multi-room color log with brand and color code tracking
- Responsive layout: two-column on tablet/web, stacked on mobile

## Run

```bash
cd Projects/paint_estimate_calculator
flutter pub get
flutter run
```

## Math

- **Net Sq Ft** = Total Sq Ft − (Doors × 20) − (Windows × 15)
- **Raw Gallons** = (Net Sq Ft × Coats) ÷ 350
- **Total Gallons** = ceil(Raw Gallons)
- **Material Cost** = Total Gallons × Price per Gallon (default $45)
- **Labor Cost** = Net Sq Ft × Price per Sq Ft
- **Total Estimate** = Material Cost + Labor Cost
