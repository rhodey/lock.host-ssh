# Lock.host-ssh
Put ssh in an enclave, see:
+ [lock.host](https://github.com/rhodey/lock.host)
+ [lock.host-node](https://github.com/rhodey/lock.host-node)
+ [lock.host-python](https://github.com/rhodey/lock.host-python)

## Build app
This is how PCR hashes are checked:
```
just serve-alpine
just build-app
...
{
  "Measurements": {
    "HashAlgorithm": "Sha384 { ... }",
    "PCR0": "0a7213b628effb9a641c51f47aaa8d0c3f7007db88eb5120496bdd1f4f7b7ea3c152bd99f44b95ef170741194ea12da5",
    "PCR1": "4b4d5b3661b3efc12920900c80e126e4ce783c522de6c02a2a5bf7af3a2b9327b86776f188e4be1c1c404a129dbda493",
    "PCR2": "d0e30c140e731c144471145904ef3c3ceb5fd1b453ed06d0dfcaf3cb5cda6f39fd28637299e48f87956e6cf4c93a7845"
  }
}
```

See that [run.yml](.github/workflows/run.yml) is testing that PCRs in this readme match the build

## Test
+ In test a container emulates a TEE
+ Two fifos /tmp/read and /tmp/write emulate a vsock
```
just serve-alpine
just build-test-app make-test-fifos
docker compose up -d
ssh -p 2223 root@localhost
(password is 'root')
```

## Prod
+ In prod all I/O passes through /dev/vsock
```
just serve-alpine
just build-app
just run-app
cp example.env .env
just run-host
just atsocat 2223 https://prod.domain.or.ip:2222
ssh -p 2223 root@localhost
(password is 'root')
```

## Why
+ Because it demonstrates Lock.host versatility
+ Because it assists with exploring the enclave runtime

## License
MIT

hello@lock.host
