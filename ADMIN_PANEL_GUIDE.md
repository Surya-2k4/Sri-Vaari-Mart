# Admin Panel Documentation

## Hidden Admin Panel for Vaari App

### Access Instructions

1. **Hidden Entry Point**: Go to Profile tab → Tap the settings icon (⚙️) **7 times rapidly** (within 2 seconds)
2. **Password**: `vaari@admin2026`

### Features

#### 1. **Product Management**
- View all products with category filtering
- Add new products with:
  - Name, Price, Category
  - Image URL
  - Description and Highlights
- Edit existing products
- Delete products
- Update prices individually

#### 2. **Order Management**
- View all customer orders
- Filter orders by status (Pending, Paid, Processing, Shipped, Delivered, Cancelled)
- View complete order details:
  - Customer information (User ID, Phone, Address)
  - Order items and quantities
  - Payment method and total amount
- Update order status
- Delete orders

### Admin Panel Structure

```
lib/features/admin/
├── model/
│   ├── admin_product_model.dart    # Product model with toMap/fromMap
│   └── admin_order_model.dart      # Order model with user data
├── viewmodel/
│   ├── admin_auth_provider.dart    # Authentication logic
│   ├── admin_product_viewmodel.dart # Product CRUD operations
│   └── admin_order_viewmodel.dart   # Order management operations
└── view/
    ├── admin_login_view.dart        # Password entry screen
    ├── admin_panel_view.dart        # Main admin navigation
    ├── admin_product_management_view.dart # Product management UI
    └── admin_order_management_view.dart   # Order management UI
```

### Security Features

- Password-protected access
- Session persistence using SharedPreferences
- Hidden entry point (no visible menu)
- Logout functionality

### Database Operations

**Products Table:**
- INSERT: Add new products
- UPDATE: Edit product details or prices
- DELETE: Remove products
- SELECT: View all products

**Orders Table:**
- SELECT: View all orders with order_items joined
- UPDATE: Change order status
- DELETE: Remove orders (cascades to order_items)

### Color-Coded Order Status

- 🟠 Pending (Orange)
- 🔵 Paid (Blue)
- 🟣 Processing (Purple)
- 🟢 Delivered (Green)
- 🔴 Cancelled (Red)
- ⚪ Shipped (Teal)

### Usage Tips

1. Use category filter to manage products by type
2. Regularly check pending orders
3. Update order status as you process them
4. Use the refresh button to get latest order data
5. Logout when finished to secure the admin panel

### Important Notes

- Admin authentication persists across app restarts
- Deleting a product doesn't affect past orders
- Deleting an order removes its items automatically
- Price updates are immediate and affect new orders
