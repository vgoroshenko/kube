resource "aws_cognito_user_pool" "pool" {
  name = var.mln_cognito_name
  schema {
    attribute_data_type = "String"
    mutable = true
    name = "creatorEmail"
    string_attribute_constraints {
      min_length = "1"
      max_length = "256"
    }
  }
  schema {
    attribute_data_type = "String"
    mutable = true
    name = "firstName"
    string_attribute_constraints {
      min_length = "1"
      max_length = "256"
    }
  }
  schema {
    attribute_data_type = "String"
    mutable = true
    name = "lastName"
    string_attribute_constraints {
      min_length = "1"
      max_length = "256"
    }
  }
  schema {
    attribute_data_type = "String"
    mutable = true
    name = "age"
    string_attribute_constraints {
      min_length = "1"
      max_length = "256"
    }
  }
  schema {
    attribute_data_type = "String"
    mutable = true
    name = "nativeLanguage"
    string_attribute_constraints {
      min_length = "1"
      max_length = "256"
    }
  }
  schema {
    attribute_data_type = "String"
    mutable = true
    name = "country"
    string_attribute_constraints {
      min_length = "1"
      max_length = "256"
    }
  }
  schema {
    attribute_data_type = "Number"
    mutable = true
    name = "sendMessageTime"
    number_attribute_constraints {
      min_value = "0"
      max_value = "10000000000000"
    }
  }
  schema {
    attribute_data_type = "Number"
    mutable = true
    name = "permissionValue"
    number_attribute_constraints {
      min_value = "0"
      max_value = "1000"
    }
  }

  password_policy {
    minimum_length = 8
    require_numbers = true
    require_lowercase = true
    require_uppercase = true
    require_symbols = false
  }
  username_attributes = [
    "email"]
  auto_verified_attributes = [
    "email"]
  lambda_config {
    pre_sign_up = "arn:aws:lambda:${var.region}:${var.account_id}:function:${module.lambda_function_email_verified.lambda_function_name}"
  }
}

module "lambda_function_email_verified" {
  source = "terraform-aws-modules/lambda/aws"
  function_name = var.lambda_function_name
  handler = "index.handler"
  runtime = "nodejs14.x"
  create_package         = false
  local_existing_package = "lambda_function.zip"
}
resource "aws_cognito_user_group" "pool" {
  name = "AdminUsers"
  description = "Admin users whom will be given permissions"
  user_pool_id = aws_cognito_user_pool.pool.id
}