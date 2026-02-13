#!/bin/bash
# Database Server Setup Script for PostgreSQL

# Update system packages
yum update -y

# Install PostgreSQL
amazon-linux-extras enable postgresql14
yum install -y postgresql postgresql-server

# Initialize PostgreSQL database
postgresql-setup initdb

# Configure PostgreSQL to accept connections from web servers
# Backup original configuration
cp /var/lib/pgsql/data/postgresql.conf /var/lib/pgsql/data/postgresql.conf.backup
cp /var/lib/pgsql/data/pg_hba.conf /var/lib/pgsql/data/pg_hba.conf.backup

# Configure PostgreSQL to listen on all interfaces
sed -i "s/#listen_addresses = 'localhost'/listen_addresses = '*'/" /var/lib/pgsql/data/postgresql.conf

# Allow connections from the VPC CIDR range (10.0.0.0/16)
cat >> /var/lib/pgsql/data/pg_hba.conf <<EOF

# Allow connections from VPC
host    all             all             10.0.0.0/16             md5
EOF

# Start and enable PostgreSQL
systemctl start postgresql
systemctl enable postgresql

# Wait for PostgreSQL to be ready
sleep 5

# Create database and user
sudo -u postgres psql <<EOF
-- Create a database
CREATE DATABASE techcorp_db;

-- Create a user with password
CREATE USER techcorp_user WITH PASSWORD 'TechCorp2024!DB';

-- Grant privileges
GRANT ALL PRIVILEGES ON DATABASE techcorp_db TO techcorp_user;

-- Create a sample table
\c techcorp_db
CREATE TABLE IF NOT EXISTS users (
    id SERIAL PRIMARY KEY,
    username VARCHAR(50) NOT NULL,
    email VARCHAR(100) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Insert sample data
INSERT INTO users (username, email) VALUES 
    ('admin', 'admin@techcorp.com'),
    ('user1', 'user1@techcorp.com'),
    ('user2', 'user2@techcorp.com');

-- Grant table permissions
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO techcorp_user;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO techcorp_user;
EOF

# Create a user for password authentication (SSH)
useradd -m -s /bin/bash techcorp
echo "techcorp:TechCorp2024!Secure" | chpasswd

# Enable password authentication for SSH
sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config
systemctl restart sshd

# Add techcorp user to sudoers
echo "techcorp ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers.d/techcorp

# Create a connection test script
cat > /home/techcorp/test_db_connection.sh <<'SCRIPT'
#!/bin/bash
echo "Testing PostgreSQL connection..."
psql -h localhost -U techcorp_user -d techcorp_db -c "SELECT * FROM users;"
SCRIPT

chmod +x /home/techcorp/test_db_connection.sh
chown techcorp:techcorp /home/techcorp/test_db_connection.sh

# Create README for database access
cat > /home/techcorp/DATABASE_INFO.txt <<EOF
===========================================
TechCorp Database Server Information
===========================================

PostgreSQL Version: $(psql --version)
Database Name: techcorp_db
Database User: techcorp_user
Database Password: TechCorp2024!DB

Connection from web servers:
psql -h $(hostname -I | awk '{print $1}') -U techcorp_user -d techcorp_db

Connection test:
./test_db_connection.sh

Sample queries:
psql -h localhost -U techcorp_user -d techcorp_db -c "SELECT * FROM users;"

===========================================
EOF

chown techcorp:techcorp /home/techcorp/DATABASE_INFO.txt

# Log completion
echo "Database server setup completed at $(date)" >> /var/log/user-data.log
echo "PostgreSQL is running and configured" >> /var/log/user-data.log
