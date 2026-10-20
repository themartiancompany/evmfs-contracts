# SPDX-License-Identifier: AGPL-3.0

#    -----------------------------------------------------
#    Copyright © 2024, 2025, 2026  Pellegrino Prevete
#
#    All rights reserved
#    -----------------------------------------------------
#
#    This program is free software: you can redistribute
#    it and/or modify it under the terms of the
#    GNU Affero General Public License as published by
#    the Free Software Foundation, either version 3 of
#    the License, or (at your option) any later version.
#
#    This program is distributed in the hope that it
#    will be useful, but WITHOUT ANY WARRANTY;
#    without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
#    See the GNU Affero General Public License for
#    more details.
#
#    You should have received a copy of the
#    GNU Affero General Public License
#    along with this program.
#    If not, see <https://www.gnu.org/licenses/>.

_NPM ?= false
SHELL=bash
PREFIX ?= /usr/local
_PROJECT=evmfs
_PROJECT_NPM=$(_PROJECT)-contracts
_NAMESPACE=themartiancompany
SOLIDITY_COMPILER_BACKEND ?= solc
DOC_DIR=$(DESTDIR)$(PREFIX)/share/doc/$(_PROJECT)
USR_DIR=$(DESTDIR)$(PREFIX)
BIN_DIR=$(DESTDIR)$(PREFIX)/bin
LIB_DIR=$(DESTDIR)$(PREFIX)/lib/$(_PROJECT)
NODE_DIR=$(DESTDIR)$(PREFIX)/lib/node_modules/$(_PROJECT_NPM)
BUILD_NPM_DIR=build
BUILD_EVM_MAKE_DIR=evm-make-build
BUILD_CONTRACTS_DIR=contracts-build
BUILD_DIR=build

CONTRACTS_TARGETS_ALL=\
  contracts \
  contracts-npm \
  contracts-deployments-config-npm \
  contracts-deployments-hardhat-npm \
  contracts-deployments-solc-npm \
  contracts-sources-npm

PHONY_TARGETS=\
  check \
  $(CONTRACTS_TARGETS_ALL) \
  npm \
  build-scripts \
  contracts \
  install \
  install-doc \
  install-npm \
  install-scripts \
  shellcheck \
  uninstall

_INSTALL_FILE=\
  install \
    -vDm644
_INSTALL_EXE=\
  install \
    -vDm755
_INSTALL_DIR=\
  install \
    -vdm755
_MAKE_LINK=\
  ln \
    -sv
_MAKE_EXE=\
  chmod \
    755

DOC_FILES=\
  $(wildcard \
      *.rst) \
  $(wildcard \
      *.md)

NPM_FILES=\
  "README.md" \
  "COPYING" \
  "AUTHORS.rst" \
  "dist" \
  "data-get" \
  "eslint.config.mjs" \
  "fs-worker.webpack.config.cjs" \
  "package.json" \
  "webpack.config.cjs"

CONTRACTS=\
  "UserRepository" \
  "UserRepositoryPublishers" \
  "PackagePublishers"

all: contracts contracts-npm npm

check: eslint

eslint:

	npm \
	  install \
	  --save-dev; \
	npx \
	  eslint \
	    "."

contracts:

	evm-make \
	  -v \
	  -f \
	    "y" \
	  -C \
	    "$${PWD}" \
	  -p \
	    "./" \
	  -b \
	    "$(SOLIDITY_COMPILER_BACKEND)" \
	  -w \
	    "$(BUILD_EVM_MAKE_DIR)" || \
	true

contracts-sources-npm:

	evm-make \
	  -v \
	  -f \
	    "y" \
	  -C \
	    "$${PWD}" \
	  -p \
	    "./" \
	  -b \
	    "$(SOLIDITY_COMPILER_BACKEND)" \
	  -w \
	    "$(BUILD_EVM_MAKE_DIR)" \
	  -o \
	    "$(BUILD_CONTRACTS_DIR)" \
	  -l \
	    "n" \
	  install_sources

contracts-deployments-config-npm:

	evm-make \
	  -v \
	  -f \
	    "y" \
	  -C \
	    "$${PWD}" \
	  -p \
	    "./" \
	  -b \
	    "$(SOLIDITY_COMPILER_BACKEND)" \
	  -w \
	    "$(BUILD_EVM_MAKE_DIR)" \
	  -o \
	    "$(BUILD_CONTRACTS_DIR)" \
	  -l \
	    "n" \
	  install_deployments_config

contracts-deployments-solc-npm:

	evm-make \
	  -v \
	  -f \
	    "y" \
	  -C \
	    "$${PWD}" \
	  -p \
	    "./" \
	  -b \
	    "solc" \
	  -w \
	    "$(BUILD_EVM_MAKE_DIR)" \
	  -o \
	    "$(BUILD_CONTRACTS_DIR)" \
	  -l \
	    "n" \
	  install_deployments

contracts-deployments-hardhat-npm:

	evm-make \
	  -v \
	  -f \
	    "y" \
	  -C \
	    "$${PWD}" \
	  -p \
	    "./" \
	  -b \
	    "hardhat" \
	  -w \
	    "$(BUILD_EVM_MAKE_DIR)" \
	  -o \
	    "$(BUILD_CONTRACTS_DIR)" \
	  -l \
	    "n" \
	  install_deployments

contracts-npm:

	make \
	  contracts-deployments-solc-npm
	make \
	  contracts-deployments-hardhat-npm
	make \
	  contracts-deployments-config-npm
	make \
	  contracts-sources-npm

npm:

	SOLIDITY_COMPILER_BACKEND="hardhat" \
	make \
	  contracts || \
	true
	SOLIDITY_COMPILER_BACKEND="solc" \
	make \
	  contracts
	make \
	  contracts-npm
	mkdir \
	  -p \
	  "build"; \
	cp \
	  -r \
	  "contracts-build/"* \
	  "build"
	cp \
	  -r \
	  "Makefile" \
	  $(NPM_FILES) \
	  "build"; \
	cd \
	  "build"; \
	_version="$$( \
	  npm \
	    view \
	      "$${PWD}" \
	      "version")"; \
	npm \
	  install; \
	npm \
	  run \
	    "build"; \
	npm \
	  pack; \
	mv \
	  "$(_PROJECT_NPM)-$${_version}.tgz" \
	  ".."

install: install-scripts install-doc install-examples

install-scripts:

	if [[ "$(_NPM)" == "false" ]]; then \
	  $(_INSTALL_DIR) \
	    "$(LIB_DIR)/nodejs"; \
	  for _file \
	    in $$( \
	         cat \
	           "$${PWD}/package.json" | \
	             jq \
	               --raw-output \
	               '.files[]'); do \
            cp \
	      -r \
	      "build/$${_file}" \
	      "$(DESTDIR)$(PREFIX)/lib/$(_PROJECT_NPM)/nodejs" || \
	    true; \
          done; \
	  for _program in \
	    $(_PROGRAMS); do \
	    if [[ ! -s "$(BIN_DIR)/$${_program}" && \
	          ! -e "$(BIN_DIR)/$${_program}" ]]; then \
	      $(_MAKE_LINK) \
	        "$(PREFIX)/lib/$(_PROJECT_NPM)/nodejs/$${_program}" \
	        "$(BIN_DIR)/$${_program}"; \
	    fi; \
	  done; \
	  rm \
	    "$(LIB_DIR)/node_modules" || \
	    true; \
	  if [[ ! -s "$(LIB_DIR)/node_modules" ]]; then \
	    $(_MAKE_LINK) \
	      "$(PREFIX)/lib/node_modules" \
	      "$(DESTDIR)$(PREFIX)/lib/$(_PROJECT_NPM)/nodejs/node_modules"; \
	  fi; \
	  rm \
	    -rf \
	    "$(DESTDIR)$(PREFIX)/lib/node_modules/$(_PROJECT_NPM)"; \
	  if [[ ! -s "$(DESTDIR)$(PREFIX)/lib/node_modules/$(_PROJECT_NPM)" ]]; then \
	    $(_MAKE_LINK) \
	      "$(PREFIX)/lib/$(_PROJECT_NPM)/nodejs" \
	      "$(DESTDIR)$(PREFIX)/lib/node_modules/$(_PROJECT_NPM)"; \
	  fi; \
	  if [[ ! -s "$(DESTDIR)$(PREFIX)/lib/$(_PROJECT)/contracts" ]]; then \
	    $(_MAKE_LINK) \
	      "$(PREFIX)/lib/$(_PROJECT_NPM)/nodejs/contracts" \
	      "$(DESTDIR)$(PREFIX)/lib/$(_PROJECT)/contracts" || \
	      true; \
	  fi; \
	  if [[ ! -s "$(DESTDIR)$(PREFIX)/lib/$(_PROJECT)/deployments" ]]; then \
	    $(_MAKE_LINK) \
	      "$(PREFIX)/lib/$(_PROJECT_NPM)/nodejs/deployments" \
	      "$(DESTDIR)$(PREFIX)/lib/$(_PROJECT)/deployments" || \
	      true; \
	  fi; \
	elif [[ "$(_NPM)" == "true" ]]; then \
	  make \
	    install-npm; \
	  $(_MAKE_LINK) \
	    "$(PREFIX)/lib/node_modules/$(_PROJECT_NPM)" \
	    "$(LIB_DIR)/nodejs" || \
	  true; \
	fi;

install-contracts-sources:

	evm-make \
	  -v \
	  -f \
	    "y" \
	  -C \
	    "$${PWD}" \
	  -b \
	    "$(SOLIDITY_COMPILER_BACKEND)" \
	  -w \
	    "$(BUILD_DIR)" \
	  -o \
	    "$(LIB_DIR)" \
	  -l \
	    "n" \
	  install_sources

install-contracts-deployments-config:

	evm-make \
	  -v \
	  -f \
	    "y" \
	  -C \
	    "$${PWD}" \
	  -b \
	    "$(SOLIDITY_COMPILER_BACKEND)" \
	  -w \
	    "$(BUILD_DIR)" \
	  -o \
	    "$(LIB_DIR)" \
	  -l \
	    "n" \
	  install_deployments_config

install-contracts-deployments-solc:

	evm-make \
	  -v \
	  -f \
	    "y" \
	  -C \
	    "$${PWD}" \
	  -b \
	    "solc" \
	  -w \
	    "$(BUILD_DIR)" \
	  -o \
	    "$(LIB_DIR)" \
	  -l \
	    "n" \
	  install_deployments

install-contracts-deployments-hardhat:

	evm-make \
	  -v \
	  -f \
	    "y" \
	  -C \
	    "$${PWD}" \
	  -b \
	    "hardhat" \
	  -w \
	    "$(BUILD_DIR)" \
	  -o \
	    "$(LIB_DIR)" \
	  -l \
	    "n" \
	  install_deployments

install-npm:

	_npm_opts=( \
	  -g \
	  --prefix \
	    '$(USR_DIR)' \
	); \
	_version="$$( \
	  npm \
	    view \
	      "$${PWD}" \
	      "version")"; \
	npm \
	  install \
	    "$${_npm_opts[@]}" \
	    "$(_PROJECT)-$${_version}.tgz"; \
	$(_INSTALL_DIR) \
	  "$(DESTDIR)$(PREFIX)/lib"; \
	ln \
	  -s \
	  "$(PREFIX)/lib/node_modules/$(_PROJECT_NPM)" \
	  "$(LIB_DIR)" || \
	true

publish-npm:

	cd \
	  "build"; \
	npm \
	  publish \
	  --access \
	    "public"

install-doc:

	$(_INSTALL_FILE) \
	  $(DOC_FILES) \
	  -t \
	  $(DOC_DIR)

uninstall:

	rm \
	  "$(DESTDIR)$(PREFIX)/lib/$(_PROJECT)/contracts" \
	  "$(DESTDIR)$(PREFIX)/lib/$(_PROJECT)/deployments" \
	  "$(DESTDIR)$(PREFIX)/lib/$(_PROJECT_NPM)" \
	  "$(DESTDIR)$(PREFIX)/lib/node_modules/$(_PROJECT_NPM)"


.PHONY: $(PHONY_TARGETS)
