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
    organization = "shahid-test"

    workspaces {
      name = "shahid-actions-demo"
    }
  }
}


provider "aws" {
    region = "us-east-2"
  
}

resource "aws_vpc" "crm" {
    cidr_block = "10.0.0.0/16"
    instance_tenancy = "default"

    tags = {
      Name = "crmvpc"

    }
  
}

resource "aws_subnet" "crmsubnet" {
    vpc_id = aws_vpc.crm.id
    cidr_block = "10.0.1.0/24"
    availability_zone = "us-east-2b"
    tags = {
     Name = "crmsubnet"

    }
  
}

resource "aws_security_group" "crmsg" {
    name = "allow_rdp_traffic"
    description = "Allow RDP inbound traffic"
    vpc_id = aws_vpc.crm.id

  tags = {
    Name = "crmsg"
  }
}

resource "aws_security_group_rule" "crmrule" {
  type              = "ingress"
  from_port         = 3389
  to_port           = 3389
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.crmsg.id
}

resource "aws_security_group_rule" "allow_all" {
  type              = "egress"
  to_port           = 0
  protocol          = "-1"
  cidr_blocks    = ["0.0.0.0/0"]
  from_port         = 0
  security_group_id = aws_security_group.crmsg.id
}

resource "aws_internet_gateway" "crmig" {
    vpc_id = aws_vpc.crm.id
  
  tags = {
    Name = "crmig"
  }
}

resource "aws_route_table" "crmrt" {
    vpc_id = aws_vpc.crm.id

    route {
         
         cidr_block = "0.0.0.0/0"
         gateway_id = aws_internet_gateway.crmig.id
         
        }

      tags = {
          Name = "crmrt"

      }
  }

  resource "aws_route_table_association" "crmrtas" {
      subnet_id = aws_subnet.crmsubnet.id
      route_table_id = aws_route_table.crmrt.id

    
  }

  resource "aws_network_interface" "crm-nic" {
  subnet_id       = aws_subnet.crmsubnet.id
  private_ips     = ["10.0.1.22"]
  security_groups = [aws_security_group.crmsg.id]


  }

  resource "aws_instance" "crm-web" {
    ami = "ami-0a727a421bd5a51a3"
    instance_type = "t2.micro"
    key_name = "windowkey"
    availability_zone = "us-east-2b"
    
    
  tags = {
     Name = "crmweb"
  }
network_interface {
 device_index = 0
 network_interface_id = aws_network_interface.crm-nic.id

   }

}

resource "aws_eip" "one" {
  vpc                       = true
  network_interface         = aws_network_interface.crm-nic.id
  associate_with_private_ip = "10.0.1.22"
  depends_on = [aws_internet_gateway.crmig,aws_instance.crm-web]

}