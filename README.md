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
    "PCR0": "73c84ba3480ea68e44f3abcf06c7f6fa39f32ae413b4442907a00bfe265f77d7faf9a5d504b424b51488054683f50c0a",
    "PCR1": "4b4d5b3661b3efc12920900c80e126e4ce783c522de6c02a2a5bf7af3a2b9327b86776f188e4be1c1c404a129dbda493",
    "PCR2": "86ef7620d53315d440d2440a5d5f0aa825b95a0a62b50602efeba9d656fca67ab831d2ae23615a7a1187b40e31877640"
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
