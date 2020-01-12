# Some Terraform Examples


## vpc_with_nat_gw.tf

This will create a two az-vpc with a nat GW, and the public/private routing setup.

It will also create a iam role/instance profile for use with SSM, so you can use SSM-Session Manager to connect into it, which is easy if you're lazy.


## vpc_with_nat_instance.tf

This will create a two az-vpc with a nat instance, and the public/private routing setup.

It will also create a iam role/instance profile for use with SSM, so you can use SSM-Session Manager to connect into it, which is easy if you're lazy.

Nat instances can be way cheaper than Nat gateways, and as this instance is t2.micro, it is both free tier eligible and much cheaper than a nat gateway