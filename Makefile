DIR ?= IP/STD_cell

# =============================================================================
# Compress blocks
# =============================================================================
# Generate zip
COMP_DIR        := $(shell find $(DIR) -type d -name liberty)
COMP_DIR_PARENT := $(patsubst %/liberty, %, $(COMP_DIR))
COMP_BZ2_PATH   := $(addsuffix _liberty.tar.bz2, $(COMP_DIR_PARENT))

.PHONY: zip clean-bz2

$(COMP_BZ2_PATH): %_liberty.tar.bz2: %/liberty
	@echo "\nCompressing: $< -> $@"
	@tar -cjvf $@ -C $(dir $<) $(notdir $<)

zip: clean-bz2 $(COMP_BZ2_PATH)
	@echo "\nAll liberty directories have been compressed!"

clean-bz2:
	@echo "Cleaning up all old bz2 files..."
	@find ./ -name "*.tar.bz2" -exec rm -fv {} \; || true

# Upload zip
RELEASE_VERSION ?=
RELEASE_TITLE   ?= $(RELEASE_VERSION)
RELEASE_NOTES   ?= "ICsprout55 Open Source PDK Large Files"

.PHONY: upload check-auth

check-auth:
	@if ! gh auth status >/dev/null 2>&1; then \
		echo "Error: GitHub release status check failed. Are you in a repo with releases?"; \
		exit 1; \
	fi

upload: zip check-auth
	@echo "\nCreating GitHub release $(RELEASE_VERSION)..."
	gh release create $(RELEASE_VERSION) $(COMP_BZ2_PATH) --title $(RELEASE_TITLE) --notes $(RELEASE_NOTES)
	@echo "Release $(RELEASE_VERSION) uploaded successfully!"

# =============================================================================
# Extract blocks
# =============================================================================
REPO_OWNER := myyerrol
REPO_NAME  := pdk

RELEASE_FILES := ics55_LLSC_H7CH_liberty.tar.bz2 \
                 ics55_LLSC_H7CL_liberty.tar.bz2 \
                 ics55_LLSC_H7CR_liberty.tar.bz2

EXTR_DIR_PARENT := $(DIR)/ics55_LLSC_H7C_V1p10C100
EXTR_DIR        := $(patsubst %_liberty.tar.bz2, $(EXTR_DIR_PARENT)/%/liberty, $(RELEASE_FILES))

.PHONY: download unzip clean-dir

$(RELEASE_FILES):
	@echo "\nGetting the latest release information..."
	@RELEASE_URL=$$(curl -s "https://api.github.com/repos/$(REPO_OWNER)/$(REPO_NAME)/releases/latest" | \
		grep -E "browser_download_url.*$(@)" | \
		cut -d '"' -f 4); \
	if [ -z "$$RELEASE_URL" ]; then \
		echo "Error: File not found $(@)"; \
		echo "Please check whether the Release contains the following files: "; \
		echo "$(RELEASE_FILES)"; \
		exit 1; \
	fi; \
	echo "Downloading $(@)"; \
	if [ "$(TOOL)" = "wget" ]; then \
		wget -O $(@) "$$RELEASE_URL" && echo "Download completed: $(@)"; \
	else \
		curl -L -o $(@) "$$RELEASE_URL" && echo "Download completed: $(@)"; \
	fi

$(EXTR_DIR_PARENT)/%/liberty: %_liberty.tar.bz2
	@echo "\nExtracting: $< -> $(EXTR_DIR_PARENT)/$*/"
	@mkdir -p $@
	@tar -xjvf $< -C $(EXTR_DIR_PARENT)/$*/
	@touch $@

download: $(RELEASE_FILES)

unzip: clean-bz2 clean-dir download $(EXTR_DIR)
	@echo "\nAll liberty bz2 files have been extracted!"

clean-dir:
	@echo "Cleaning up all old directories..."
	@find $(DIR) -depth -type d -name "liberty" -exec rm -rfv {} \; || true
