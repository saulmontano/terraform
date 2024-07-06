# main.tf

provider "aws" {
  region = "us-east-2"
}

resource "aws_vpc" "my_vpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "My-vpc"
  }
}

resource "aws_subnet" "public" {
  vpc_id            = aws_vpc.my_vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-east-2a"
}

resource "aws_subnet" "private" {
  vpc_id            = aws_vpc.my_vpc.id
  cidr_block        = "10.0.2.0/24"  
  availability_zone = "us-east-2a"
}



module "keypair" {
  source  = "terraform-aws-modules/key-pair/aws"
  version = "2.0.3"

  key_name   = "my-keypair"
  public_key = filebase64("${path.module}/my-keypair.pub")
}




module "sg_public" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "5.1.2"
  
  name = "sg_public"
  description = "Security group for public instances"
  vpc_id = aws_vpc.my_vpc.id
  egress_rules = ["all-all"]
  ingress_with_cidr_blocks = [
    {
        from_port =22
        to_port = 22
        protocol = "tcp"
        description = "SSH service"
        cidr_blocks = "0.0.0.0/0"
    }
  ] 

}

module "sg_private" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "5.1.2"
  
  name = "sg_private"
  description = "Security group for public instances"
  vpc_id = aws_vpc.my_vpc.id
  egress_rules = ["all-all"]
  ingress_with_cidr_blocks = [
    {
        from_port =22
        to_port = 22
        protocol = "tcp"
        description = "SSH service"
        cidr_blocks = "10.98.0.0/16"
    }
  ] 

}

module "ec2-public" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "5.6.1"

  name                        = "ec2-public"
  ami                         = "ami-0862be96e41dcbf74"
  instance_type               = "t3a.micro"
  key_name                    = "my-keypair"
  vpc_security_group_ids      = [module.sg_public.security_group_id]
  subnet_id                   = aws_subnet.public.id
  associate_public_ip_address = true
}

module "ec2-private" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "5.6.1"

  name                        = "ec2-private"
  ami                         = "ami-0862be96e41dcbf74"
  instance_type               = "t3a.micro"
  key_name                    = "my-keypair"
  vpc_security_group_ids      = [module.sg_private.security_group_id]
  subnet_id                   = aws_subnet.private.id
  associate_public_ip_address = false
}


output "ec2_public_pub_ip" {
    value = module.ec2-public.public_ip
}
output "ec2_public_pri_ip" {
    value = module.ec2-public.private_ip
}

output "ec2_private_pri_ip" {
    value = module.ec2-private.private_ip
}
