variable "aws_region" {
  type    = string
  default = "{{ cookiecutter.aws_region }}"
}

provider "aws" {
  region = var.aws_region
  # assume_role {
  #   role_arn = "" ## set environment-specific role arn here
  # }
}
