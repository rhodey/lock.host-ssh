sudo := "$(docker info > /dev/null 2>&1 || echo 'sudo')"

#########################
## Reproducible builds ##
#########################

serve-alpine:
    python3 -m http.server -d apk/ 8082

build-app:
    {{sudo}} docker buildx build --platform="linux/amd64" -f Dockerfile.nitro -t lockhost-ssh-build-app .
    {{sudo}} docker rm -f lockhost-ssh-build-app > /dev/null 2>&1 || true
    {{sudo}} docker run --platform="linux/amd64" --name lockhost-ssh-build-app -v /var/run/docker.sock:/var/run/docker.sock lockhost-ssh-build-app
    mkdir -p dist
    {{sudo}} docker cp lockhost-ssh-build-app:/workspace/app.eif ./dist/ || true
    {{sudo}} docker cp lockhost-ssh-build-app:/workspace/app.pcr ./dist/ || true
    {{sudo}} docker rm -f lockhost-ssh-build-app > /dev/null  2>&1 || true

build-app-vm:
    sudo multipass delete --purge myvm > /dev/null  2>&1 || true
    sudo snap install multipass
    sudo snap restart multipass.multipassd
    sleep 5
    sudo multipass find --force-update
    sudo multipass launch 24.04 --name myvm --cpus 2 --memory 4G --disk 32G
    sudo multipass stop myvm
    sudo multipass mount -t native ../lock.host myvm:/home/ubuntu/base
    sudo multipass mount -t native ./ myvm:/home/ubuntu/app
    sudo multipass start myvm
    sudo multipass exec myvm -- sudo apt install -y just
    sudo multipass exec myvm -- bash -c "curl -fsSL https://get.docker.com -o /tmp/docker.sh"
    sudo multipass exec myvm -- VERSION=28.3.3 sh /tmp/docker.sh
    sudo multipass exec myvm -- bash -c "cp -r ~/base ~/basee"
    sudo multipass exec myvm -- bash -c "cp -r ~/app ~/appp"
    sudo multipass exec myvm -- bash -c "cd ~/basee && just serve-alpine" &
    sudo multipass exec myvm -- bash -c "cd ~/basee && just build-runtime"
    sudo multipass exec myvm -- bash -c "cd ~/appp && just serve-alpine" &
    sudo multipass exec myvm -- bash -c "cd ~/appp && just build-app"
    mkdir -p dist
    sudo multipass exec myvm -- sudo cp /home/ubuntu/appp/dist/app.pcr /home/ubuntu/app/dist/
    sudo multipass exec myvm -- sudo chmod 666 /home/ubuntu/app/dist/app.pcr
    sudo multipass delete --purge myvm


#############
## Testing ##
#############

make-test-fifos:
    mkfifo /tmp/read > /dev/null 2>&1 || true
    mkfifo /tmp/write > /dev/null 2>&1 || true

build-test-app:
    just make-test-fifos
    {{sudo}} docker buildx build --platform="linux/amd64" --build-arg PROD=false -f Dockerfile.app -t lockhost-ssh-test-app .


#########################
## Allow update alpine ##
#########################

proxy-alpine:
    cd ../lock.host && just build-proxy-alpine
    {{sudo}} docker run --rm -it -v ./apk:/root/apk -p 8080:8080 lockhost-proxy-alpine

fetch-alpine:
    {{sudo}} docker buildx build --platform="linux/amd64" -f apk/Dockerfile.fetch -t lockhost-fetch-alpine .


##########
## Prod ##
##########

run-host:
    sudo docker run --rm -it --privileged --name lockhost-host -v /dev/vsock:/dev/vsock -p 2222:2222 --env-file .env -e PROD=true lockhost-host 2222

run-app:
    sudo nitro-cli run-enclave --cpu-count 2 --memory 4096 --enclave-cid 16 --eif-path dist/app.eif

run-app-debug:
    sudo nitro-cli run-enclave --cpu-count 2 --memory 4096 --enclave-cid 16 --eif-path dist/app.eif --debug-mode

atsocat listen target:
    {{sudo}} docker run --rm -it --entrypoint /runtime/atsocat.sh -p {{listen}}:{{listen}} lockhost-host {{listen}} {{target}}

nitro:
    sudo nitro-cli describe-enclaves

eid := "$(just nitro | jq -r '.[0].EnclaveID')"

nitro-logs:
    sudo nitro-cli console --enclave-id {{eid}}

nitro-rm:
    sudo nitro-cli terminate-enclave --enclave-id {{eid}}
