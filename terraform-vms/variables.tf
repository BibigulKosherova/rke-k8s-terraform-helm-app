variable region {
    type = string
    description = "Provide region"
    default = "us-east-2"
}

variable ip_on_launch {
    type = bool
    default = true
}

variable instance_type {
    type = string
    default = "t3a.medium"
}



