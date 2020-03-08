variable "region" {
  type    = string
  default = "us-east-1"
}

variable "profile" {
  type    = string
  default = "default"
}

variable "vpc_id"{
    type    = string
  
}

variable "cluster_sg"{
    type    = string
}

variable "cluster_ca"{
    type    = string
}

variable "cluster_endpoint"{
    type    = string
}

variable "cluster_version"{
    type    = string
}

variable "cluster_subnet_1"{
    type    = string
}

variable "cluster_subnet_2"{
    type    = string
}