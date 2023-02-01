terraform {
  backend "s3" {
    bucket = "abbvie-infosec-eks-app"
    key    = "infosec-eksbackend"
    region = "us-east-2"
    profile = "abbviesplunkk8s"
  }
}
