# Lock.host-ssh
Put sshd in an enclave, see:
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
    "PCR0": "d795c01d6364349b39e6f1db6986c984c1c79e09c87f94b09e45727fc5c2d1f18866ede0a9f780e5b11b0320ce9456b1",
    "PCR1": "4b4d5b3661b3efc12920900c80e126e4ce783c522de6c02a2a5bf7af3a2b9327b86776f188e4be1c1c404a129dbda493",
    "PCR2": "6027aa49f664e990e9941de72bbbf7a8314b71679f1c33226b88d64be4dc836a03f7707cb094f56ea24af0bcf4c96aa6"
  }
}
```

See that [run.yml](.github/workflows/run.yml) step "PCR" is testing that PCRs in this readme match the build

## Prod
+ In prod all TEE I/O passes through /dev/vsock
+ Think of /dev/vsock as a file handle
+ How to run:
```
just serve-alpine
just build-app
cp example.env .env
just run-app
just run-host
just atsocat 2223 the.prod.i.p 2222
ssh -p 2223 root@localhost
```

## Test
+ In test a container emulates a TEE
+ Uses two fifos /tmp/read /tmp/write to emulate vsock
+ How to run:
```
just serve-alpine
just build-test-app
just run-test-app
just run-test-host
just atsocat 2223 lockhost-host 2222
ssh -p 2223 root@localhost
```

## Why
+ Because we can
+ Because it demonstrate lock.host versatility
+ Because it can assist with exploring nitro enclave runtime

## License
MIT
