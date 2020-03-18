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

variable "subnet_id"{
    type    = string
}
variable "subnet_id2"{
    type    = string
}
#variable "cluster_role"{
#    type    = string
#}
variable "clustername" {
  type    = string
}