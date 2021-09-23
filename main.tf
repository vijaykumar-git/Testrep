terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "3.26.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "3.0.1"
    }
  }
  required_version = ">= 0.14"

  backend "remote" {
    organization = "vijayorg"

    workspaces {
      name = "gh-actions-demo"
    }
  }
}



provider "aws" {
  region = "us-east-2"
}
 

resource "aws_instance" "web" {
  ami           = "ami-830c94e3"
  instance_type = "t2.micro"
}
