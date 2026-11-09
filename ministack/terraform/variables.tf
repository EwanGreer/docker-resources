variable "region" {
  description = "AWS region for the resources"
  type        = string
  default     = "us-east-1"
}

variable "bucket_name" {
  description = "S3 bucket name"
  type        = string
  default     = "example-bucket"
}

variable "queue_name" {
  description = "SQS queue name"
  type        = string
  default     = "example-queue"
}

variable "db_identifier" {
  description = "RDS instance identifier"
  type        = string
  default     = "example-db"
}

variable "db_username" {
  description = "Master username for the Postgres instance"
  type        = string
  default     = "admin"
}

variable "instance_name" {
  description = "Name tag for the EC2 instance"
  type        = string
  default     = "example-instance"
}

variable "ami" {
  description = "AMI for the EC2 instance (any value works in MiniStack)"
  type        = string
  default     = "ami-12345678"
}
