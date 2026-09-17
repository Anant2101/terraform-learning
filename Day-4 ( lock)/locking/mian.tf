
# =========================================================
# VPC
# =========================================================

resource "aws_vpc" "rds_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "terraform-rds-vpc"
  }
}

# =========================================================
# Private Subnet - AZ 1
# =========================================================

resource "aws_subnet" "private_subnet_1" {
  vpc_id            = aws_vpc.rds_vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "rds-private-subnet-1a"
  }
}

# =========================================================
# Private Subnet - AZ 2
# =========================================================

resource "aws_subnet" "private_subnet_2" {
  vpc_id            = aws_vpc.rds_vpc.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "us-east-1b"

  tags = {
    Name = "rds-private-subnet-1b"
  }
}

# =========================================================
# Route Table
# No Internet Gateway / NAT required for this basic
# private RDS learning setup.
# =========================================================

resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.rds_vpc.id

  tags = {
    Name = "rds-private-route-table"
  }
}

# =========================================================
# Associate Subnet 1 with Route Table
# =========================================================

resource "aws_route_table_association" "private_1" {
  subnet_id      = aws_subnet.private_subnet_1.id
  route_table_id = aws_route_table.private_rt.id
}

# =========================================================
# Associate Subnet 2 with Route Table
# =========================================================

resource "aws_route_table_association" "private_2" {
  subnet_id      = aws_subnet.private_subnet_2.id
  route_table_id = aws_route_table.private_rt.id
}

# =========================================================
# Security Group for RDS
# =========================================================

resource "aws_security_group" "rds_sg" {
  name        = "terraform-rds-sg"
  description = "Security group for PostgreSQL RDS"
  vpc_id      = aws_vpc.rds_vpc.id

  ingress {
    description = "PostgreSQL from inside VPC"
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "terraform-rds-sg"
  }
}

# =========================================================
# RDS DB Subnet Group
# =========================================================

resource "aws_db_subnet_group" "rds_subnet_group" {
  name = "terraform-rds-subnet-group"

  subnet_ids = [
    aws_subnet.private_subnet_1.id,
    aws_subnet.private_subnet_2.id
  ]

  tags = {
    Name = "terraform-rds-subnet-group"
  }
}

# =========================================================
# PRIMARY RDS POSTGRESQL
# =========================================================

resource "aws_db_instance" "postgres_primary" {
  identifier = "terraform-postgres-primary"

  engine = "postgres"

  instance_class = "db.t3.micro"

  allocated_storage = 20
  storage_type      = "gp3"

  db_name  = "terraformdb"
  username = "postgres"
  password = "MyStrongPassword123!"

  port = 5432

  db_subnet_group_name = aws_db_subnet_group.rds_subnet_group.name

  vpc_security_group_ids = [
    aws_security_group.rds_sg.id
  ]

  publicly_accessible = false

  # Required for read replica
  backup_retention_period = 7

  storage_encrypted = true

  multi_az = false

  skip_final_snapshot = true

  deletion_protection = false

  apply_immediately = true

  tags = {
    Name = "terraform-postgres-primary"
    Role = "Primary"
  }
}

# =========================================================
# READ REPLICA
# =========================================================

resource "aws_db_instance" "postgres_replica" {
  identifier = "terraform-postgres-replica"

  instance_class = "db.t3.micro"

  # Same-region replica + DB subnet group
  # => use source DB ARN
  replicate_source_db = aws_db_instance.postgres_primary.arn

  db_subnet_group_name = aws_db_subnet_group.rds_subnet_group.name

  vpc_security_group_ids = [
    aws_security_group.rds_sg.id
  ]

  publicly_accessible = false

  skip_final_snapshot = true

  apply_immediately = true

  tags = {
    Name = "terraform-postgres-replica"
    Role = "Read Replica"
  }
}
