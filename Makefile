HOST ?= pcp.local
.DEFAULT_GOAL := help

.PHONY: help install install-and-keep-downloads ssh install-ssh-key remove-ssh-fingerprint

help: ## Show this help message
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-25s\033[0m %s\n", $$1, $$2}'
	@echo "You can append HOST=xxx to any command to override pcp.local"

install: ## Copy and run the installation script on the piCorePlayer
	scp install_cdsp.sh tc@$(HOST):~
	ssh tc@$(HOST) "./install_cdsp.sh"

install-and-keep-downloads: ## Copy and run the installation script on the piCorePlayer and keep downloads to in speed up repeated installs
	scp install_cdsp.sh tc@$(HOST):~
	ssh tc@$(HOST) "./install_cdsp.sh --keep-downloads"

ssh: ## Open an SSH session to the piCorePlayer
	ssh tc@$(HOST)

install-ssh-key: ## Copy your local SSH public key to the piCorePlayer
	ssh-copy-id tc@$(HOST)

remove-ssh-fingerprint: ## Remove the SSH fingerprint from known_hosts
	ssh-keygen -f "$(HOME)/.ssh/known_hosts" -R '$(HOST)'
