# Define a provider
provider "aws" {
  region = "us-east-1"
}


# Create a VPC
resource "aws_vpc" "dev-vpc" {
  cidr_block = "10.1.0.0/16"

  tags = {
    Name = "Development"
  }
}

# Create a internet gateway
resource "aws_internet_gateway" "igw-dev" {
  vpc_id = aws_vpc.dev-vpc.id
  tags = {
    Name = "Dev-IGW"
  }
}

# Create custom route table
resource "aws_route_table" "dev-route-table" {
  vpc_id = aws_vpc.dev-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw-dev.id
  }

  tags = {
    Name = "Dev_RT"
  }
}

# Create Subnets
resource "aws_subnet" "az1-subnet" {
  vpc_id     = aws_vpc.dev-vpc.id
  cidr_block = "10.1.1.0/24"

  tags = {
    Name = "publicWebServers"
  }
}

# Associate with route table 
resource "aws_route_table_association" "dev" {
  subnet_id      = aws_subnet.az1-subnet.id
  route_table_id = aws_route_table.dev-route-table.id
}

# Create a Security Group
resource "aws_security_group" "allow_web" {
  name        = "allow_web_traffic"
  description = "Allow inbound web traffic"
  vpc_id      = aws_vpc.dev-vpc.id

  ingress {
    description = " WEB from VPC"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = " SSH from VPC"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "WebServerAllow"
  }
}

# Create AWS EFS resource
resource "aws_efs_access_point" "test" {
  file_system_id = aws_efs_file_system.foo.id
}

resource "aws_efs_file_system" "foo" {
  creation_token = "my-product"

  tags = {
    Name = "MyProduct"
  }
}

resource "aws_efs_mount_target" "alpha" {
  file_system_id = aws_ef_file_system.foo.id
  subnet_id = aws_subnet.az1-subnet-id
}

# Create Network Interface
resource "aws_network_interface" "web-server-nic" {
  subnet_id       = aws_subnet.az1-subnet.id
  private_ips     = ["10.1.1.50"]
  security_groups = [aws_security_group.allow_web.id]

}

# Asign an elastic IP to the network interface created in step 7
resource "aws_eip" "prod-eip" {
  vpc                       = true
  network_interface         = aws_network_interface.web-server-nic.id
  associate_with_private_ip = "10.1.1.50"
  depends_on                = [aws_internet_gateway.igw-dev] # We need to add this or this gonna end in failed state and pass its like a list

  tags = {
    Name = "Prod-ENI"
  }
}

resource "aws_instance" "web" {
  ami               = "ami-0be2609ba883822ec"
  instance_type     = "t2.micro"
  availability_zone = "us-east-1a"
  key_name          = "myNewKeyPair"

  network_interface {
    device_index         = 0
    network_interface_id = aws_network_interface.web-server-nic.id
  }

  user_data = <<EOF
       #!/bin/bash
       sudo yum update -y
       sudo yum install httpd -y
       sudo systemctl start httpd
       sudo bash -c 'echo NICE! > /var/www/html/index.html'
       EOF

  tags = {
    Name = "AmazonWebServer"
  }
}