variable "aws_region" {
  default = "us-east-1"
}

variable "vpc_cidr" {
  default = "10.0.0.0/16"
}

variable "public_subnet_cidr" {
  default = "10.0.1.0/24"
}

variable "availability_zones" {
  type    = list(string)
  default = ["us-east-1a", "us-east-1b"]
}

variable "ami_id" {
  default = "ami-0c101f26f147fa7fd"
}

variable "instance_type" {
  default = "t2.micro"
}

variable "key_name" {
  description = "Name of your EC2 Key Pair"
  default     = "chidera-key"
}

variable "domain_name" {
  description = "Domain name hosted on Route 53"
  default     = "chidera.store"
}
