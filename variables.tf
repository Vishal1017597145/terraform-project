variable "vpc_cidr" {
  default = "10.0.0.0/16"
}
variable "sub1_cidr" {
  default = "10.0.0.0/24"
}

variable "sub2_cidr" {
  default = "10.0.1.0/24"
}
variable "instance_id" {
  default = "t2.micro"
}

variable "volume_type" {
  default = "gp3"
}

variable "volume_size" {
  default = "10"
}
