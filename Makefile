include .env

.DEFAULT_GOAL := all
.PHONY: .docker .sysbox .git .vim .patch-0.59.0 arca-gaia arca-atlas all boostrap inject\:% new\:v1\:% new\:v1-atlas\:% monitor\:% enter\:% stop\:% remove\:% docker\:tag\:% docker\:push\:% push clean
.ONESHELL:
.SUFFIXES:

.install-%:
	command -v $* >/dev/null 2>&1 || sudo bash .install/$*.sh

.start-%:
	STATUS=$$(systemctl show $* --property ActiveState --value)
	echo $?
	if [ $$STATUS != "active" ]; then \
		sudo systemctl enable --now $* && sudo systemctl start $*; \
	fi

.docker: .install-docker .start-docker

.sysbox: .docker .install-sysbox .start-sysbox .start-sysbox-fs .start-sysbox-mgr .start-sysbox-mgr 

.git:
	command -v git >/dev/null 2>&1 || sudo apt update -y && sudo apt install git

.vim:
	command -v vim >/dev/null 2>&1 || sudo apt update -y && sudo apt install vim

install: .git .vim .docker .sysbox

source/openhands-%:
	rm -rf source/openhands-$*
	git clone https://github.com/All-Hands-AI/OpenHands.git source/openhands-$*
	cd source/openhands-$*
	git switch -c $*

.patch-0.59.0:
	cd source/openhands-0.59.0
	sed -i "s/host.docker.internal/0.0.0.0/g" "./containers/app/Dockerfile"
	sed -i "s/OPENHANDS_USER_ID openhands/OPENHANDS_USER_ID arca/g" "./containers/app/Dockerfile"
	sed -i "s/\/bin\/bash openhands/\/bin\/bash arca/g" "./containers/app/Dockerfile"
	sed -i "s/usermod -aG openhands openhands/usermod -aG arca arca/g" "./containers/app/Dockerfile"
	sed -i "s/usermod -aG sudo openhands/usermod -aG sudo arca/g" "./containers/app/Dockerfile"
	sed -i "s/chown -R openhands:openhands/chown -R arca:arca/g" "./containers/app/Dockerfile"
	sed -i "s/USER openhands/USER arca/g" "./containers/app/Dockerfile"
	sed -i "s/--chown=openhands:openhands/--chown=arca:arca/g" "./containers/app/Dockerfile"
	sed -i "s/-group openhands -exec chgrp openhands/-group arca -exec chgrp arca/g" "./containers/app/Dockerfile"
	sed -i "s/, 'security_risk'//g" "./openhands/agenthub/codeact_agent/tools/bash.py"
	sed -i "s/, 'security_risk'//g" "./openhands/agenthub/codeact_agent/tools/browser.py"
	sed -i "s/, 'security_risk'//g" "./openhands/agenthub/codeact_agent/tools/ipython.py"
	sed -i "s/, 'security_risk'//g" "./openhands/agenthub/codeact_agent/tools/llm_based_edit.py"
	sed -i "s/, 'security_risk'//g" "./openhands/agenthub/codeact_agent/tools/str_replace_editor.py"

.app-%:
	docker image rm "arca-app:$*" || true
	cd ./source/openhands-$*
	docker build -f "./containers/app/Dockerfile" \
		-t "arca-app:$*" . ${DOCKER_BUILD_OPTS} \
		&& (cd ../.. && touch .app-$*)

.arca-%:
	docker image rm "arca:${ARCA_RELEASE}-$*" || true
	docker build --build-arg OPENHANDS_RELEASE="${OPENHANDS_RELEASE}" --build-arg ARCA_TYPE="$*" -f Containerfile \
		-t "arca:${ARCA_RELEASE}-$*" . ${DOCKER_BUILD_OPTS} \
		&& touch .arca-$*

arca-core: .sysbox .git source/openhands-${OPENHANDS_RELEASE} .patch-${OPENHANDS_RELEASE} .app-${OPENHANDS_RELEASE}

arca-gaia: arca-core .arca-gaia

arca-atlas: arca-core .arca-atlas

all: arca-gaia arca-atlas

.openhands/secrets.json:
	cp --force .openhands/secrets.json.template .openhands/secrets.json
	vim .openhands/secrets.json

.openhands/settings.json:
	cp -f .openhands/settings.json.template .openhands/settings.json
	vim .openhands/settings.json

bootstrap: .vim .openhands/secrets.json .openhands/settings.json

inject\:%: .docker
	cat <<EOF | docker exec -i $* /bin/bash -c "cat > /.openhands/settings.json"
	$$(cat .openhands/settings.json)
	EOF
	cat <<EOF | docker exec -i $* /bin/bash -c "cat > /.openhands/secrets.json"
	$$(cat .openhands/secrets.json)
	EOF

new\:gaia\:%: .sysbox bootstrap
	docker run -d --runtime=sysbox-runc -p 8443:8443 --name $* --hostname $* "localhost/arca:v1-gaia"
	sleep 5
	make inject:$*

new\:atlas\:%: bootstrap
	docker run -d --runtime=sysbox-runc -p 8443:8443 --name $* --hostname $* "localhost/arca:v1-atlas"
	sleep 5
	make inject:$*

monitor\:%: .docker
	WHICH=$$(echo $* | cut -d ':' -f 1)
	WHAT=$$(echo $* | cut -d ':' -f 2)
	docker exec -it "$${WHICH}" /bin/bash -c "journalctl -f -u $$WHAT.service"

enter\:%: .docker
	docker exec -it $* /bin/bash

stop\:%: .docker
	docker container stop $*

remove\:%: .docker
	docker container rm $*

docker\:tag\:%: .docker
	docker tag localhost/arca:v1-$* omnedock/arca:v1-$*

local\:tag\:%: .docker
	docker tag omnedock/arca:v1-$* localhost/arca:v1-$*

docker\:push\:%: .docker
	docker push omnedock/arca:v1-$*

docker\:pull\:%: .docker
	docker pull omnedock/arca:v1-$*

push\:%: .docker
	make docker:tag:$*
	make docker:push:$*

push: .docker
	make push:gaia
	make push:atlas

pull\:%: .docker
	make docker:pull:$*
	make local:tag:$*

pull: .docker
	make pull:gaia
	make pull:atlas

clean:
	rm -rf .installed source/* .app* .arca* || true
	docker system prune --force

