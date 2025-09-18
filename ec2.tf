# ----------------------------
# Security Group
# ----------------------------
resource "aws_security_group" "inst" {
  vpc_id = aws_vpc.ALL.id

  ingress {
    from_port   = local.ssh-port
    to_port     = local.ssh-port
    protocol    = local.tcp
    cidr_blocks = [local.anywhere]
  }

  ingress {
    from_port   = local.http-port
    to_port     = local.http-port
    protocol    = local.tcp
    cidr_blocks = [local.anywhere]
  }

  ingress {
    from_port   = local.postgres-port
    to_port     = local.postgres-port
    protocol    = local.tcp
    cidr_blocks = [local.anywhere]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [local.anywhere]
  }

  tags = {
    Name = "inst"
  }
}

# ----------------------------
# AMI lookup: OS → AMI Map (safe filters)
# ----------------------------
data "aws_ami" "selected" {
  most_recent = true
  owners      = [lookup(local.ami_owners, var.os_distribution, "309956199498")]

  filter {
    name   = "name"
    values = lookup(local.ami_filters, var.os_distribution, ["RHEL-8*"])
  }

  filter {
    name   = "architecture"
    values = [var.architecture]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# ----------------------------
# Keypair generation and saving private key locally
# ----------------------------
resource "tls_private_key" "example" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "aws_key_pair" "my_key" {
  key_name   = "Apply"
  public_key = tls_private_key.example.public_key_openssh
}

resource "local_file" "private_key" {
  content         = tls_private_key.example.private_key_pem
  filename        = "/home/ubuntu/Apply.pem"
  file_permission = "0400"
}


# ----------------------------
# Primary DB instances
# ----------------------------
resource "aws_instance" "primary" {
  count                       = var.instance_count
  ami                         = data.aws_ami.selected.id
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.public[0].id
  associate_public_ip_address = true
  key_name                    = aws_key_pair.my_key.key_name
  vpc_security_group_ids      = [aws_security_group.inst.id]

  tags = {
    Name = "postgres-db-${count.index}"
  }

  depends_on = [
    aws_security_group.inst,
  ]

  provisioner "remote-exec" {
    inline = [
      "set -e",
      "echo 'Updating system...'",
      "sudo yum update -y",
      "echo 'Installing PostgreSQL repository...'",
      "sudo dnf install -y https://download.postgresql.org/pub/repos/yum/reporpms/EL-8-x86_64/pgdg-redhat-repo-latest.noarch.rpm",
      "echo 'Disabling default PostgreSQL module...'",
      "sudo dnf -qy module disable postgresql",
      "echo 'Installing ${var.postgres_version}...'",
      "sudo dnf install -y postgresql${var.postgres_version}-server",
      "echo 'Initializing PostgreSQL database...'",
      "sudo /usr/pgsql-${var.postgres_version}/bin/postgresql-${var.postgres_version}-setup initdb",
      "echo 'Enabling and starting PostgreSQL service...'",
      "sudo systemctl enable postgresql-${var.postgres_version}",
      "sudo systemctl start postgresql-${var.postgres_version}",
      "echo 'Configuring PostgreSQL streaming replication settings ...'",
      "sudo -iu postgres psql -c \"ALTER SYSTEM SET wal_level = 'replica';\"",
      "sudo -iu postgres psql -c \"ALTER SYSTEM SET max_wal_senders = '10';\"",
      "sudo -iu postgres psql -c \"ALTER SYSTEM SET hot_standby = 'on';\"",
      "sudo -iu postgres psql -c \"ALTER SYSTEM SET listen_addresses = '*';\"",
      "echo \"host    replication     ${var.replication_user}    0.0.0.0/0               trust\" | sudo tee -a /var/lib/pgsql/${var.postgres_version}/data/pg_hba.conf",
      "sudo -iu postgres psql -c \"CREATE USER ${var.replication_user} REPLICATION LOGIN ENCRYPTED PASSWORD '${var.replication_password}';\"",
      "echo 'Restarting PostgreSQL service...'",
      "sudo systemctl restart postgresql-${var.postgres_version}"
    ]
  }

  connection {
    type        = "ssh"
    user = (
      var.os_distribution == "ubuntu" || var.os_distribution == "debian" ? "ubuntu" :
      var.os_distribution == "rocky" ? "rocky" :
      var.os_distribution == "centos" ? "centos" :
      var.os_distribution == "fedora" ? "fedora" :
      "ec2-user"
    )
    private_key = file(local_file.private_key.filename)
    host        = self.public_ip
  }
}

# ----------------------------
# Replica instances
# ----------------------------
resource "aws_instance" "replica" {
  count                       = var.replica_count
  ami                         = data.aws_ami.selected.id
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.public[1].id
  associate_public_ip_address = true
  key_name                    = aws_key_pair.my_key.key_name
  vpc_security_group_ids      = [aws_security_group.inst.id]

  tags = {
    Name = "postgres-replica-${count.index}"
  }

  provisioner "remote-exec" {
    inline = [
      "set -e",
      "echo 'Updating system...'",
      "sudo yum update -y",
      "echo 'Installing PostgreSQL repository...'",
      "sudo dnf install -y https://download.postgresql.org/pub/repos/yum/reporpms/EL-8-x86_64/pgdg-redhat-repo-latest.noarch.rpm",
      "echo 'Disabling default PostgreSQL module...'",
      "sudo dnf -qy module disable postgresql",
      "echo 'Installing ${var.postgres_version}...'",
      "sudo dnf install -y postgresql${var.postgres_version}-server",
      "echo 'Initializing PostgreSQL database...'",
      "sudo /usr/pgsql-${var.postgres_version}/bin/postgresql-${var.postgres_version}-setup initdb",
      "echo 'Enabling and starting PostgreSQL service...'",
      "sudo systemctl enable postgresql-${var.postgres_version}",
      "sudo systemctl start postgresql-${var.postgres_version}",
      "sudo systemctl stop postgresql-${var.postgres_version}",
      "echo 'Postgresql Server Stopped Successfully...'",
      "echo 'Creating .pgpass file...'",
      "echo '*:*:*:${var.replication_user}:${var.replication_password}' | sudo tee /var/lib/pgsql/.pgpass > /dev/null",
      "sudo chown postgres:postgres /var/lib/pgsql/.pgpass",
      "sudo chmod 600 /var/lib/pgsql/.pgpass",
      "sudo -iu postgres bash -c 'export PGPASSFILE=/var/lib/pgsql/.pgpass && /usr/pgsql-${var.postgres_version}/bin/pg_basebackup -h ${aws_instance.primary[0].public_ip} -D /var/lib/pgsql/${var.postgres_version}/standby_data -U ${var.replication_user} -P -v -R -C -S test_${count.index}'",
      "echo 'pg_basebackup Completed Successfully...'",
      "sudo sed -i 's/^#\\?port = .*/port = ${tostring(5433 + count.index)}/' /var/lib/pgsql/${var.postgres_version}/standby_data/postgresql.conf",
      "echo 'Port changed Successfully in standby...'",
      "sudo systemctl start postgresql-${var.postgres_version}",
      "echo 'Postgresql Server Started Successfully...'",
      "sudo -iu postgres /usr/pgsql-${var.postgres_version}/bin/pg_ctl -D /var/lib/pgsql/${var.postgres_version}/standby_data start",
      "echo 'Standby Server Started'"
    ]
  }

  connection {
    type = "ssh"
    user = (
      var.os_distribution == "ubuntu" || var.os_distribution == "debian" ? "ubuntu" :
      var.os_distribution == "rocky" ? "rocky" :
      var.os_distribution == "centos" ? "centos" :
      var.os_distribution == "fedora" ? "fedora" :
      "ec2-user"
    )
    private_key = file(local_file.private_key.filename)
    host        = self.public_ip
  }

  depends_on = [aws_instance.primary]
}

# ----------------------------
# Pgbench run (local-exec example)
# ----------------------------
resource "null_resource" "pgbench_run" {
  for_each = local.primary_instance_ips

  depends_on = [aws_instance.primary]

  provisioner "local-exec" {
    command = <<-EOF
      if [ "${var.run_pgbench}" = "yes" ]; then
        ssh -o StrictHostKeyChecking=no -i ${local_file.private_key.filename} ec2-user@${each.value} <<'EOF_REMOTE'

sudo -iu postgres /usr/pgsql-${var.postgres_version}/bin/pgbench -i -s 5 postgres
sudo -iu postgres /usr/pgsql-${var.postgres_version}/bin/pgbench -c 10 -j 2 -T 60 postgres
EOF_REMOTE
      fi
    EOF
  }
}

# ----------------------------
# Pgbench cleanup using remote-exec (runs on primary instances)
# ----------------------------
resource "null_resource" "pgbench_cleanup" {
  count = var.cleanup_pgbench == "yes" && var.run_pgbench == "yes" ? length(aws_instance.primary) : 0

  depends_on = [null_resource.pgbench_run]

  provisioner "remote-exec" {
    inline = [
      "sudo -iu postgres psql -d postgres -c 'DROP TABLE IF EXISTS pgbench_accounts, pgbench_branches, pgbench_history, pgbench_tellers;'"
    ]

    connection {
      type        = "ssh"
      host        = aws_instance.primary[count.index].public_ip
      user = (
        var.os_distribution == "ubuntu" || var.os_distribution == "debian" ? "ubuntu" :
        var.os_distribution == "rocky" ? "rocky" :
        var.os_distribution == "centos" ? "centos" :
        var.os_distribution == "fedora" ? "fedora" :
        "ec2-user"
      )
      private_key = file(local_file.private_key.filename)
    }
  }
}


        #ssh -o StrictHostKeyChecking=no -i ${local_file.private_key.filename} ec2-user@${each.value} <<EOF_REMOTE
