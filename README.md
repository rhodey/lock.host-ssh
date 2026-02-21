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
    "PCR0": "ea67f49a0ce98a7a74724e6d203c48df1c892932c3cf74545fac36ff249e92073585ba5c5728e0065a94b5c446a4e0e9",
    "PCR1": "4b4d5b3661b3efc12920900c80e126e4ce783c522de6c02a2a5bf7af3a2b9327b86776f188e4be1c1c404a129dbda493",
    "PCR2": "f63437f60df62f107567f10daedc72076cf4f6dd556ba28ea875904d1daae49469d477788450e5f7e1d2aa189a5f5f08"
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
