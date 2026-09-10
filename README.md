# Gwinn Painting Solutions — Paint Estimate Calculator

Premium, responsive estimate calculator built with Flutter for interior walls and exterior work (decks, siding, fences).

## Features

- **Interior / Exterior toggle** at the top of the calculator
- Live invoice-style estimate summary
- Interior: wall area, labor rate, material cost, coats, optional door/window deductions, color log
- Exterior: type the job name, enter square footage, choose **paint or stain**, add more surfaces
- Download PDF or send the estimate from the phone
- Saved estimates stored locally

## Run

```bash
flutter pub get
flutter run
```

Web:

```bash
flutter run -d web-server --web-port 43123 --web-hostname 127.0.0.1
```

## Interior math

- **Net Sq Ft** = Total Sq Ft − (Doors × 20) − (Windows × 15)
- **Raw Gallons** = (Net Sq Ft × Coats) ÷ 350
- **Total Gallons** = ceil(Raw Gallons)
- **Material Cost** = Total Gallons × Price per Gallon (default $45)
- **Labor Cost** = Net Sq Ft × Price per Sq Ft
- **Total Estimate** = Material Cost + Labor Cost

## Exterior math

- **Paint gallons** = ceil((Sq Ft × Coats) ÷ 350)
- **Stain gallons** = ceil((Sq Ft × Coats) ÷ 200) — tighter coverage for decks and raw wood
- **Material** uses the paint or stain gallon price for that surface
- **Labor** = Sq Ft × labor rate
- Multiple surfaces (deck + siding + fence) add into one estimate
