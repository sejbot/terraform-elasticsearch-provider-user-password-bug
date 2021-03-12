1. Start Elasticsearch in Docker with security enabled: 
```
docker run -p 9200:9200 -p 9300:9300 -e "discovery.type=single-node" -e "xpack.security.enabled=true" --name es01 docker.elastic.co/elasticsearch/elasticsearch:7.11.2
```
2. When it has started, generate passwords for system users: 
```
docker exec es01 /bin/bash -c "bin/elasticsearch-setup-passwords auto --batch --url https://es01:9200"
```
3. Copy the password for elastic user and add it to the provider in main.tf
4. Run ```terraform init```
5. Run ```terraform apply```. Plan output looks like this:

```terraform

  # elasticsearch_xpack_user.myuser will be created
  + resource "elasticsearch_xpack_user" "myuser" {
      + enabled  = true
      + fullname = "My User"
      + id       = (known after apply)
      + metadata = jsonencode({})
      + password = (sensitive value)
      + roles    = [
          + "superuser",
        ]
      + username = "myuser"
    }

Plan: 1 to add, 0 to change, 0 to destroy.
```
6. Run curl to verify that elastic is reachable with the new user:
```
curl http://localhost:9200 -u "myuser:mysecretpassword"
```
This should give response:
```
{
  "name" : "4c54de4447ff",
  "cluster_name" : "docker-cluster",
  "cluster_uuid" : "Np-GESHERwaVdEtRs_4bIw",
  "version" : {
    "number" : "7.11.2",
    "build_flavor" : "default",
    "build_type" : "docker",
    "build_hash" : "3e5a16cfec50876d20ea77b075070932c6464c7d",
    "build_date" : "2021-03-06T05:54:38.141101Z",
    "build_snapshot" : false,
    "lucene_version" : "8.7.0",
    "minimum_wire_compatibility_version" : "6.8.0",
    "minimum_index_compatibility_version" : "6.0.0-beta1"
  },
  "tagline" : "You Know, for Search"
}
```
7. Run ```cat terraform.tfstate``` and not the password:
```
{
  "version": 4,
  "terraform_version": "0.14.5",
  "serial": 1,
  "lineage": "f1e17378-7312-7cfb-8199-21ee3212fe0b",
  "outputs": {},
  "resources": [
    {
      "mode": "managed",
      "type": "elasticsearch_xpack_user",
      "name": "myuser",
      "provider": "provider[\"registry.terraform.io/phillbaker/elasticsearch\"]",
      "instances": [
        {
          "schema_version": 0,
          "attributes": {
            "email": "",
            "enabled": true,
            "fullname": "My User",
            "id": "myuser",
            "metadata": "{}",
            "password": "94aefb8be78b2b7c344d11d1ba8a79ef087eceb19150881f69460b8772753263",
            "password_hash": null,
            "roles": [
              "superuser"
            ],
            "username": "myuser"
          },
          "sensitive_attributes": [],
          "private": "bnVsbA=="
        }
      ]
    }
  ]
}
```
8. Add role ```kibana_admin``` to myuser in main.tf
9. Run ```terraform apply```. Plan shows that a new role is the only thing that will change
```terraform
elasticsearch_xpack_user.myuser: Refreshing state... [id=myuser]

An execution plan has been generated and is shown below.
Resource actions are indicated with the following symbols:
  ~ update in-place

Terraform will perform the following actions:

  # elasticsearch_xpack_user.myuser will be updated in-place
  ~ resource "elasticsearch_xpack_user" "myuser" {
        id       = "myuser"
      ~ roles    = [
          + "kibana_admin",
            # (1 unchanged element hidden)
        ]
        # (5 unchanged attributes hidden)
    }

Plan: 0 to add, 1 to change, 0 to destroy.
```
10. Run ```cat terraform.tfstate``` to verify that the password is unchanged in state:
```
{
  "version": 4,
  "terraform_version": "0.14.5",
  "serial": 3,
  "lineage": "f1e17378-7312-7cfb-8199-21ee3212fe0b",
  "outputs": {},
  "resources": [
    {
      "mode": "managed",
      "type": "elasticsearch_xpack_user",
      "name": "myuser",
      "provider": "provider[\"registry.terraform.io/phillbaker/elasticsearch\"]",
      "instances": [
        {
          "schema_version": 0,
          "attributes": {
            "email": "",
            "enabled": true,
            "fullname": "My User",
            "id": "myuser",
            "metadata": "{}",
            "password": "94aefb8be78b2b7c344d11d1ba8a79ef087eceb19150881f69460b8772753263",
            "password_hash": null,
            "roles": [
              "kibana_admin",
              "superuser"
            ],
            "username": "myuser"
          },
          "sensitive_attributes": [],
          "private": "bnVsbA=="
        }
      ]
    }
  ]
}
```
11. Try to access elastic again with same username and password using ```curl http://localhost:9200 -u "myuser:mysecretpassword"``` now gives authentication exception:
```
{"error":{"root_cause":[{"type":"security_exception","reason":"unable to authenticate user [myuser] for REST request [/]","header":{"WWW-Authenticate":"Basic realm=\"security\" charset=\"UTF-8\""}}],"type":"security_exception","reason":"unable to authenticate user [myuser] for REST request [/]","header":{"WWW-Authenticate":"Basic realm=\"security\" charset=\"UTF-8\""}},"status":401}%
```
12. Try to access elastic with the hashed password from the state ```curl http://localhost:9200 -u "myuser:94aefb8be78b2b7c344d11d1ba8a79ef087eceb19150881f69460b8772753263"``` is successful:
```
{
  "name" : "4c54de4447ff",
  "cluster_name" : "docker-cluster",
  "cluster_uuid" : "Np-GESHERwaVdEtRs_4bIw",
  "version" : {
    "number" : "7.11.2",
    "build_flavor" : "default",
    "build_type" : "docker",
    "build_hash" : "3e5a16cfec50876d20ea77b075070932c6464c7d",
    "build_date" : "2021-03-06T05:54:38.141101Z",
    "build_snapshot" : false,
    "lucene_version" : "8.7.0",
    "minimum_wire_compatibility_version" : "6.8.0",
    "minimum_index_compatibility_version" : "6.0.0-beta1"
  },
  "tagline" : "You Know, for Search"
}
```