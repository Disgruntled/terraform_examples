resource "aws_iam_policy" "permissions_boundary_policy" {
  name        = "IAMLimitedEditBoundary"
  path        = "/"
  description = "A policy created to allow some user self service of IAM entities"
  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "NoBoundaryDelete",
            "Effect": "Deny",
            "Action": [
                "iam:DeleteUserPermissionsBoundary",
                "iam:DeleteRolePermissionBoundary"
            ],
            "Resource": "*"
        },
        {
            "Sid": "CreateOrChangeOnlyWithBoundaryInPath",
            "Effect": "Allow",
            "Action": [
                "iam:CreateUser",
                "iam:DeleteUserPolicy",
                "iam:AttachUserPolicy",
                "iam:DetachUserPolicy",
                "iam:PutUserPermissionsBoundary",
                "iam:PutUserPolicy",
                "iam:CreateRole",
                "iam:DeleteRolePolicy",
                "iam:AttachRolePolicy",
                "iam:DetachRolePolicy",
                "iam:PutRolePermissionsBoundary",
                "iam:PutRolePolicy"
            ],
            "Resource": [
                "arn:aws:iam::*:user/customer-roles/*",
                "arn:aws:iam::*:group/customer-roles/*",
                "arn:aws:iam::*:role/customer-roles/*"
            ],
            "Condition": {
                "StringLike": {
                    "iam:PermissionsBoundary": "arn:aws:iam::*:policy/IAMLimitedEditBoundary"
                }
            }
        },
        {
            "Sid": "IAMRead",
            "Effect": "Allow",
            "Action": [
                "iam:List*",
                "iam:Get*",
                "iam:Describe*"
            ],
            "Resource": "*"
        },
                {
            "Sid": "S3Limited",
            "Effect": "Allow",
            "Action": [
                "s3:Get*",
                "s3:PutObject*",
                "s3:List*",
                "s3:Describe*",
                "s3:Abort*"
            ],
            "Resource": "*"
        },
       {
            "Sid": "AllowActions",
            "Effect": "Allow",
            "Action": [
                "ec2:*",
                "kms:*"

            ],
            "Resource": "*"
        },
       {
            "Sid": "Ec2Deny",
            "Effect": "Deny",
            "Action": [
                "ec2:CreateVpcEndpoint",
                "ec2:ModifyVpcEndpoint",
                "ec2:CreateVpc"
            ],
            "Resource": "*"
        }
    ]
}
EOF
}