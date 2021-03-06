######################################################################
# This file was autogenerated by 'configure'. Do not edit it directly!
# Invocation was: ./configure 
######################################################################
WITH_LOCK=yes
WITH_DEFER=yes
WITH_CACHE=yes
WITH_DEBUG=yes
WITH_PARALLEL=yes
WITH_EXTENSIONS=yes
WITH_COMPLETION=yes
######################################################################
SHELL     ?= sh
PREFIX    ?= /usr/local

CRAM_OPTS ?= -v

PROJECT   ?= $(CURDIR)
BIN       ?= ${PROJECT}/bin
SRC       ?= ${PROJECT}/src
TESTS     ?= ${PROJECT}/tests
TOOLS     ?= ${PROJECT}/tools
TEST      ?= ${PROJECT}/tests

ZSH_VERSION     ?= zsh-5.3
CONTAINER_ROOT  ?= /antigen
USE_CONTAINER   ?= docker
CONTAINER_IMAGE ?= desyncr/zsh-docker-

TARGET     ?= ${BIN}/antigen.zsh
SRC        ?= ${SRC}
EXTENSIONS ?= 
GLOB       ?= 

WITH_DEBUG      ?= yes
WITH_EXTENSIONS ?= yes
WITH_DEFER      ?= yes
WITH_LOCK       ?= yes
WITH_PARALLEL   ?= yes
WITH_CACHE      ?= yes
WITH_COMPLETION ?= yes

ifeq (${WITH_EXTENSIONS}, yes)
EXTENSIONS += ${SRC}/ext/ext.zsh
endif
ifeq (${WITH_DEFER}, yes)
EXTENSIONS += ${SRC}/ext/defer.zsh
endif
ifeq (${WITH_LOCK}, yes)
EXTENSIONS += ${SRC}/ext/lock.zsh
endif
ifeq (${WITH_PARALLEL}, yes)
EXTENSIONS += ${SRC}/ext/parallel.zsh
endif
ifeq (${WITH_CACHE}, yes)
GLOB       += ${SRC}/boot.zsh
EXTENSIONS += ${SRC}/ext/cache.zsh
endif

LIB     = $(filter-out ${SRC}/lib/log.zsh,$(sort $(wildcard ${PWD}/src/lib/*.zsh)))
HELPERS = $(sort $(wildcard ${PWD}/src/helpers/*.zsh)) 
COMMANDS= $(sort $(wildcard ${PWD}/src/commands/*.zsh))
GLOB   += ${SRC}/antigen.zsh ${HELPERS} ${LIB} ${COMMANDS} ${EXTENSIONS}

ifeq (${WITH_COMPLETION}, yes)
GLOB  += ${SRC}/_antigen
endif
# If debug is enabled then load debug functions
ifeq (${WITH_DEBUG}, yes)
GLOB  += ${SRC}/lib/log.zsh
endif

VERSION      ?= develop
VERSION_FILE  = ${PROJECT}/VERSION

BANNER_SEP    =$(shell printf '%*s' 70 | tr ' ' '\#')
BANNER_TEXT   =This file was autogenerated by \`make\`. Do not edit it directly!
BANNER        =${BANNER_SEP}\n\# ${BANNER_TEXT}\n${BANNER_SEP}\n

HEADER_TEXT   =\# Antigen: A simple plugin manager for zsh\n\
\# Authors: Shrikant Sharat Kandula\n\
\#          and Contributors <https://github.com/zsh-users/antigen/contributors>\n\
\# Homepage: http://antigen.sharats.me\n\
\# License: MIT License <mitl.sharats.me>\n

define ised
	sed $(1) $(2) > "$(2).1"
	mv "$(2).1" "$(2)"
endef

define isede
	sed -E $(1) $(2) > "$(2).1"
	mv "$(2).1" "$(2)"
endef

.PHONY: itests tests install all

build:
	@echo Building Antigen...
	@printf "${BANNER}" > ${BIN}/antigen.zsh
	@printf "${HEADER_TEXT}" >> ${BIN}/antigen.zsh
	@for src in ${GLOB}; do echo "----> $$src"; cat "$$src" >> ${TARGET}; done
	@echo "-antigen-env-setup" >> ${TARGET}
	@echo "${VERSION}" > ${VERSION_FILE}
	@$(call ised,"s/{{ANTIGEN_VERSION}}/$$(cat ${VERSION_FILE})/",${TARGET})
	@$(call ised,"s/{{ANTIGEN_REVISION}}/$$(git log -n1 --format=%h -- . ':(exclude)bin')/",${TARGET})
	@$(call ised,"s/{{ANTIGEN_REVISION_DATE}}/$$(TZ=UTC date -d @$$(git log -n1 --format='%at' -- . ':(exclude)bin') '+%F %T %z')/",${TARGET})
ifeq (${WITH_DEBUG}, no)
	@$(call isede,"s/ (WARN|LOG|ERR|TRACE) .*&//",${TARGET})
	@$(call isede,"/ (WARN|LOG|ERR|TRACE) .*/d",${TARGET})
endif
	@echo Done.
	@ls -sh ${TARGET}

release:
	git checkout develop
	${MAKE} build tests
	git checkout -b release/${VERSION}
	# Update changelog
	${EDITOR} CHANGELOG.md
	# Build release commit
	git add CHANGELOG.md ${VERSION_FILE} README.mkd ${TARGET}
	git commit -S -m "Build release ${VERSION}"

publish:
	git push origin release/${VERSION}
	# Merge release branch into develop before deploying

deploy:
	git checkout develop
	git tag -m "Build release ${VERSION}" -s ${VERSION}
	git archive --output=${VERSION}.tar.gz --prefix=antigen-$$(echo ${VERSION}|sed s/v//)/ ${VERSION}
	zcat ${VERSION}.tar.gz | gpg --armor --detach-sign >${VERSION}.tar.gz.sign
	# Verify signature
	zcat ${VERSION}.tar.gz | gpg --verify ${VERSION}.tar.gz.sign -
	# Push upstream
	git push upstream ${VERSION}

.container:
ifeq (${USE_CONTAINER}, docker)
	@docker run --rm --privileged=true -it -v ${PROJECT}:/antigen ${CONTAINER_IMAGE}${ZSH_VERSION} $(shell echo "${COMMAND}" | sed "s|${PROJECT}|${CONTAINER_ROOT}|g")
else ifeq (${USE_CONTAINER}, no)
	${COMMAND}
endif

info:
	@${MAKE} .container COMMAND="sh -c 'cat ${PROJECT}/VERSION; zsh --version; git --version; env'"

itests:
	@${MAKE} tests CRAM_OPTS=-i

tests:
	@${MAKE} .container COMMAND="sh -c 'ZDOTDIR=${TESTS} ANTIGEN=${PROJECT} cram ${CRAM_OPTS} --shell=zsh ${TEST}'"

stats:
	@${MAKE} .container COMMAND="${TOOLS}/stats --zsh zsh --antigen ${PROJECT}"

install:
	mkdir -p ${PREFIX}/share && cp ${TARGET} ${PREFIX}/share/antigen.zsh

clean:
	rm -f ${PREFIX}/share/antigen.zsh

install-deps:
	sudo pip install cram=='0.6.*'

all: clean build install
