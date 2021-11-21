######Getting availability zone datas using data-resource in tfstate file########

data "aws_availability_zones" "Azones" {
                         state = "available"
}

########## Creating VPC ###############

resource "aws_vpc" "project-vpc" {
  cidr_block                   = var.vpc_cidr
  instance_tenancy             = "default"
  enable_dns_hostnames         = true
  enable_dns_support           = true

  tags = {
  Name                         = "${var.pro}-vpc"
  }
}

######## Attaching internetGateway ######

resource "aws_internet_gateway" "my-igw" {
  vpc_id = aws_vpc.project-vpc.id

  tags = {
    Name = "${var.pro}-igw"
  }
}

########## Creating subnets #############
### Public 1

resource "aws_subnet" "public-1" {
  vpc_id                  = aws_vpc.project-vpc.id
  cidr_block              = cidrsubnet(var.vpc_cidr , var.subnets , 0 )
  availability_zone       = data.aws_availability_zones.Azones.names[0]
  map_public_ip_on_launch = true
  tags = {
    Name = "${var.pro}-public1"
  }
}
### Public 2

resource "aws_subnet" "public-2" {
  vpc_id                  = aws_vpc.project-vpc.id
  cidr_block              = cidrsubnet(var.vpc_cidr , var.subnets , 1 )
  availability_zone       = data.aws_availability_zones.Azones.names[1]
  map_public_ip_on_launch = true
  tags = {
    Name = "${var.pro}-public2"
  }
}
### Public 3

resource "aws_subnet" "public-3" {
  vpc_id                  = aws_vpc.project-vpc.id
  cidr_block              = cidrsubnet(var.vpc_cidr , var.subnets , 2 )
  availability_zone       = data.aws_availability_zones.Azones.names[2]
  map_public_ip_on_launch = true
  tags = {
    Name = "${var.pro}-public3"
  }
}
######### Creating public route table ##############

resource "aws_route_table" "project-public" {
            vpc_id = aws_vpc.project-vpc.id
  route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.my-igw.id
        }
              tags = {
              Name = "${var.pro}-pub-rt"
               }
}
########## Route table association ############

resource "aws_route_table_association" "sub1" {
  subnet_id      = aws_subnet.public-1.id
  route_table_id = aws_route_table.project-public.id
}

resource "aws_route_table_association" "sub2" {
  subnet_id      = aws_subnet.public-2.id
  route_table_id = aws_route_table.project-public.id
}

resource "aws_route_table_association" "sub3" {
  subnet_id      = aws_subnet.public-3.id
  route_table_id = aws_route_table.project-public.id
}

########### Key pair ##########################
resource "aws_key_pair" "terra-key" {

  key_name   = "terra-key"
  public_key = file("tfkey.pub")
  tags       = {
    Name = "terra-key"
  }
}
########## Security Groups ###################

###Sec_group for Nginx
resource "aws_security_group" "nginx" {

  name        = "${var.pro}-nginx"
  description = "Allow 22,80,443"
  vpc_id      =  aws_vpc.project-vpc.id

  ingress  {

      from_port        = 80
      to_port          = 80
      protocol         = "tcp"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = ["::/0"]
    }

  ingress  {

      from_port        = 443
      to_port          = 443
      protocol         = "tcp"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = ["::/0"]
    }

  ingress  {

      from_port        = 22
      to_port          = 22
      protocol         = "tcp"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = ["::/0"]
    }

  egress  {

      from_port        = 0
      to_port          = 0
      protocol         = "-1"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = ["::/0"]
    }
      tags =  {
  Name               = "${var.pro}-nginx"
   }
}

######## Flask-app ##########
resource "aws_security_group" "flask" {

  name        = "${var.pro}-flask"
  description = "Allow access to 5000 and 22 from nginx"
  vpc_id      = aws_vpc.project-vpc.id

ingress  {
  from_port          = 5000
  to_port            = 5000
  protocol           = "tcp"
  cidr_blocks        =  [ "0.0.0.0/0" ]
  ipv6_cidr_blocks   =  [ "::/0" ]
   }

ingress  {
  from_port          = 22
  to_port            = 22
  protocol           = "tcp"
  cidr_blocks        =  [ "0.0.0.0/0" ]
  ipv6_cidr_blocks   =  [ "::/0" ]

   }

egress  {
  from_port          = 0
  to_port            = 0
  protocol           = "-1"
  cidr_blocks        =  [ "0.0.0.0/0" ]
  ipv6_cidr_blocks   =  [ "::/0" ]
    }
tags =  {
  Name               = "${var.pro}-flask"
   }

}

######## DBserver ##########

resource "aws_security_group" "database" {

  name        = "${var.pro}-database"
  description = "Allow access to 3306 and 22 from nginx"
  vpc_id      = aws_vpc.project-vpc.id

ingress  {
  from_port          = 3306
  to_port            = 3306
  protocol           = "tcp"
  cidr_blocks        =  [ "0.0.0.0/0" ]
  ipv6_cidr_blocks   =  [ "::/0" ]
   }

ingress  {
  from_port          = 22
  to_port            = 22
  protocol           = "tcp"
  cidr_blocks        =  [ "0.0.0.0/0" ]
  ipv6_cidr_blocks   =  [ "::/0" ]

   }

egress  {
  from_port          = 0
  to_port            = 0
  protocol           = "-1"
  cidr_blocks        =  [ "0.0.0.0/0" ]
  ipv6_cidr_blocks   =  [ "::/0" ]
    }
tags =  {
  Name               = "${var.pro}-database"
   }

}
############Creating Ec2 Instance##############################

####Nginx server#####
resource "aws_instance" "nginx" {

    ami                          =  var.ami
    instance_type                =  var.inst-type
    subnet_id                    =  aws_subnet.public-1.id
    key_name                     =  aws_key_pair.terra-key.id
    associate_public_ip_address  =   true
    vpc_security_group_ids       =  [aws_security_group.nginx.id]
    tags  = {
       Name                      = "${var.pro}-nginx"
    }
}
#### Associating elastic IP with nginx instance ####

resource "aws_eip" "flask-ip" {
  instance = aws_instance.nginx.id
  vpc      = true
}  

####DB server #####
resource "aws_instance" "dbserver" {

    ami                          =  var.ami
    instance_type                =  var.inst-type
    subnet_id                    =  aws_subnet.public-2.id
    key_name                     =  aws_key_pair.terra-key.id
    associate_public_ip_address  =  true
    vpc_security_group_ids       =  [aws_security_group.database.id]
    tags  = {
       Name                      = "${var.pro}-dbserver"
    }
}
####Flask-app server #####
resource "aws_instance" "flask" {

    ami                          =  var.ami
    instance_type                =  var.inst-type
    key_name                     =  aws_key_pair.terra-key.id
    subnet_id                    =  aws_subnet.public-2.id
    associate_public_ip_address  =   true
    vpc_security_group_ids       =  [aws_security_group.flask.id]
    tags  = {
       Name                      = "${var.pro}-flask"
    }
}
### IP's ####

output "pub_nginx" {

	value = aws_eip.flask-ip.public_ip
	description = "Public IP of nginx "

}
output "pub_db" {

	value = aws_instance.dbserver.public_ip	
	description = "Public IP of database server"

}

output "pub_flask" {
 	 value = aws_instance.flask.public_ip
  	 description = "Public IP of flask"
}


output "priv_flask" {
  	value = aws_instance.flask.private_ip
  	description = "Private IP of flask"
}






