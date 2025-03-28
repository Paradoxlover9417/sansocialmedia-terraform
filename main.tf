# 기본 인스턴스 - 원래 사용하던 인스턴스를 테라폼으로 임포트 하여 사용
resource "aws_instance" "original_instance" {
  ami                  = var.ec2_ami
  instance_type        = "t2.micro"
  iam_instance_profile = aws_iam_instance_profile.ec2_s3_access_instance_profile.name
}

# 마리아 디비 데이터베이스 인스턴스
resource "aws_db_instance" "sansocialmedia-database" {
  identifier          = var.db_identifier
  engine              = "mariadb"
  instance_class      = "db.t3.micro"
  allocated_storage   = 20
  db_name             = var.db_name
  username            = var.db_username
  password            = var.db_password
  skip_final_snapshot = true

  vpc_security_group_ids = var.vpc_security_group_ids
  engine_version = 10.5

  multi_az = false
}

# 파일 저장을 위한 S3 인스턴스
resource "aws_s3_bucket" "sansocialmedia_bucket" {
  bucket = var.s3_bucket_name
}

# IAM 역할 S3 접속용
resource "aws_iam_role" "ec2_s3_role" {
  name = "ec2_s3_access_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Effect = "Allow"
        Sid    = ""
      },
    ]
  })
}

# IAM 정책 S3 접속용
resource "aws_iam_policy" "ec2_s3_policy" {
  name        = "ec2_s3_policy"
  description = "Allow EC2 to access S3"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "s3:*"
        Effect = "Allow"
        Resource = [
          "${aws_s3_bucket.sansocialmedia_bucket.arn}/*",
          "${aws_s3_bucket.sansocialmedia_bucket.arn}"
        ]
      }
    ]
  })
}

# 역할 정책 연결 S3 접속용
resource "aws_iam_role_policy_attachment" "ec2_s3_policy_attachment" {
  role       = aws_iam_role.ec2_s3_role.name
  policy_arn = aws_iam_policy.ec2_s3_policy.arn
}

# 인스턴스 프로파일
resource "aws_iam_instance_profile" "ec2_s3_access_instance_profile" {
  name = "ec2_s3_access_instance_profile"
  role = aws_iam_role.ec2_s3_role.name
}