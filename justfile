sudo := "$(docker info > /dev/null 2>&1 || echo 'sudo')"

#########################
## Reproducible builds ##
#########################

serve-alpine:
    python3 -m http.server -d apk/ 8082

build-app:
    {{sudo}} docker buildx build --platform="linux/amd64" -f Dockerfile.nitro -t build-app .
    {{sudo}} docker rm -f build-app > /dev/null  2>&1 || true
    {{sudo}} docker run --platform="linux/amd64" --name build-app -v /var/run/docker.sock:/var/run/docker.sock build-app
    mkdir -p dist
    {{sudo}} docker cp build-app:/workspace/app.eif ./dist/ || true
    {{sudo}} docker cp build-app:/workspace/app.pcr ./dist/ || true
    {{sudo}} docker rm -f build-app > /dev/null  2>&1 || true

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
    sudo multipass exec myvm -- sh /tmp/docker.sh
    sudo multipass exec myvm -- bash -c "cp -r ~/base ~/basee"
    sudo multipass exec myvm -- bash -c "cp -r ~/app ~/appp"
    sudo multipass exec myvm -- bash -c "cd ~/basee && just serve-alpine" &
    sudo multipass exec myvm -- bash -c "cd ~/basee && just build-runtime"
    sudo multipass exec myvm -- bash -c "cd ~/appp && just serve-alpine" &
    sudo multipass exec myvm -- bash -c "cd ~/appp && just build-app"
    mkdir -p dist
    sudo multipass exec myvm -- sudo cp /home/ubuntu/appp/dist/app.eif /home/ubuntu/app/dist/
    sudo multipass exec myvm -- sudo cp /home/ubuntu/appp/dist/app.pcr /home/ubuntu/app/dist/
    sudo multipass exec myvm -- sudo chmod 666 /home/ubuntu/app/dist/app.eif
    sudo multipass exec myvm -- sudo chmod 666 /home/ubuntu/app/dist/app.pcr
    sudo multipass delete --purge myvm


#############
## Testing ##
#############

build-test-app:
    {{sudo}} docker buildx build --platform="linux/amd64" --build-arg PROD=false -f Dockerfile.app -t test-app .

make-test-net:
    {{sudo}} docker network create lockhost-net > /dev/null 2>&1 || true

make-test-fifos:
    mkfifo /tmp/read > /dev/null  2>&1 || true
    mkfifo /tmp/write > /dev/null  2>&1 || true

run-test-host:
    just make-test-net
    just make-test-fifos
    {{sudo}} docker run --rm -it --platform="linux/amd64" --name lockhost-host -v /tmp/read:/tmp/read -v /tmp/write:/tmp/write --network lockhost-net -p 2222:2222 lockhost-host 2222

run-test-app:
    just make-test-fifos
    {{sudo}} docker run --rm -it --cap-add NET_ADMIN --platform="linux/amd64" -v /tmp/read:/tmp/write -v /tmp/write:/tmp/read test-app

atsocat listen target port:
    {{sudo}} docker run --rm -it --platform="linux/amd64" --entrypoint /runtime/atsocat.sh --network lockhost-net -p {{listen}}:{{listen}} lockhost-runtime {{listen}} {{target}} {{port}}


##########
## Prod ##
##########

run-host:
    just make-test-net
    sudo docker run --rm -it --platform="linux/amd64" --privileged --name lockhost-host -v /dev/vsock:/dev/vsock --network lockhost-net -p 2222:2222 --env-file .env -e PROD=true lockhost-host 2222

run-app:
    sudo nitro-cli run-enclave --cpu-count 2 --memory 4096 --enclave-cid 16 --eif-path dist/app.eif

run-app-debug:
    sudo nitro-cli run-enclave --cpu-count 2 --memory 4096 --enclave-cid 16 --eif-path dist/app.eif --debug-mode

nitro-logs enclave-id:
    sudo nitro-cli console --enclave-id {{enclave-id}}

nitro-rm enclave-id:
    sudo nitro-cli terminate-enclave --enclave-id {{enclave-id}}
