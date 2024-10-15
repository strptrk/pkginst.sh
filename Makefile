DOCKER_IMAGES  := archlinux ubuntu fedora gentoo
DOCKER_USER    := user
DOCKER_DIR     := docker
DOCKER_IMGNAME := pkginst-test

TEST_PKGS := 'nvim:neovim' \
			 'rg:ripgrep' \
			 '{fd,fdfind}:{fd,fd-find}' \
			 'clangd:{clangd,clang,llvm}' \
			 'tree-sitter:{tree-sitter,tree-sitter-cli}' \
			 'cmake'

TEST_VERBOSITY ?= -v

test-%:
	@echo ">>> RUNNING $*"
	@docker run -it -v $${PWD}:$${PWD} --workdir $${PWD} ${DOCKER_IMGNAME}-$* \
		sh -c "./pkginst.sh ${TEST_VERBOSITY} ${TEST_PKGS}"


.PHONY: test
test: check-docker
	@$(MAKE) $(patsubst %, test-%, ${DOCKER_IMAGES}) | tee test.log
	@if grep "None of" test.log >/dev/null 2>&1; then \
		echo "Test FAILED: see test/test.log for details"; \
		exit 1; \
	else \
		echo "Test SUCCESSFUL"; \
		rm -f test.log; \
	fi

check-docker-%:
	@if ! docker images | grep ${DOCKER_IMGNAME}-$* >/dev/null 2>&1; then \
		echo "Docker image ${DOCKER_IMGNAME}-$* cannot be found, building it."; \
		$(MAKE) build-docker-$*; \
	fi

.PHONY: build-docker
check-docker: $(patsubst %, check-docker-%, ${DOCKER_IMAGES})

build-docker-%:
	@docker build ${DOCKER_DIR} --build-arg _USER=${DOCKER_USER} -f ${DOCKER_DIR}/Dockerfile-$* -t ${DOCKER_IMGNAME}-$*

.PHONY: build-docker
build-docker: $(patsubst %, build-docker-%, ${DOCKER_IMAGES})

clean-docker-%:
	@docker image rm -f ${DOCKER_IMGNAME}-$*
	@docker image rm -f koalaman/shellcheck

.PHONY: clean-docker
clean-docker: $(patsubst %, clean-docker-%, ${DOCKER_IMAGES})

.PHONY: verify
verify:
	@docker run --rm -v "$${PWD}:/mnt" koalaman/shellcheck:stable -f gcc pkginst.sh
