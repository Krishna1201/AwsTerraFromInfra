provider "aws" {
    access_key = "${var.aws_access_key}"
    secret_key ="${var.aws_secret_key}"
    region     ="${var.aws_region}"
}

# Create VPC
 
 resource "aws_vpc" "Devops"{
     cidr_block = "${var.vpc_cidr}"
     enable_dns_hostnames= true

     #tags{
      #   Name = "DevopsOne-VPC"
     #}
 }

# Setup the public subnet - on US-East-1A AZ
resource "aws_subnet" "public-subnet" {
    vpc_id ="${aws_vpc.Devops.id}"
    cidr_block ="${var.public_subnet_cidr}"
    availability_zone ="us-east-1a"
  #tags{
   #   Name = "Public Subnet"
  #}
}

# Setup private subnet - on US-East-1B AZ
resource "aws_subnet" "private-subnet" {
    vpc_id="${aws_vpc.Devops.id}"
    cidr_block="${var.private_subnet_cidr}"
    availability_zone= "us-east-1b"

   # tags{
    #    Name = "Private Subnet"
    #}
  
}

 # Setup internet gateway
resource "aws_internet_gateway" "gw"{
    vpc_id = "${aws_vpc.Devops.id}"

    #tags{
     #   Name = "DevopsOne-Internet GateWay"
    #}
}

# Setup Route Table

resource "aws_route_table" "web-public-rt" {

    vpc_id ="${aws_vpc.Devops.id}"
    route{
        cidr_block = "0.0.0.0/0"
        gateway_id ="${aws_internet_gateway.gw.id}"
    }

    #tags{
     #   Name = "Public Subnet Route Table"
    #}
  
}

# Assign the route table to the public Subnet
resource "aws_route_table_association" "web-public-rt" {
    subnet_id ="${aws_subnet.public-subnet.id}"
    route_table_id = "${aws_route_table.web-public-rt.id}"
  
}
# Setup Security Group for public subnet
resource "aws_security_group" "sg-public" {
     name = "vpc_test_web"
     description = "Allow incoming HTTP connections & SSH access"
     ingress {
         from_port = 8080
         to_port = 8080
         protocol = "tcp"
         cidr_blocks = ["0.0.0.0/0"]
     }
     ingress {
    from_port = 443
    to_port = 443
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port = 3389
    to_port = 3389
    protocol = "tcp"
   cidr_blocks = ["0.0.0.0/0"]
  }
   ingress {
    from_port = -1
    to_port = -1
    protocol = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
  }
ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks =  ["0.0.0.0/0"]
  }
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    }
    vpc_id = "${aws_vpc.Devops.id}"

    #tags{
     #   Name ="Public-sg"
    #}
  
}

# Setup security group for private subnet
resource "aws_security_group" "sg-private" {
    name = "sg_test_web"
    description = "Allow traffic from public subnet"
    
    ingress {
         from_port = 3306
         to_port = 3306
         protocol= "tcp"
         cidr_blocks = ["${var.public_subnet_cidr}"]
    }
    ingress {
    from_port = 8080
    to_port = 8080
    protocol = "tcp"
    cidr_blocks = ["${var.public_subnet_cidr}"]
  }
  ingress {
    from_port = -1
    to_port = -1
    protocol = "icmp"
    cidr_blocks = ["${var.public_subnet_cidr}"]
  }
   ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["${var.public_subnet_cidr}"]
  }
  # Allow traffic within Private Subnet
ingress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["${var.private_subnet_cidr}"]
  }

egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  vpc_id ="${aws_vpc.Devops.id}"

  #tags {
   # Name = "Private-SG"
  #}


  
}







