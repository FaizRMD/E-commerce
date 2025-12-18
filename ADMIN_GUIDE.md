# Admin Panel Documentation

## 📱 Halaman Admin yang Telah Dibuat

### 1. **Admin Dashboard** (`admin_dashboard.dart`)
- **Overview Statistics**
  - Total Products
  - Total Orders
  - Total Users
  - Total Revenue
- **Quick Actions**
  - Add New Product
  - View Pending Orders
- **Bottom Navigation** untuk akses cepat ke semua fitur admin
- **Logout** dengan konfirmasi

### 2. **Admin Products** (`admin_products.dart`)
- **List Produk** dengan search
- **Add Product** - Buat produk baru
- **Edit Product** - Update produk
- **Delete Product** - Hapus produk dengan konfirmasi
- **Form lengkap**:
  - Name
  - Price
  - Description
  - Image URL
  - Category
  - Active status
  - Best Seller toggle

### 3. **Admin Orders** (`admin_orders.dart`)
- **List Order** dengan filter status:
  - All
  - Pending
  - Paid
  - Shipped
  - Completed
- **Update Status** order dengan 1 klik
- **Detail Order**:
  - Order ID
  - Date
  - Total amount
  - Payment method
  - Status badge dengan warna

### 4. **Admin Users** (`admin_users.dart`)
- **List Users** dengan search
- **Change Role** (Admin ↔ User)
- **User Info**:
  - Full name
  - Email
  - Role badge
  - Avatar icon berbeda untuk admin

---

## 🎨 Fitur & Animasi

✅ **Animasi Flutter Animate**
- Fade in animations
- Slide animations
- Staggered delays untuk smooth entrance

✅ **Modern UI/UX**
- Card-based design
- Shadow & elevation
- Color-coded status badges
- Responsive layout

✅ **Search & Filter**
- Real-time search di Products & Users
- Filter orders berdasarkan status

✅ **CRUD Operations**
- Create, Read, Update, Delete products
- Update order status
- Change user roles

---

## 🔐 Cara Akses Admin Panel

### 1. Registrasi sebagai Admin
Gunakan halaman `register_admin.dart`:
- Kode admin: `ADMIN2024SECRET`
- Setelah registrasi, role otomatis di-set sebagai 'admin'

### 2. Auto-redirect saat Login
Aplikasi akan otomatis:
- Cek role user di tabel `profiles`
- Jika role = 'admin' → Redirect ke Admin Dashboard
- Jika role = 'user' → Redirect ke Home Screen

### 3. Manual Navigation (untuk testing)
```dart
AppRoutes.pushReplacement(context, AppRoutes.adminDashboard);
```

---

## 🗄️ Database Requirements

Pastikan tabel Supabase memiliki struktur:

### Tabel: `profiles`
```sql
- id (uuid, primary key)
- full_name (text)
- email (text)
- role (text) -- 'admin' atau 'user'
- created_at (timestamp)
```

### Tabel: `products`
```sql
- id (int, primary key)
- name (text)
- price (int)
- description (text)
- image_url (text)
- category_id (int, foreign key)
- is_active (boolean)
- is_best_seller (boolean)
- created_at (timestamp)
```

### Tabel: `orders`
```sql
- id (uuid, primary key)
- user_id (uuid, foreign key)
- total (int)
- status (text) -- 'pending', 'paid', 'shipped', 'completed'
- payment_method (text)
- created_at (timestamp)
```

### Tabel: `categories`
```sql
- id (int, primary key)
- name (text)
```

---

## 🚀 Flow Lengkap

1. **Admin Register** → Masukkan kode admin
2. **Auto Login** → Sistem cek role
3. **Redirect** → Admin Dashboard (jika admin)
4. **Manage**:
   - Products: CRUD operations
   - Orders: Update status
   - Users: Change roles

---

## 🎯 Next Steps (Optional)

Fitur yang bisa ditambahkan:
- [ ] Analytics & Charts (revenue graph)
- [ ] Export data (CSV/Excel)
- [ ] Bulk actions (delete multiple products)
- [ ] Image upload (Supabase Storage)
- [ ] Push notifications ke users
- [ ] Activity logs
- [ ] Dark mode untuk admin panel

---

## 💡 Tips

1. **Testing Admin Panel**:
   - Buat akun dengan kode admin
   - Atau manual update role di Supabase:
     ```sql
     UPDATE profiles SET role = 'admin' WHERE email = 'your@email.com';
     ```

2. **Security**:
   - Kode admin sebaiknya di environment variable (production)
   - Implementasikan Row Level Security (RLS) di Supabase
   - Validasi role di backend

3. **Performance**:
   - Pagination untuk list yang panjang
   - Cache data yang jarang berubah
   - Lazy loading images

---

Halaman admin sudah siap digunakan! 🎉
