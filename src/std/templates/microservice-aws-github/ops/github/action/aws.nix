{
  credentials = {
    name = "Configure AWS Credentials";
    uses = "aws-actions/configure-aws-credentials@main";
    "with" = {
      "role-to-assume" = "\${{ var.AWS_ROLE_ARN }}";
      "aws-region" = "\${{ var.AWS_REGION }}";
    };
  };
  ecr = {
    name = "Login to Amazon ECR";
    uses = "aws-actions/amazon-ecr-login@v1";
  };
}
