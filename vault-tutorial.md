# Vault Tutorial

1. In vault host, we create directories to store our secret configuration.

```sh
mkdir myvault
cd myvault
mkdir config
mkdir policies
```

2. Initialize and unseal vault.

```sh
vault operator init
vault operator unseal y2CTz0T3JfP/k+2omuLk/0r3Ox53LVjhoZTOtgL0qtZY
vault login s.N7wrm2h0FydyyQkFIYxL9YOT
```

3. Use kv version 1 secret engine with path secret, and store our secret.

`/myvault/config/secret-conf.json`

```json
{ "domain": "www.example.com", "mongodb": { "host": "localhost", "port": 27017}, "mysql": "server=localhost;userid=myms_user;password=kjbgo4eFSzcHYyGf;persistsecurityinfo=True;port=32786;database=mymicroservicedb"}
```

```sh
vault secrets enable -version=1 -path=secret kv
vault write secret/secretapp/config "@/myvault/config/secret-conf.json"
```

4. Test to read our secret as root.
vault read secret/secretapp/config

5. Test to read our secret using wrap token.

```
vault read -wrap-ttl=60s secret/secretapp/config 
vault unwrap lYO2AoJ95QEDnZgUbNxoWWsw
```

6. Create a policy that only can read path secret/secretapp/
`/myvault/policies/policy.hcl`

```hcl
path "secret/secretapp/*" {
  policy = "read"
}
```

```sh
vault policy write secretapp /myvault/policies/policy.hcl
```

7. Enable AppRole.

```sh
vault auth enable approle

# Create ttl role with above policy
vault write auth/approle/role/secretapprole secret_id_ttl=10m token_num_uses=10 token_ttl=2m token_max_ttl=30m secret_id_num_uses=40 policies=secretapp

# Get RoleID and pass to application
vault read auth/approle/role/secretapprole/role-id

# Get Wrap Secret Token
vault write -wrap-ttl=2m -f auth/approle/role/secretapprole/secret-id

# Note we will unwrap the above token to get secretID using vault unwrap



8. Test use RoleID and SecretID to get client token in order to get secretID.

```sh
vault write auth/approle/login \
    role_id=4f08e434-32fb-73c6-fde6-5f0afdfdf5ed \
    secret_id=ccf93982-d0a3-1a91-4568-5492634e474c
# or
curl \
    --request POST \
    --data '{"role_id":"4f08e434-32fb-73c6-fde6-5f0afdfdf5ed","secret_id":"ccf93982-d0a3-1a91-4568-5492634e474c"}' \
    http://127.0.0.1:8200/v1/auth/approle/login
```

9. After get the client token, use this token to get secret data.

```sh
VAULT_TOKEN=s.3pCZ0izxrErf0MbfE5A0Sxgm vault read secret/secretapp/config
# or
curl --header "X-Vault-Token: s.3pCZ0izxrErf0MbfE5A0Sxgm" \
       --request GET \
       http://127.0.0.1:8200/v1/secret/secretapp/config
# or 
vault read -format=json auth/approle/role/secretapprole/role-id | jq -r .data.role_id
vault write -format=json -wrap-ttl=2m -f auth/approle/role/secretapprole/secret-id | jq -r .wrap_info.token
```

# Run Vault Docker Container on AWS

1. Get host Public and Private IP.

```sh
export EC2_PUBLIC_IP="$(curl http://169.254.169.254/latest/meta-data/public-ipv4)"
export EC2_PRIVATE_IP="$(curl http://169.254.169.254/latest/meta-data/local-ipv4)"
```

2. Vault configuration.

```sh
mkdir -p /vault/config
cat <<EOT>> /vault/config/vault.json
{
  "api_addr": "http://${EC2_PRIVATE_IP}:8200",
  "backend": {
    "consul": {
      "address": "127.0.0.1:8500",
      "path": "vault/"
    }
  },
  "cluster_addr": "https://${EC2_PRIVATE_IP}:8201",
  "default_lease_ttl": "168h",
  "listener": {
    "tcp": {
      "address": "0.0.0.0:8200",
      "cluster_address": "${EC2_PRIVATE_IP}:8201",
      "tls_disable": "true"
    }
  },
  "max_lease_ttl": "720h"
}
EOT
```

3. Run vault docker with above configuration.

```sh
docker run -d --net=host --cap-add=IPC_LOCK -e VAULT_ADDR='http://127.0.0.1:8200' -v /vault/config:/vault/config vault server
```
