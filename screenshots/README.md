# Screenshots

Add the following screenshots to this folder after deployment:

| File | What to capture |
|------|----------------|
| `vpc-subnets.png` | VPC → Subnets page showing all 4 subnets (2 public, 2 private) with their CIDRs and AZs |
| `security-groups.png` | EC2 → Security Groups showing inbound rules for both `alb-sg` and `ec2-sg` |
| `target-group-healthy.png` | EC2 → Target Groups → hello-world-tg → Targets tab showing both instances as **Healthy** |
| `working-page.png` | Browser screenshot of the Hello World page showing instance ID and AZ |

## How to take screenshots

1. After CloudFormation stack is `CREATE_COMPLETE`, wait 5 minutes
2. Open the ALB URL from the Outputs tab
3. Take a full browser screenshot for `working-page.png`
4. Navigate to each AWS console page listed above for the other screenshots
