cat << 'EOF' > codebuild.tf
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "ap-southeast-2" 
}

data "aws_secretsmanager_secret" "github" {
  name = "github-token"
}

data "aws_secretsmanager_secret_version" "github_token_val" {
  secret_id = data.aws_secretsmanager_secret.github.id
}

resource "aws_codebuild_source_credential" "github_auth" {
  auth_type   = "PERSONAL_ACCESS_TOKEN"
  server_type = "GITHUB"
  token       = data.aws_secretsmanager_secret_version.github_token_val.secret_string
}

resource "aws_iam_role" "cb_execution_role" {
  name = "manual-sam-codebuild-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action    = "sts:AssumeRole"
        Effect    = "Allow"
        Principal = { Service = "://amazonaws.com" }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "cb_admin_access" {
  role       = aws_iam_role.cb_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

resource "aws_codebuild_project" "sam_pipeline" {
  name          = "manual-sam-builder"
  service_role  = aws_iam_role.cb_execution_role.arn
  build_timeout = "20"

  artifacts {
    type = "NO_ARTIFACTS"
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/amazonlinux2-x86_64-standard:4.0"
    type                        = "LINUX_CONTAINER"
    privileged_mode             = true 
  }

  source {
    type            = "GITHUB"
    location        = "https://github.com/Kavitha0401/lambda-deployment.git" 
    buildspec       = "dev/buildspec.yml"
    git_clone_depth = 1
  }
}
EOF
