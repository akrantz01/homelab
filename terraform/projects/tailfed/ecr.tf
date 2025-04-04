resource "aws_ecrpublic_repository" "lambda" {
  for_each = var.repositories

  repository_name = "tailfed/${each.key}"

  catalog_data {
    description = "Tailfed ${title(each.key)} Lambda Image"
    about_text  = <<-EOA
    The Lambda image for the ${each.key} component of the [Tailfed](https://github.com/akrantz01/tailfed) API.
    It is ${each.value}
    EOA

    operating_systems = ["Linux"]
    architectures     = ["x86-64", "ARM 64"]
  }
}
