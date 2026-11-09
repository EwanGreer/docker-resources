# MiniStack

MiniStack is a free AWS emulator that runs on one port. It works with the AWS CLI, AWS SDKs, and Terraform.

| Service | Address |
|---|---|
| MiniStack API | `http://localhost:4566` |
| StackPort UI | `http://localhost:8080` |

```bash
docker compose up -d
```

State and S3 objects persist in `./data`.

## Terraform example

The `terraform/` directory starts five resources:

- S3 bucket
- Postgres RDS instance
- SQS queue
- EC2 instance
- Secrets Manager secret with the database credentials

```bash
cd terraform
terraform init
terraform plan
terraform apply
```

The database password is generated randomly and stored in the Secrets Manager secret `example-db`:

```bash
docker exec ministack awslocal secretsmanager get-secret-value --secret-id example-db
```

The RDS instance runs a real Postgres container. MiniStack pulls it through the Docker socket that `compose.yml` mounts. Host ports are allocated starting at `15432` (change with `RDS_BASE_PORT`) — check `docker ps` for the actual port.

The provider uses test credentials. Change names and region in `variables.tf` or with `-var`.

```bash
terraform destroy
```
