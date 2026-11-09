resource "aws_s3_bucket" "example" {
  bucket        = var.bucket_name
  force_destroy = true
}

resource "aws_sqs_queue" "example" {
  name = var.queue_name
}

resource "random_password" "db" {
  length  = 16
  special = false
}

resource "aws_db_instance" "example" {
  identifier          = var.db_identifier
  engine              = "postgres"
  engine_version      = "15"
  instance_class      = "db.t3.micro"
  allocated_storage   = 20
  username            = var.db_username
  password            = random_password.db.result
  skip_final_snapshot = true
}

resource "aws_secretsmanager_secret" "db" {
  name = "example-db"
}

resource "aws_secretsmanager_secret_version" "db" {
  secret_id = aws_secretsmanager_secret.db.id
  secret_string = jsonencode({
    username = var.db_username
    password = random_password.db.result
  })
}

resource "aws_instance" "example" {
  ami           = var.ami
  instance_type = "t3.micro"

  tags = {
    Name = var.instance_name
  }
}
