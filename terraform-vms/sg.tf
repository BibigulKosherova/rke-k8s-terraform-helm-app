# Opening all ports
data "aws_vpc" "default" {
  default = true
}

resource "aws_security_group" "allow_all" {
  name        = "allow-all-testing"
  description = "Allow all inbound and outbound traffic (for testing only)"
  vpc_id      = data.aws_vpc.default.id

  # Inbound: all traffic from all IPs
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Outbound: all traffic to all IPs
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

