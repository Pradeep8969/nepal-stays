# Invoice Printing Feature

## Installation Instructions

Since npm installation was blocked, you need to install the required dependencies manually:

### Required Dependencies:
1. `react-to-print` - For printing functionality
2. `date-fns` - Already should be installed (for date formatting)

### To install react-to-print:

**Option 1: Using npm (if allowed)**
```bash
npm install react-to-print
```

**Option 2: Using yarn (if available)**
```bash
yarn add react-to-print
```

**Option 3: Manual installation**
1. Download the package from npm registry
2. Add to node_modules folder
3. Update package.json manually

## Features Added:

### 1. Invoice Component (`src/components/Invoice.tsx`)
- Professional invoice layout
- Hotel and customer information
- Booking details with dates and pricing
- Print functionality using react-to-print
- Responsive design
- Nepal Stays branding

### 2. Updated MyBookings Page (`src/pages/MyBookings.tsx`)
- Added "Invoice" button to each booking
- Modal dialog to display invoice
- User profile integration for customer details
- Print functionality

### 3. Logo (`public/logo.svg`)
- Custom SVG logo for invoice branding
- Blue geometric design representing Nepal mountains

## Usage:

1. User goes to "My Bookings" page
2. Clicks "Invoice" button on any booking
3. Invoice modal opens with full booking details
4. Click "Print Invoice" to print or save as PDF
5. Professional invoice includes:
   - Customer information
   - Hotel details and image
   - Booking dates and room type
   - Pricing breakdown
   - Terms and conditions

## Next Steps:

1. Install react-to-print dependency
2. Test the invoice printing functionality
3. Deploy to production
4. Users can now print professional invoices for their hotel bookings
