-- Database Export: E-Ticketing Helpdesk
-- Platform: Supabase Cloud (PostgreSQL)
-- Date: 2026-07-07

-- -----------------------------------------------------
-- 1. Table structure for table `users`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS users (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  email TEXT UNIQUE NOT NULL,
  password TEXT NOT NULL,
  role TEXT NOT NULL,
  is_active BOOLEAN DEFAULT TRUE
);

-- -----------------------------------------------------
-- 2. Table structure for table `tickets`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS tickets (
  id TEXT PRIMARY KEY,
  title TEXT NOT NULL,
  description TEXT NOT NULL,
  category TEXT NOT NULL,
  priority TEXT NOT NULL,
  status TEXT NOT NULL,
  created_by TEXT NOT NULL,
  assigned_to TEXT,
  attachment_name TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL
);

-- -----------------------------------------------------
-- 3. Table structure for table `comments`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS comments (
  id TEXT PRIMARY KEY,
  ticket_id TEXT REFERENCES tickets(id) ON DELETE CASCADE NOT NULL,
  user_name TEXT NOT NULL,
  user_role TEXT NOT NULL,
  content TEXT NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL
);

-- -----------------------------------------------------
-- 4. Table structure for table `history_logs`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS history_logs (
  id TEXT PRIMARY KEY,
  ticket_id TEXT REFERENCES tickets(id) ON DELETE CASCADE NOT NULL,
  action TEXT NOT NULL,
  performed_by TEXT NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL
);

-- -----------------------------------------------------
-- 5. Table structure for table `notifications`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS notifications (
  id TEXT PRIMARY KEY,
  ticket_id TEXT NOT NULL,
  title TEXT NOT NULL,
  description TEXT NOT NULL,
  is_read BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL
);

-- -----------------------------------------------------
-- Dumping data for table `users`
-- -----------------------------------------------------
INSERT INTO users (id, name, email, password, role, is_active) VALUES
  ('U-1', 'Alfin', 'user@example.com', 'user123', 'User', TRUE),
  ('U-2', 'Budi Helpdesk', 'helpdesk@example.com', 'helpdesk123', 'Helpdesk', TRUE),
  ('U-3', 'Joni Admin', 'admin@example.com', 'admin123', 'Admin', TRUE)
ON CONFLICT (id) DO NOTHING;

-- -----------------------------------------------------
-- Dumping data for table `tickets` (Mockup seed data)
-- -----------------------------------------------------
INSERT INTO tickets (id, title, description, category, priority, status, created_by, assigned_to, attachment_name, created_at, updated_at) VALUES
  ('T-001', 'Komputer tidak bisa menyala', 'Komputer di ruang staff mati total setelah pemadaman listrik kemarin.', 'Hardware', 'High', 'In Progress', 'Alfin', 'Budi Helpdesk', NULL, TIMEZONE('utc'::text, NOW() - INTERVAL '3 days'), TIMEZONE('utc'::text, NOW() - INTERVAL '2 days')),
  ('T-002', 'Tidak bisa akses email kantor', 'Saat mencoba login ke Outlook muncul pesan kesalahan autentikasi terus menerus.', 'Software', 'Medium', 'Open', 'Alfin', NULL, NULL, TIMEZONE('utc'::text, NOW() - INTERVAL '1 days'), TIMEZONE('utc'::text, NOW() - INTERVAL '1 days')),
  ('T-003', 'Printer lantai 2 error', 'Muncul tulisan paper jam pada layar printer lantai 2 sebelah kanan.', 'Hardware', 'Low', 'Resolved', 'Alfin', 'Budi Helpdesk', NULL, TIMEZONE('utc'::text, NOW() - INTERVAL '10 days'), TIMEZONE('utc'::text, NOW() - INTERVAL '9 days'))
ON CONFLICT (id) DO NOTHING;

-- -----------------------------------------------------
-- Dumping data for table `comments` (Mockup seed data)
-- -----------------------------------------------------
INSERT INTO comments (id, ticket_id, user_name, user_role, content, created_at) VALUES
  ('C-1', 'T-001', 'Alfin', 'User', 'Komputer mati total, lampu indikator power juga mati.', TIMEZONE('utc'::text, NOW() - INTERVAL '3 days')),
  ('C-2', 'T-001', 'Budi Helpdesk', 'Helpdesk', 'Baik, saya akan membawa power supply cadangan ke lokasi.', TIMEZONE('utc'::text, NOW() - INTERVAL '2 days'))
ON CONFLICT (id) DO NOTHING;

-- -----------------------------------------------------
-- Dumping data for table `history_logs` (Mockup seed data)
-- -----------------------------------------------------
INSERT INTO history_logs (id, ticket_id, action, performed_by, created_at) VALUES
  ('H-1', 'T-001', 'Tiket dibuat', 'Alfin', TIMEZONE('utc'::text, NOW() - INTERVAL '3 days')),
  ('H-2', 'T-001', 'Tiket ditugaskan ke Budi Helpdesk', 'System', TIMEZONE('utc'::text, NOW() - INTERVAL '3 days')),
  ('H-3', 'T-001', 'Status diubah ke In Progress', 'Budi Helpdesk', TIMEZONE('utc'::text, NOW() - INTERVAL '2 days'))
ON CONFLICT (id) DO NOTHING;
