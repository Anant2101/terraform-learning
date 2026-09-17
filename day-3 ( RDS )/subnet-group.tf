resource "aws_db_subnet_group" "db_subnet_group" {
  name = "myapp-db-subnet-group"
  subnet_ids = [
    aws_subnet.db_subnet_1.id,
    aws_subnet.db_subnet_2.id
  ]

  tags = {
    Name = "myapp-db-subnet-group"
  }
}
