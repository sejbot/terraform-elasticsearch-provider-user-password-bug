terraform {
  required_version = ">= 0.14"
  required_providers {
    elasticsearch = {
      source  = "phillbaker/elasticsearch"
      version = "= 1.5.3"
    }
  }
}

provider "elasticsearch" {
  url      = "http://localhost:9200"
  sniff    = false
  username = "elastic"
  password = "" //Run setup passwords to get the password
}

resource "elasticsearch_xpack_user" "myuser" {
    username = "myuser"
    fullname = "My User"
    password = "mysecretpassword"
    roles = [
        "superuser",
        #"kibana_admin" //Follow the steps in README.md and uncomment this role in step 8
    ]
}
